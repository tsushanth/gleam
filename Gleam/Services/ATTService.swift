import AppTrackingTransparency
import FacebookCore
import Foundation

final class ATTService {
    static let shared = ATTService()

    /// Request tracking authorisation once per install. Must be called after
    /// the first UI frame is rendered (the built-in 1-second delay handles this).
    /// Initialises dependent SDKs (Facebook) after the user responds.
    func requestPermission() async {
        guard !UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasSeenATTPrompt) else { return }
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasSeenATTPrompt)

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        let status = await ATTrackingManager.requestTrackingAuthorization()

        // Enable/disable Facebook auto-event logging based on user choice.
        Settings.shared.isAutoLogAppEventsEnabled = (status == .authorized)
        Settings.shared.isAdvertiserIDCollectionEnabled = (status == .authorized)

        FirebaseAnalyticsService.shared.log(.appOpened)
    }
}
