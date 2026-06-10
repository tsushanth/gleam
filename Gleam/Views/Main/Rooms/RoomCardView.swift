import SwiftUI

struct RoomCardView: View {
    let room: Room

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(room.dirtinessLevel.color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: room.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(room.dirtinessLevel.color)
                }
                Spacer()
                Text("\(room.tasks.filter(\.isActive).count)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(room.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                Text(room.dirtinessLevel.accessibilityLabel)
                    .font(.caption)
                    .foregroundStyle(room.dirtinessLevel.color)
            }

            DirtinessMeterView(score: room.aggregateDirtinessScore, showLabel: false)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(room.name) — \(room.dirtinessLevel.accessibilityLabel), \(room.tasks.filter(\.isActive).count) tasks")
    }
}
