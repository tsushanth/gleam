import Foundation
import StoreKit

// MARK: - Product Metadata

/// Static metadata for each purchasable product. Live prices come from StoreKit;
/// these strings serve as fallback when the App Store is unreachable.
enum SubscriptionProduct: String, CaseIterable, Identifiable {
    case weekly    = "com.com.appfactory.gleam.subscription.weekly"
    case monthly   = "com.com.appfactory.gleam.subscription.monthly"
    case yearly    = "com.com.appfactory.gleam.subscription.yearly"
    case lifetime  = "com.com.appfactory.gleam.subscription.lifetime"
    case removeAds = "com.com.appfactory.gleam.remove_ads"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly:    return "Weekly"
        case .monthly:   return "Monthly"
        case .yearly:    return "Yearly"
        case .lifetime:  return "Lifetime"
        case .removeAds: return "Remove Ads"
        }
    }

    var fallbackPrice: String {
        switch self {
        case .weekly:    return "$3.19/week"
        case .monthly:   return "$7.99/month"
        case .yearly:    return "$63.99/year"
        case .lifetime:  return "$127.98"
        case .removeAds: return "$1.99"
        }
    }

    var badge: String? {
        switch self {
        case .yearly: return "Best Value"
        default:      return nil
        }
    }

    var perMonthNote: String? {
        switch self {
        case .yearly: return "$5.33/mo"
        default:      return nil
        }
    }

    var isOneTime: Bool {
        self == .lifetime || self == .removeAds
    }

    /// Subscription products shown in the main paywall tier picker.
    static var subscriptionCases: [SubscriptionProduct] {
        [.weekly, .monthly, .yearly, .lifetime]
    }
}

// MARK: - Purchase State

enum PurchaseState: Equatable {
    case idle
    case purchasing
    case restoring
    case cancelled
    case pending                  // Awaiting parental / Ask-to-Buy approval
    case failed(String)
    case noNetwork

    static func == (lhs: PurchaseState, rhs: PurchaseState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.purchasing, .purchasing),
             (.restoring, .restoring), (.cancelled, .cancelled),
             (.pending, .pending), (.noNetwork, .noNetwork):
            return true
        case (.failed(let a), .failed(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - ViewModel

@MainActor
final class SubscriptionViewModel: ObservableObject {
    // UI state
    @Published var selectedProduct: SubscriptionProduct = .yearly
    @Published var purchaseState: PurchaseState = .idle

    // Cached from PremiumManager — updated via withObservationTracking
    @Published private(set) var tier: SubscriptionTier = .free

    let storeKit = StoreKitManager.shared
    private let premium  = PremiumManager.shared

    // MARK: - Derived

    var isPremium: Bool { tier.isPremium }

    var isPurchasing: Bool { purchaseState == .purchasing }
    var isRestoring:  Bool { purchaseState == .restoring  }

    var errorMessage: String? {
        if case .failed(let msg) = purchaseState { return msg }
        return nil
    }

    var ctaTitle: String {
        selectedProduct.isOneTime
            ? "Buy \(selectedProduct.displayName)"
            : "Start Free Trial"
    }

    // MARK: - Init

    init() {
        tier = premium.tier
        observePremiumManager()
        Task { await premium.sync() }
    }

    // MARK: - Purchase

    func purchase() async {
        purchaseState = .purchasing

        // Ensure products are loaded (may be empty if app launched offline)
        if storeKit.products.isEmpty {
            await storeKit.loadProducts()
        }

        guard let product = storeKit.product(for: selectedProduct.rawValue) else {
            purchaseState = .noNetwork
            return
        }

        let outcome = await storeKit.purchase(product)
        handleOutcome(outcome, productID: selectedProduct.rawValue)
    }

    private func handleOutcome(_ outcome: StoreKitManager.PurchaseOutcome, productID: String) {
        switch outcome {
        case .purchased:
            purchaseState = .idle
            FirebaseAnalyticsService.shared.log(.subscriptionStarted(productID: productID))

        case .cancelled:
            purchaseState = .idle   // User dismissed — not an error

        case .pending:
            purchaseState = .pending

        case .failed(let error):
            // StoreKitError.networkError is not directly accessible outside StoreKit module;
            // detect it by description to surface a friendlier message.
            let msg = error.localizedDescription
            if msg.localizedCaseInsensitiveContains("network") ||
               msg.localizedCaseInsensitiveContains("internet") {
                purchaseState = .noNetwork
            } else {
                purchaseState = .failed(msg)
            }
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        purchaseState = .restoring
        do {
            try await storeKit.restorePurchases()
            purchaseState = .idle
            FirebaseAnalyticsService.shared.log(.subscriptionRestored)
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Error Dismissal

    func dismissError() {
        purchaseState = .idle
    }

    // MARK: - StoreKit Product Lookup

    func storeKitProduct(for product: SubscriptionProduct) -> Product? {
        storeKit.product(for: product.rawValue)
    }

    // MARK: - Observe PremiumManager (@Observable → ObservableObject bridge)

    /// Re-subscribes after every change so the published `tier` stays in sync.
    private func observePremiumManager() {
        withObservationTracking {
            _ = premium.tier
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.tier = self.premium.tier
                self.observePremiumManager()  // re-subscribe for next change
            }
        }
    }
}
