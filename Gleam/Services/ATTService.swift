import AppTrackingTransparency
import AdServices
import Foundation
import RevenueCat

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
        do {
            let token = try AAAttribution.attributionToken()
            Purchases.shared.attribution.setAttributes(["adservices_token": token])
        } catch {
            // Attribution token unavailable; silently skip
        }
    }
}
