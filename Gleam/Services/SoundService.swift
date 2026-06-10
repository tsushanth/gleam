import AVFoundation
import UIKit

enum SoundEffect: String {
    case completionChime = "completion_chime"
}

final class SoundService {
    static let shared = SoundService()

    private var player: AVAudioPlayer?

    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: UserDefaultsKeys.soundsEnabled) as? Bool ?? true
    }

    func play(_ effect: SoundEffect) {
        guard isEnabled else { return }
        guard !UIAccessibility.isReduceMotionEnabled else { return }

        guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "caf") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            // Sound file not found; silently skip
        }
    }
}
