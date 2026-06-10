import Foundation

enum DirtinessCalculator {
    static func level(for score: Double) -> DirtinessLevel {
        switch score {
        case ..<50:       return .clean
        case 50..<75:     return .soon
        case 75..<90:     return .needsIt
        default:          return .urgent
        }
    }

    static func percentage(for score: Double) -> Double {
        min(score / 100, 1.0)
    }

    static func nextTransitionDate(task: CleaningTask) -> Date? {
        let thresholds: [Double] = [50, 75, 90, 100]
        let currentScore = task.dirtinessScore
        guard let nextThreshold = thresholds.first(where: { $0 > currentScore }) else { return nil }
        let effectiveLast = task.lastCompletedAt ?? task.createdAt
        let daysToThreshold = (nextThreshold / 100) * Double(task.frequencyDays)
        return effectiveLast.addingTimeInterval(daysToThreshold * 86_400)
    }
}
