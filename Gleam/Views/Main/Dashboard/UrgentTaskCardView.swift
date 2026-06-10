import SwiftUI
import SwiftData

struct UrgentTaskCardView: View {
    let task: CleaningTask
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let roomIcon = task.room?.icon {
                    Image(systemName: roomIcon)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                Text(task.room?.name ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(Color.gleamRed)
                    .font(.system(size: 16))
            }

            Text(task.name)
                .font(.subheadline.bold())
                .lineLimit(2)

            DirtinessMeterView(score: task.dirtinessScore, showLabel: false)

            Button(action: onComplete) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                    Text("Just Did It")
                        .font(.caption.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.gleamRed)
                .clipShape(Capsule())
            }
            .accessibilityLabel("Mark \(task.name) as done")
        }
        .padding(16)
        .frame(width: 180)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.name), \(task.room?.name ?? ""), urgent — clean now")
    }
}
