import StoreKit
import Observation

/// StoreKit 2 manager. Source of truth for all App Store transactions.
/// Uses `@Observable` so SwiftUI views re-render whenever `purchasedProductIDs` changes.
@MainActor
@Observable
final class StoreKitManager {
    static let shared = StoreKitManager()

    // MARK: - Product IDs

    static let weeklyID    = "com.com.appfactory.gleam.subscription.weekly"
    static let monthlyID   = "com.com.appfactory.gleam.subscription.monthly"
    static let yearlyID    = "com.com.appfactory.gleam.subscription.yearly"
    static let lifetimeID  = "com.com.appfactory.gleam.subscription.lifetime"
    static let removeAdsID = "com.com.appfactory.gleam.remove_ads"

    static let allProductIDs: Set<String> = [
        weeklyID, monthlyID, yearlyID, lifetimeID, removeAdsID
    ]

    // MARK: - Observed State

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoadingProducts = false

    // MARK: - Init

    private var updateListenerTask: Task<Void, Never>?

    private init() {
        updateListenerTask = startTransactionListener()
        Task {
            await loadProducts()
            await refreshPurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: Self.allProductIDs)
            // Sort: subscriptions by price ascending, then one-time IAPs last
            products = loaded.sorted { lhs, rhs in
                let lhsIsIAP = lhs.type == .nonConsumable
                let rhsIsIAP = rhs.type == .nonConsumable
                if lhsIsIAP != rhsIsIAP { return rhsIsIAP }
                return lhs.price < rhs.price
            }
        } catch {
            // Products unavailable (offline / sandbox not configured). Silently handled —
            // PaywallView shows fallback prices from SubscriptionProduct enum.
        }
    }

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    // MARK: - Purchase

    enum PurchaseOutcome {
        case purchased
        case cancelled
        case pending
        case failed(Error)
    }

    func purchase(_ product: Product) async -> PurchaseOutcome {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    return .failed(StoreKitManagerError.verificationFailed)
                }
                await transaction.finish()
                await refreshPurchasedProducts()
                return .purchased

            case .userCancelled:
                return .cancelled

            case .pending:
                // Family-sharing or Ask-to-Buy awaiting approval
                return .pending

            @unknown default:
                return .cancelled
            }
        } catch {
            return .failed(error)
        }
    }

    // MARK: - Restore Purchases

    /// Syncs the App Store account; `Transaction.currentEntitlements` will then reflect
    /// all active subscriptions and non-consumable IAPs.
    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshPurchasedProducts()
    }

    // MARK: - Entitlement Refresh

    func refreshPurchasedProducts() async {
        var active: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            // Ignore revoked purchases (refunds, billing issues)
            if transaction.revocationDate == nil {
                active.insert(transaction.productID)
            }
        }
        purchasedProductIDs = active
        PremiumManager.shared.update(from: active)
    }

    // MARK: - Transaction Listener

    /// Processes transactions that arrive outside of a direct purchase flow
    /// (e.g. subscription renewals, family-share approvals, subscription restoration).
    private func startTransactionListener() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await refreshPurchasedProducts()
            }
        }
    }
}

// MARK: - Error

enum StoreKitManagerError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        "Purchase verification failed. Contact support if you were charged."
    }
}
