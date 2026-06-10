import Foundation
import Observation

/// Single source of truth for the user's premium status.
///
/// - Reads live entitlements from `StoreKitManager.purchasedProductIDs`.
/// - Persists the last-known tier to `UserDefaults` so the app loads correctly offline.
/// - Uses `@Observable` so any SwiftUI view that reads `isPremium` / `tier` automatically
///   re-renders when a subscription is purchased, restored, or expires.
@MainActor
@Observable
final class PremiumManager {
    static let shared = PremiumManager()

    // MARK: - Observed State

    private(set) var tier: SubscriptionTier = .free
    private(set) var hasRemovedAds: Bool = false

    var isPremium: Bool { tier.isPremium }

    // MARK: - Init

    private init() {
        // Restore persisted state immediately — avoids a "free" flash while StoreKit loads.
        let saved = UserDefaults.standard.string(forKey: UserDefaultsKeys.subscriptionTier) ?? ""
        tier = SubscriptionTier(rawValue: saved) ?? .free
        hasRemovedAds = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasRemovedAds)
    }

    // MARK: - Update

    /// Called by `StoreKitManager` after every entitlement refresh.
    func update(from purchasedIDs: Set<String>) {
        let newTier: SubscriptionTier
        if purchasedIDs.contains(StoreKitManager.lifetimeID) {
            newTier = .lifetime
        } else if purchasedIDs.contains(StoreKitManager.yearlyID)
               || purchasedIDs.contains(StoreKitManager.monthlyID)
               || purchasedIDs.contains(StoreKitManager.weeklyID) {
            newTier = .premium
        } else {
            newTier = .free
        }

        let newHasRemovedAds = purchasedIDs.contains(StoreKitManager.removeAdsID)

        tier = newTier
        hasRemovedAds = newHasRemovedAds

        // Persist for offline access
        UserDefaults.standard.set(tier.rawValue, forKey: UserDefaultsKeys.subscriptionTier)
        UserDefaults.standard.set(hasRemovedAds, forKey: UserDefaultsKeys.hasRemovedAds)
    }

    // MARK: - Manual Sync

    /// Forces a full entitlement refresh from the App Store.
    func sync() async {
        await StoreKitManager.shared.refreshPurchasedProducts()
    }
}
