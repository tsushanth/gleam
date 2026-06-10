import SwiftData
import Foundation

@Model
final class CleaningTask {
    var id: UUID
    var name: String
    var frequencyDays: Int
    var lastCompletedAt: Date?
    var createdAt: Date
    var isActive: Bool
    var sortOrder: Int

    var notes: String?
    var estimatedMinutes: Int?
    var assignedToUserID: String?
    var notificationHour: Int?
    var notificationMinute: Int?
    var pausedUntil: Date?

    var room: Room?

    @Relationship(deleteRule: .cascade, inverse: \CompletionLog.task)
    var completionLogs: [CompletionLog]

    var dirtinessScore: Double {
        guard isActive else { return 0 }
        let effectiveLastDone: Date = lastCompletedAt ?? createdAt
        let daysSince = Date().timeIntervalSince(effectiveLastDone) / 86_400
        let score = (daysSince / Double(frequencyDays)) * 100
        return min(score, 150)
    }

    var dirtinessLevel: DirtinessLevel {
        DirtinessCalculator.level(for: dirtinessScore)
    }

    var daysUntilDue: Int {
        let daysRemaining = Double(frequencyDays) - (dirtinessScore / 100 * Double(frequencyDays))
        return max(0, Int(daysRemaining))
    }

    init(name: String, frequencyDays: Int, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.frequencyDays = frequencyDays
        self.sortOrder = sortOrder
        self.createdAt = .now
        self.isActive = true
        self.completionLogs = []
    }
}
