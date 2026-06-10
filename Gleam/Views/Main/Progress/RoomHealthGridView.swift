import SwiftUI

struct RoomHealthGridView: View {
    let rooms: [Room]
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Room Health")
                .font(.headline)

            if rooms.isEmpty {
                Text("No rooms to display")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(rooms.sorted { $0.aggregateDirtinessScore > $1.aggregateDirtinessScore }) { room in
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(room.dirtinessLevel.color.opacity(0.2))
                                    .frame(height: 52)
                                Image(systemName: room.icon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(room.dirtinessLevel.color)
                            }

                            Text(room.name)
                                .font(.caption2.bold())
                                .lineLimit(1)

                            Circle()
                                .fill(room.dirtinessLevel.color)
                                .frame(width: 8, height: 8)
                        }
                        .accessibilityLabel("\(room.name): \(room.dirtinessLevel.accessibilityLabel)")
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
