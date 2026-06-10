import Foundation
import FirebaseAnalytics

enum GleamAnalyticsEvent {
    case appOpened
    case onboardingStarted
    case onboardingStepViewed(step: String)
    case onboardingCompleted(householdType: String)
    case aiRoutineRequested
    case aiRoutineCompleted(roomCount: Int, taskCount: Int)
    case taskCompleted(taskName: String)
    case taskCreated(frequencyDays: Int)
    case taskDeleted(taskName: String)
    case roomCreated(roomName: String)
    case paywallViewed(trigger: String)
    case subscriptionStarted(productID: String)
    case subscriptionRestored
    case vacationModeEnabled
    case searchUsed(query: String)
    case shareScoreTapped

    var name: String {
        switch self {
        case .appOpened:                    return "app_opened"
        case .onboardingStarted:            return "onboarding_started"
        case .onboardingStepViewed:         return "onboarding_step_viewed"
        case .onboardingCompleted:          return "onboarding_completed"
        case .aiRoutineRequested:           return "ai_routine_requested"
        case .aiRoutineCompleted:           return "ai_routine_completed"
        case .taskCompleted:                return "task_completed"
        case .taskCreated:                  return "task_created"
        case .taskDeleted:                  return "task_deleted"
        case .roomCreated:                  return "room_created"
        case .paywallViewed:                return "paywall_viewed"
        case .subscriptionStarted:         return "subscription_started"
        case .subscriptionRestored:        return "subscription_restored"
        case .vacationModeEnabled:         return "vacation_mode_enabled"
        case .searchUsed:                  return "search_used"
        case .shareScoreTapped:            return "share_score_tapped"
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .onboardingStepViewed(let step):
            return ["step": step]
        case .onboardingCompleted(let householdType):
            return ["household_type": householdType]
        case .aiRoutineCompleted(let roomCount, let taskCount):
            return ["room_count": roomCount, "task_count": taskCount]
        case .taskCompleted(let taskName):
            return ["task_name": taskName]
        case .taskCreated(let frequencyDays):
            return ["frequency_days": frequencyDays]
        case .taskDeleted(let taskName):
            return ["task_name": taskName]
        case .roomCreated(let roomName):
            return ["room_name": roomName]
        case .paywallViewed(let trigger):
            return ["trigger": trigger]
        case .subscriptionStarted(let productID):
            return ["product_id": productID]
        case .searchUsed(let query):
            return ["query_length": query.count]
        default:
            return nil
        }
    }
}

final class FirebaseAnalyticsService {
    static let shared = FirebaseAnalyticsService()

    func configure() {
        Analytics.setAnalyticsCollectionEnabled(true)
    }

    func log(_ event: GleamAnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }

    func setUserProperty(isPremium: Bool) {
        Analytics.setUserProperty(isPremium ? "premium" : "free", forName: "subscription_tier")
    }
}
