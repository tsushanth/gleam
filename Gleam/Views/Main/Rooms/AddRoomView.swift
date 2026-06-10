import SwiftUI

struct AddRoomView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (String, RoomIcon) -> Void

    @State private var roomName = ""
    @State private var selectedIcon: RoomIcon = .livingRoom
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    TextField("Room name", text: $roomName)
                        .textInputAutocapitalization(.words)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .accessibilityLabel("Room name")

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose an icon")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(RoomIcon.allCases, id: \.rawValue) { icon in
                                Button {
                                    selectedIcon = icon
                                    HapticService.shared.trigger(.selection)
                                } label: {
                                    VStack(spacing: 6) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedIcon == icon ? Color.accent : Color(.secondarySystemBackground))
                                                .frame(width: 56, height: 56)
                                            Image(systemName: icon.rawValue)
                                                .font(.system(size: 22))
                                                .foregroundStyle(selectedIcon == icon ? .white : Color.accent)
                                        }
                                        Text(icon.displayName)
                                            .font(.caption2)
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(selectedIcon == icon ? Color.accent : Color(.secondaryLabel))
                                    }
                                }
                                .accessibilityLabel(icon.displayName)
                                .accessibilityValue(selectedIcon == icon ? "Selected" : "Not selected")
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !roomName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        HapticService.shared.trigger(.medium)
                        onAdd(roomName.trimmingCharacters(in: .whitespaces), selectedIcon)
                        dismiss()
                    }
                    .disabled(roomName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityLabel("Add room")
                }
            }
        }
    }
}
