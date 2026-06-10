import Foundation

enum TaskFrequency: Int, CaseIterable, Identifiable {
    case daily = 1
    case twiceWeekly = 3
    case weekly = 7
    case biweekly = 14
    case monthly = 30
    case bimonthly = 60
    case quarterly = 90
    case semiannually = 180
    case annually = 365

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .daily:         return "Daily"
        case .twiceWeekly:   return "Every 3 days"
        case .weekly:        return "Weekly"
        case .biweekly:      return "Every 2 weeks"
        case .monthly:       return "Monthly"
        case .bimonthly:     return "Every 2 months"
        case .quarterly:     return "Quarterly"
        case .semiannually:  return "Twice a year"
        case .annually:      return "Yearly"
        }
    }

    static func closest(to days: Int) -> TaskFrequency {
        allCases.min(by: { abs($0.rawValue - days) < abs($1.rawValue - days) }) ?? .weekly
    }
}
