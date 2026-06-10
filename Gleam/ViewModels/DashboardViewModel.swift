import SwiftUI
import SwiftData

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var urgentTasks: [CleaningTask] = []
    @Published var todaysFocus: [CleaningTask] = []
    @Published var comingUp: [CleaningTask] = []
    @Published var homeScore: Double = 100
    @Published var showCompletionAnimation = false
    @Published var lastCompletedTaskName: String = ""

    func computeHomeScore(from tasks: [CleaningTask]) -> Double {
        guard !tasks.isEmpty else { return 100 }
        let avgDirtiness = tasks.map(\.dirtinessScore).reduce(0, +) / Double(tasks.count)
        return max(0, 100 - avgDirtiness)
    }

    func loadDashboard(tasks: [CleaningTask]) {
        let active = tasks.filter(\.isActive)
        urgentTasks = active.filter { $0.dirtinessLevel == .urgent }
            .sorted { $0.dirtinessScore > $1.dirtinessScore }
        todaysFocus = active.filter { $0.dirtinessLevel == .needsIt }
            .sorted { $0.dirtinessScore > $1.dirtinessScore }
            .prefix(5).map { $0 }
        comingUp = active.filter { $0.dirtinessLevel == .soon }
            .sorted { $0.dirtinessScore > $1.dirtinessScore }
            .prefix(5).map { $0 }
        homeScore = computeHomeScore(from: active)
    }

    func completeTask(_ task: CleaningTask, context: ModelContext) {
        let userID = UserDefaults.standard.string(forKey: UserDefaultsKeys.currentUserID) ?? "local"
        let log = CompletionLog(completedByUserID: userID)
        task.completionLogs.append(log)
        task.lastCompletedAt = .now
        context.insert(log)

        lastCompletedTaskName = task.name
        showCompletionAnimation = true

        HapticService.shared.trigger(.taskComplete)
        SoundService.shared.play(.completionChime)
        FirebaseAnalyticsService.shared.log(.taskCompleted(taskName: task.name))
    }
}
