import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var ctaTitle: String? = nil
    var ctaAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 52))
                .foregroundStyle(.quaternary)

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let ctaTitle, let ctaAction {
                Button(action: ctaAction) {
                    Text(ctaTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accent)
                        .clipShape(Capsule())
                }
                .accessibilityLabel(ctaTitle)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
