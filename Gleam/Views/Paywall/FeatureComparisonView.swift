import SwiftUI

private struct FeatureRow: Identifiable {
    let id = UUID()
    let name: String
    let free: Bool
    let premium: Bool
}

struct FeatureComparisonView: View {
    private let features: [FeatureRow] = [
        FeatureRow(name: "Dirtiness tracking", free: true, premium: true),
        FeatureRow(name: "Room organization", free: true, premium: true),
        FeatureRow(name: "Task completion", free: true, premium: true),
        FeatureRow(name: "Drag-to-reorder", free: true, premium: true),
        FeatureRow(name: "Full-text search", free: true, premium: true),
        FeatureRow(name: "1 AI routine/month", free: true, premium: true),
        FeatureRow(name: "Unlimited AI routines", free: false, premium: true),
        FeatureRow(name: "Cloud sync", free: false, premium: true),
        FeatureRow(name: "Multi-user household", free: false, premium: true),
        FeatureRow(name: "Leaderboard", free: false, premium: true),
        FeatureRow(name: "Per-task notifications", free: false, premium: true),
        FeatureRow(name: "iOS widgets", free: false, premium: true),
        FeatureRow(name: "Advanced analytics", free: false, premium: true),
        FeatureRow(name: "Custom themes", free: false, premium: true)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Feature")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Free")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(width: 48)

                Text("Premium")
                    .font(.caption.bold())
                    .foregroundStyle(Color.accent)
                    .frame(width: 72)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))

            ForEach(features) { feature in
                HStack {
                    Text(feature.name)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: feature.free ? "checkmark" : "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(feature.free ? Color.gleamGreen : Color(.tertiaryLabel))
                        .frame(width: 48)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.gleamGreen)
                        .frame(width: 72)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.systemFill), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}
