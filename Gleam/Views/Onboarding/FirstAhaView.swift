import SwiftUI
import SwiftData

struct FirstAhaView: View {
    @ObservedObject var vm: OnboardingViewModel
    @Environment(\.modelContext) private var context
    @State private var barRevealProgress: Double = 0
    @State private var showingContinue = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("Here's your home's health")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text("Each room shows how much attention it needs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    ForEach(vm.selectedRoomIcons.sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { icon in
                        roomPreviewRow(icon: icon)
                    }
                }
                .padding(.horizontal, 24)

                if showingContinue {
                    VStack(spacing: 8) {
                        Text("🎉 Your routine is ready!")
                            .font(.headline)
                        Text("Let's see the full picture")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if showingContinue {
                Button {
                    HapticService.shared.trigger(.medium)
                    vm.commitOnboarding(context: context, userID: UUID().uuidString)
                    vm.advance()
                } label: {
                    Text("See My Cleaning Plan")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .accessibilityLabel("See My Cleaning Plan")
            }
        }
        .onAppear {
            FirebaseAnalyticsService.shared.log(.onboardingStepViewed(step: "first_aha"))

            withAnimation(.easeOut(duration: 1.2)) {
                barRevealProgress = 1
            }
            withAnimation(.easeIn(duration: 0.4).delay(1.4)) {
                showingContinue = true
            }

            Task {
                await ATTService.shared.requestPermission()
            }
        }
    }

    private func roomPreviewRow(icon: RoomIcon) -> some View {
        let score = initialDirtinessScore(for: icon) * barRevealProgress

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accent.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon.rawValue)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(icon.displayName)
                    .font(.subheadline.weight(.medium))

                DirtinessMeterView(score: score, showLabel: false)
            }

            Spacer()

            Text(DirtinessCalculator.level(for: score).accessibilityLabel)
                .font(.caption.bold())
                .foregroundStyle(DirtinessCalculator.level(for: score).color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel("\(icon.displayName): \(DirtinessCalculator.level(for: score).accessibilityLabel)")
    }

    private func initialDirtinessScore(for icon: RoomIcon) -> Double {
        switch icon {
        case .kitchen:    return 72
        case .bathroom:   return 85
        case .bedroom:    return 45
        case .livingRoom: return 60
        case .laundry:    return 78
        case .garage:     return 55
        case .office:     return 40
        case .outdoors:   return 65
        case .wholeHouse: return 70
        case .custom:     return 50
        }
    }
}
