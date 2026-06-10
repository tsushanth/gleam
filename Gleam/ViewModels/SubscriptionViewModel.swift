import Foundation
import RevenueCat

enum SubscriptionProduct: String, CaseIterable, Identifiable {
    case yearly   = "com.com.appfactory.gleam.subscription.yearly"
    case monthly  = "com.com.appfactory.gleam.subscription.monthly"
    case weekly   = "com.com.appfactory.gleam.subscription.weekly"
    case lifetime = "com.com.appfactory.gleam.subscription.lifetime"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .yearly:   return "Yearly"
        case .monthly:  return "Monthly"
        case .weekly:   return "Weekly"
        case .lifetime: return "Lifetime"
        }
    }

    var price: String {
        switch self {
        case .yearly:   return "$63.99/year"
        case .monthly:  return "$7.99/month"
        case .weekly:   return "$3.19/week"
        case .lifetime: return "$127.98 once"
        }
    }

    var badge: String? {
        switch self {
        case .yearly: return "Best Value"
        default:      return nil
        }
    }

    var perMonthPrice: String? {
        switch self {
        case .yearly: return "$5.33/mo"
        default:      return nil
        }
    }
}

@MainActor
final class SubscriptionViewModel: ObservableObject {
    @Published var tier: SubscriptionTier = .free
    @Published var selectedProduct: SubscriptionProduct = .yearly
    @Published var isPurchasing = false
    @Published var error: String?

    var isPremium: Bool { tier.isPremium }

    var ctaTitle: String {
        selectedProduct == .lifetime ? "Buy Lifetime Access" : "Start Free Trial"
    }

    init() {
        Task { await refresh() }
        NotificationCenter.default.addObserver(
            forName: .revenueCatCustomerInfoUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let info = notification.object as? CustomerInfo else { return }
            Task { @MainActor in
                self?.tier = RevenueCatService.shared.tier(from: info)
            }
        }
    }

    func refresh() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            tier = RevenueCatService.shared.tier(from: info)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let packages = try await RevenueCatService.shared.fetchPackages()
            guard let package = packages.first(where: {
                $0.storeProduct.productIdentifier == selectedProduct.rawValue
            }) else { return }
            let result = try await Purchases.shared.purchase(package: package)
            tier = RevenueCatService.shared.tier(from: result.customerInfo)
            FirebaseAnalyticsService.shared.log(.subscriptionStarted(productID: selectedProduct.rawValue))
        } catch {
            self.error = error.localizedDescription
        }
    }

    func restorePurchases() async {
        do {
            let info = try await Purchases.shared.restorePurchases()
            tier = RevenueCatService.shared.tier(from: info)
            FirebaseAnalyticsService.shared.log(.subscriptionRestored)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
