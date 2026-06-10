import UIKit

enum HapticStyle {
    case light
    case medium
    case heavy
    case taskComplete
    case error
    case selection
}

final class HapticService {
    static let shared = HapticService()

    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: UserDefaultsKeys.hapticsEnabled) as? Bool ?? true
    }

    func trigger(_ style: HapticStyle) {
        guard isEnabled else { return }
        switch style {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy, .taskComplete:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}
