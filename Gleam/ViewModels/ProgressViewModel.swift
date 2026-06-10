import SwiftUI
import SwiftData

struct DailyCount: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
    var label: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

@MainActor
final class ProgressViewModel: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var totalCompletionsThisWeek: Int = 0
    @Published var dailyCounts: [DailyCount] = []
    @Published var leaderboard: [HouseholdMember] = []

    func load(completionLogs: [CompletionLog], members: [HouseholdMember]) {
        currentStreak = calculateStreak(from: completionLogs)
        dailyCounts = calculateDailyCounts(from: completionLogs)
        totalCompletionsThisWeek = dailyCounts.map(\.count).reduce(0, +)
        leaderboard = members.sorted { $0.weeklyPoints > $1.weeklyPoints }
    }

    private func calculateStreak(from logs: [CompletionLog]) -> Int {
        guard !logs.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today

        let completionDates = Set(logs.map { calendar.startOfDay(for: $0.completedAt) })

        while completionDates.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        return streak
    }

    private func calculateDailyCounts(from logs: [CompletionLog]) -> [DailyCount] {
        let calendar = Calendar.current
        let today = Date()

        return (0..<7).reversed().map { daysAgo -> DailyCount in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
            let count = logs.filter {
                $0.completedAt >= startOfDay && $0.completedAt < endOfDay
            }.count
            return DailyCount(date: date, count: count)
        }
    }
}
