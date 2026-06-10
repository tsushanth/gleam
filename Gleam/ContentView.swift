import SwiftUI

struct ContentView: View {
    @AppStorage(UserDefaultsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingContainerView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
    }
}
