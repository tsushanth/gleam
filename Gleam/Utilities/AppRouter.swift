import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    @Published var showPaywall = false
    @Published var paywallTrigger: String = "settings"
    @Published var selectedTab = 0

    func presentPaywall(trigger: String = "feature_gate") {
        paywallTrigger = trigger
        showPaywall = true
        FirebaseAnalyticsService.shared.log(.paywallViewed(trigger: trigger))
    }
}
