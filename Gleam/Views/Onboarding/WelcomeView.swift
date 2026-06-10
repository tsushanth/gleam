import SwiftUI

struct WelcomeView: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var gleamOffset: CGFloat = 40
    @State private var gleamOpacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.gleamGreen.opacity(0.15))
                        .frame(width: 140, height: 140)
                    Circle()
                        .fill(Color.gleamGreen.opacity(0.25))
                        .frame(width: 100, height: 100)
                    Image(systemName: "sparkles")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.gleamGreen)
                }
                .offset(y: gleamOffset)
                .opacity(gleamOpacity)

                VStack(spacing: 12) {
                    Text("Gleam")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.gleamGreen)

                    Text("Zero guilt.\nAlways just clean enough.")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .offset(y: gleamOffset)
                .opacity(gleamOpacity)

                VStack(spacing: 8) {
                    featurePill(icon: "gauge.medium", text: "Smart dirtiness tracking")
                    featurePill(icon: "brain.head.profile", text: "AI-generated cleaning routines")
                    featurePill(icon: "person.2", text: "Household sharing & leaderboards")
                }
                .offset(y: gleamOffset)
                .opacity(gleamOpacity)
            }

            Spacer()

            Button {
                HapticService.shared.trigger(.medium)
                vm.advance()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .accessibilityLabel("Get Started")
            .accessibilityHint("Begin setting up your cleaning routine")
        }
        .onAppear {
            guard !UIAccessibility.isReduceMotionEnabled else {
                gleamOffset = 0
                gleamOpacity = 1
                return
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                gleamOffset = 0
                gleamOpacity = 1
            }
            FirebaseAnalyticsService.shared.log(.onboardingStepViewed(step: "welcome"))
        }
    }

    private func featurePill(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accent)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }
}
