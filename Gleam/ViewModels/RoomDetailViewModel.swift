import SwiftUI
import SwiftData

@MainActor
final class RoomDetailViewModel: ObservableObject {
    @Published var tasks: [CleaningTask] = []
    @Published var isAddingTask = false

    func loadTasks(from room: Room) {
        tasks = room.tasks.filter(\.isActive).sorted { $0.sortOrder < $1.sortOrder }
    }

    func moveTask(from source: IndexSet, to destination: Int, in room: Room, context: ModelContext) {
        var reordered = tasks
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, task) in reordered.enumerated() {
            task.sortOrder = index
        }
        tasks = reordered
        try? context.save()
    }

    func deleteTask(_ task: CleaningTask, context: ModelContext) {
        task.isActive = false
        FirebaseAnalyticsService.shared.log(.taskDeleted(taskName: task.name))
        try? context.save()
        if let room = task.room {
            loadTasks(from: room)
        }
    }

    func completeTask(_ task: CleaningTask, context: ModelContext) {
        let userID = UserDefaults.standard.string(forKey: UserDefaultsKeys.currentUserID) ?? "local"
        let log = CompletionLog(completedByUserID: userID)
        task.completionLogs.append(log)
        task.lastCompletedAt = .now
        context.insert(log)

        HapticService.shared.trigger(.taskComplete)
        SoundService.shared.play(.completionChime)
        FirebaseAnalyticsService.shared.log(.taskCompleted(taskName: task.name))
        try? context.save()
    }
}
