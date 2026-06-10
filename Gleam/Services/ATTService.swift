import AppTrackingTransparency
import AdServices
import Foundation

final class ATTService {
    static let shared = ATTService()

    func requestPermission() async {
        guard !UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasSeenATTPrompt) else { return }
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasSeenATTPrompt)

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        let status = await ATTrackingManager.requestTrackingAuthorization()

        if status == .authorized {
            attributeViaAdServices()
        }

        FirebaseAnalyticsService.shared.log(.appOpened)
    }

    private func attributeViaAdServices() {
        guard let token = try? AAAttribution.attributionToken() else { return }
        // Forward to your analytics/attribution backend as needed.
        _ = token
    }
}
