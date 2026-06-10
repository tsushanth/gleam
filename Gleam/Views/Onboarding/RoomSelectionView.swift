import SwiftUI

struct RoomSelectionView: View {
    @ObservedObject var vm: OnboardingViewModel
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Which rooms do you have?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("Select all that apply")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(RoomIcon.allCases.filter { $0 != .custom }, id: \.rawValue) { icon in
                        roomTile(icon: icon)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }

            VStack(spacing: 8) {
                if vm.selectedRoomIcons.isEmpty {
                    Text("Select at least one room")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    guard !vm.selectedRoomIcons.isEmpty else { return }
                    HapticService.shared.trigger(.medium)
                    vm.advance()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(vm.selectedRoomIcons.isEmpty ? Color.secondary.opacity(0.3) : Color.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(vm.selectedRoomIcons.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .accessibilityLabel("Continue")
                .accessibilityHint(vm.selectedRoomIcons.isEmpty ? "Select at least one room to continue" : "")
            }
        }
        .onAppear {
            FirebaseAnalyticsService.shared.log(.onboardingStepViewed(step: "room_selection"))
        }
    }

    private func roomTile(icon: RoomIcon) -> some View {
        let isSelected = vm.selectedRoomIcons.contains(icon)

        return Button {
            HapticService.shared.trigger(.selection)
            if isSelected {
                vm.selectedRoomIcons.remove(icon)
            } else {
                vm.selectedRoomIcons.insert(icon)
            }
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? Color.accent : Color(.secondarySystemBackground))
                        .frame(width: 60, height: 60)

                    Image(systemName: icon.rawValue)
                        .font(.system(size: 26))
                        .foregroundStyle(isSelected ? .white : Color.accent)
                }

                Text(icon.displayName)
                    .font(.caption.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isSelected ? Color.accent : Color(.label))
                    .lineLimit(2)
            }
            .padding(.vertical, 8)
        }
        .accessibilityLabel(icon.displayName)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
