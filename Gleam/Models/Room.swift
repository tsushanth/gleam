import SwiftData
import Foundation

@Model
final class Room {
    var id: UUID
    var name: String
    var icon: String
    var sortOrder: Int
    var createdAt: Date

    var home: Home?

    @Relationship(deleteRule: .cascade, inverse: \CleaningTask.room)
    var tasks: [CleaningTask]

    var aggregateDirtinessScore: Double {
        tasks.filter { $0.isActive }.map { $0.dirtinessScore }.max() ?? 0
    }

    var dirtinessLevel: DirtinessLevel {
        DirtinessCalculator.level(for: aggregateDirtinessScore)
    }

    init(name: String, icon: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.createdAt = .now
        self.tasks = []
    }
}
