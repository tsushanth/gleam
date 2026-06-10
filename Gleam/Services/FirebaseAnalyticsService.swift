import Foundation
import FirebaseAnalytics

enum GleamAnalyticsEvent {
    // Lifecycle
    case appOpened
    case signUp(method: String)
    case screenView(screenName: String)

    // Onboarding
    case onboardingStarted
    case onboardingStepViewed(step: String)
    case onboardingCompleted(householdType: String)

    // AI
    case aiRoutineRequested
    case aiRoutineCompleted(roomCount: Int, taskCount: Int)

    // Tasks & Rooms
    case taskCompleted(taskName: String)
    case taskCreated(frequencyDays: Int)
    case taskDeleted(taskName: String)
    case roomCreated(roomName: String)

    // Monetisation
    case paywallViewed(trigger: String)
    case purchase(productID: String, value: Double, currency: String)
    case subscriptionStarted(productID: String)
    case subscriptionRestored

    // Features
    case featureUsed(featureName: String)
    case vacationModeEnabled
    case searchUsed(query: String)
    case shareScoreTapped

    var name: String {
        switch self {
        case .appOpened:                    return "app_opened"
        case .signUp:                       return "sign_up"
        case .screenView:                   return AnalyticsEventScreenView
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
        case .purchase:                     return AnalyticsEventPurchase
        case .subscriptionStarted:          return "subscription_started"
        case .subscriptionRestored:         return "subscription_restored"
        case .featureUsed:                  return "feature_used"
        case .vacationModeEnabled:          return "vacation_mode_enabled"
        case .searchUsed:                   return "search_used"
        case .shareScoreTapped:             return "share_score_tapped"
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .signUp(let method):
            return [AnalyticsParameterMethod: method]
        case .screenView(let screenName):
            return [AnalyticsParameterScreenName: screenName]
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
        case .purchase(let productID, let value, let currency):
            return [
                AnalyticsParameterItemID: productID,
                AnalyticsParameterValue: value,
                AnalyticsParameterCurrency: currency
            ]
        case .subscriptionStarted(let productID):
            return ["product_id": productID]
        case .featureUsed(let featureName):
            return ["feature_name": featureName]
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
        setAppVersionProperty()
    }

    func log(_ event: GleamAnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }

    // MARK: - User Properties

    func setSubscriptionStatus(isPremium: Bool) {
        Analytics.setUserProperty(isPremium ? "premium" : "free", forName: "subscription_status")
    }

    /// Kept for backwards compatibility with existing call sites.
    func setUserProperty(isPremium: Bool) {
        setSubscriptionStatus(isPremium: isPremium)
    }

    // MARK: - Private

    private func setAppVersionProperty() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        Analytics.setUserProperty(version, forName: "app_version")
    }
}
