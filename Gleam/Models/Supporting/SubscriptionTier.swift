import Foundation

enum SubscriptionTier: String, Equatable {
    case free     = "free"
    case premium  = "premium"
    case lifetime = "lifetime"

    var displayName: String {
        switch self {
        case .free:     return "Free"
        case .premium:  return "Gleam Premium"
        case .lifetime: return "Gleam Lifetime"
        }
    }

    var isPremium: Bool { self != .free }
}
