import SwiftUI

struct SegmentationView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Tell us about your home")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    Text("We'll personalize your experience")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Who lives with you?")
                        .font(.headline)

                    ForEach(HouseholdType.allCases) { type in
                        selectionRow(
                            title: type.rawValue,
                            icon: iconFor(type),
                            isSelected: vm.householdType == type
                        ) {
                            vm.householdType = type
                            HapticService.shared.trigger(.selection)
                        }
                    }
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text("What's your biggest cleaning challenge?")
                        .font(.headline)

                    ForEach(CleaningChallenge.allCases) { challenge in
                        selectionRow(
                            title: challenge.rawValue,
                            icon: iconFor(challenge),
                            isSelected: vm.cleaningChallenge == challenge
                        ) {
                            vm.cleaningChallenge = challenge
                            HapticService.shared.trigger(.selection)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Button {
                    HapticService.shared.trigger(.medium)
                    vm.advance()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .accessibilityLabel("Continue to next step")
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            FirebaseAnalyticsService.shared.log(.onboardingStepViewed(step: "segmentation"))
        }
    }

    private func selectionRow(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Color.white : Color.accent)
                    .frame(width: 36, height: 36)
                    .background(isSelected ? Color.accent : Color.accent.opacity(0.12))
                    .clipShape(Circle())

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isSelected ? Color(.label) : Color(.label))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.accent.opacity(0.1) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accent : Color.clear, lineWidth: 1.5)
            )
        }
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private func iconFor(_ type: HouseholdType) -> String {
        switch type {
        case .solo:      return "person"
        case .couple:    return "person.2"
        case .family:    return "house"
        case .roommates: return "person.3"
        }
    }

    private func iconFor(_ challenge: CleaningChallenge) -> String {
        switch challenge {
        case .forgetting:   return "bell.slash"
        case .motivation:   return "bolt.slash"
        case .fairDivision: return "scale.3d"
        case .whereToStart: return "questionmark.circle"
        }
    }
}
