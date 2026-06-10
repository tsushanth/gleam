import Foundation

enum SubscriptionTier: Equatable {
    case free
    case premium
    case lifetime

    var displayName: String {
        switch self {
        case .free:     return "Free"
        case .premium:  return "Gleam Premium"
        case .lifetime: return "Gleam Lifetime"
        }
    }

    var isPremium: Bool { self != .free }
}
