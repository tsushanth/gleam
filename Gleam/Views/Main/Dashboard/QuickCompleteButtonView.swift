import SwiftUI

struct QuickCompleteButtonView: View {
    let urgentTasks: [CleaningTask]
    let onComplete: (CleaningTask) -> Void

    @State private var showingPicker = false

    var body: some View {
        Button {
            if let first = urgentTasks.first {
                if urgentTasks.count == 1 {
                    onComplete(first)
                } else {
                    showingPicker = true
                }
            }
            HapticService.shared.trigger(.medium)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("Just Did It")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                urgentTasks.isEmpty
                    ? Color.secondary.opacity(0.3)
                    : Color.gleamRed
            )
            .clipShape(Capsule())
            .shadow(color: urgentTasks.isEmpty ? .clear : Color.gleamRed.opacity(0.4), radius: 8, y: 4)
        }
        .disabled(urgentTasks.isEmpty)
        .accessibilityLabel("Quick complete — mark your most urgent task done")
        .confirmationDialog("Which task did you complete?", isPresented: $showingPicker, titleVisibility: .visible) {
            ForEach(urgentTasks.prefix(5)) { task in
                Button(task.name) {
                    onComplete(task)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
