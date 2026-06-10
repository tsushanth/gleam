import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var vm = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: vm.progressFraction)
                .progressViewStyle(.linear)
                .tint(Color.accent)
                .padding(.horizontal)
                .padding(.top, 12)
                .animation(.easeInOut(duration: 0.3), value: vm.progressFraction)
                .accessibilityLabel("Onboarding progress: \(Int(vm.progressFraction * 100))%")

            Group {
                switch vm.currentStep {
                case .welcome:
                    WelcomeView(vm: vm)
                case .segmentation:
                    SegmentationView(vm: vm)
                case .aiSetup:
                    AIRoutineSetupView(vm: vm)
                case .roomSelection:
                    RoomSelectionView(vm: vm)
                case .firstAha:
                    FirstAhaView(vm: vm)
                case .paywall:
                    PaywallView(isOnboarding: true)
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))
            .animation(.easeInOut(duration: 0.3), value: vm.currentStep)
        }
        .onAppear {
            FirebaseAnalyticsService.shared.log(.onboardingStarted)
        }
    }
}
