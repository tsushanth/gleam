import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String = "Search"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityLabel(placeholder)

            if !text.isEmpty {
                Button {
                    text = ""
                    HapticService.shared.trigger(.light)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemFill))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
