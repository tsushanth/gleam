import AdServices
import Foundation

/// Handles Apple Search Ads attribution via the AdServices framework.
/// Call `fetchToken()` once on first launch; the token is persisted so
/// subsequent launches are no-ops.
final class AttributionManager {
    static let shared = AttributionManager()

    private let tokenKey = "gleam.attributionToken"

    /// Fetches the Apple Search Ads attribution token on first launch and
    /// stores it in UserDefaults. Call this from AppDelegate before the ATT
    /// prompt so the token is available regardless of tracking authorisation.
    func fetchToken() {
        guard UserDefaults.standard.string(forKey: tokenKey) == nil else { return }

        do {
            let token = try AAAttribution.attributionToken()
            UserDefaults.standard.set(token, forKey: tokenKey)
            sendToken(token)
        } catch {
            // AdServices is unavailable on some devices (e.g. simulator, non-Apple hardware).
            // Silently ignore; attribution will fall back to SKAdNetwork.
        }
    }

    /// Returns the previously fetched token, or nil if not yet available.
    var storedToken: String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }

    // MARK: - Private

    private func sendToken(_ token: String) {
        // TODO: POST token to your attribution backend.
        // Example:
        //   var request = URLRequest(url: URL(string: "https://api.yourbackend.com/attribution")!)
        //   request.httpMethod = "POST"
        //   request.httpBody = try? JSONEncoder().encode(["token": token])
        //   URLSession.shared.dataTask(with: request).resume()
        #if DEBUG
        print("[Attribution] Apple Search Ads token: \(token)")
        #endif
    }
}
