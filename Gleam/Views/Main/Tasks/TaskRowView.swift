import SwiftUI

struct TaskRowView: View {
    let task: CleaningTask
    let onComplete: () -> Void

    @State private var showingDetail = false
    @State private var swipeOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onComplete) {
                ZStack {
                    Circle()
                        .stroke(task.dirtinessLevel.color, lineWidth: 2)
                        .frame(width: 32, height: 32)
                    if swipeOffset < -40 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(task.dirtinessLevel.color)
                    }
                }
            }
            .accessibilityLabel("Mark \(task.name) as done")

            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.subheadline.weight(.medium))
                    .strikethrough(false)

                HStack(spacing: 8) {
                    if let roomName = task.room?.name {
                        Text(roomName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    daysLabel
                }
            }

            Spacer()

            DirtinessMeterView(score: task.dirtinessScore, showLabel: false)
                .frame(width: 60)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture { showingDetail = true }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: onComplete) {
                Label("Done", systemImage: "checkmark.circle.fill")
            }
            .tint(task.dirtinessLevel.color)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                // snooze handled in detail
            } label: {
                Label("Snooze", systemImage: "moon.zzz.fill")
            }
            .tint(Color.gleamYellow)
        }
        .contextMenu {
            Button("Mark Done") { onComplete() }
            Button("Edit") { showingDetail = true }
            Divider()
            Button("Delete", role: .destructive) {}
        }
        .sheet(isPresented: $showingDetail) {
            TaskDetailView(task: task)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.name), \(task.room?.name ?? ""), \(task.dirtinessLevel.accessibilityLabel)")
        .accessibilityHint("Tap to view details, swipe right to complete")
    }

    private var daysLabel: some View {
        Group {
            if task.daysUntilDue == 0 {
                Text("Overdue")
                    .font(.caption.bold())
                    .foregroundStyle(Color.gleamRed)
            } else if task.daysUntilDue == 1 {
                Text("Due tomorrow")
                    .font(.caption)
                    .foregroundStyle(Color.gleamOrange)
            } else {
                Text("Due in \(task.daysUntilDue)d")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
