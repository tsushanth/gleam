import SwiftUI
import SwiftData

@MainActor
final class TaskDetailViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var frequencyDays: Int = 7
    @Published var notes: String = ""
    @Published var estimatedMinutes: Int = 15
    @Published var assignedToUserID: String = ""
    @Published var notificationEnabled = false
    @Published var notificationHour: Int = 9
    @Published var notificationMinute: Int = 0
    @Published var isEditing = false

    func load(task: CleaningTask) {
        name = task.name
        frequencyDays = task.frequencyDays
        notes = task.notes ?? ""
        estimatedMinutes = task.estimatedMinutes ?? 15
        assignedToUserID = task.assignedToUserID ?? ""
        notificationEnabled = task.notificationHour != nil
        notificationHour = task.notificationHour ?? 9
        notificationMinute = task.notificationMinute ?? 0
    }

    func save(task: CleaningTask, context: ModelContext) {
        task.name = name
        task.frequencyDays = frequencyDays
        task.notes = notes.isEmpty ? nil : notes
        task.estimatedMinutes = estimatedMinutes
        task.assignedToUserID = assignedToUserID.isEmpty ? nil : assignedToUserID

        if notificationEnabled {
            task.notificationHour = notificationHour
            task.notificationMinute = notificationMinute
            NotificationService.shared.schedule(for: task)
        } else {
            task.notificationHour = nil
            task.notificationMinute = nil
            NotificationService.shared.cancel(for: task)
        }

        try? context.save()
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

    func snoozeTask(_ task: CleaningTask, days: Int, context: ModelContext) {
        task.pausedUntil = Date().addingTimeInterval(Double(days) * 86_400)
        try? context.save()
        HapticService.shared.trigger(.light)
    }

    func deleteTask(_ task: CleaningTask, context: ModelContext) {
        task.isActive = false
        FirebaseAnalyticsService.shared.log(.taskDeleted(taskName: task.name))
        try? context.save()
    }

    func createTask(name: String, frequencyDays: Int, room: Room, context: ModelContext) {
        let sortOrder = room.tasks.filter(\.isActive).count
        let task = CleaningTask(name: name, frequencyDays: frequencyDays, sortOrder: sortOrder)
        room.tasks.append(task)
        context.insert(task)
        try? context.save()
        FirebaseAnalyticsService.shared.log(.taskCreated(frequencyDays: frequencyDays))
    }
}
