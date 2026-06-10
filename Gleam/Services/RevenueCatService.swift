import Foundation
import RevenueCat

extension Notification.Name {
    static let revenueCatCustomerInfoUpdated = Notification.Name("revenueCatCustomerInfoUpdated")
}

final class RevenueCatService: NSObject {
    static let shared = RevenueCatService()

    private let entitlementID = "premium"
    private let lifetimeEntitlementID = "lifetime"

    func configure() {
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: "REVENUECAT_PUBLIC_SDK_KEY")
        Purchases.shared.delegate = self
    }

    func tier(from info: CustomerInfo) -> SubscriptionTier {
        if info.entitlements[lifetimeEntitlementID]?.isActive == true { return .lifetime }
        if info.entitlements[entitlementID]?.isActive == true { return .premium }
        return .free
    }

    func fetchPackages() async throws -> [Package] {
        let offerings = try await Purchases.shared.offerings()
        return offerings.current?.availablePackages ?? []
    }
}

extension RevenueCatService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        NotificationCenter.default.post(name: .revenueCatCustomerInfoUpdated, object: customerInfo)
    }
}
