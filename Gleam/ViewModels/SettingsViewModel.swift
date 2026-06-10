import SwiftUI
import SwiftData

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isVacationModeActive = false
    @Published var vacationEndDate = Date().addingTimeInterval(7 * 86_400)
    @Published var hapticsEnabled = true
    @Published var soundsEnabled = true
    @Published var notificationsEnabled = false
    @Published var showDeleteConfirmation = false

    init() {
        hapticsEnabled = UserDefaults.standard.object(forKey: UserDefaultsKeys.hapticsEnabled) as? Bool ?? true
        soundsEnabled = UserDefaults.standard.object(forKey: UserDefaultsKeys.soundsEnabled) as? Bool ?? true
    }

    func toggleHaptics() {
        hapticsEnabled.toggle()
        UserDefaults.standard.set(hapticsEnabled, forKey: UserDefaultsKeys.hapticsEnabled)
    }

    func toggleSounds() {
        soundsEnabled.toggle()
        UserDefaults.standard.set(soundsEnabled, forKey: UserDefaultsKeys.soundsEnabled)
    }

    func activateVacationMode(home: Home, context: ModelContext) {
        home.isPaused = true
        home.pausedUntil = vacationEndDate
        isVacationModeActive = true
        try? context.save()
        FirebaseAnalyticsService.shared.log(.vacationModeEnabled)
    }

    func deactivateVacationMode(home: Home, context: ModelContext) {
        home.isPaused = false
        home.pausedUntil = nil
        isVacationModeActive = false
        try? context.save()
    }

    func requestNotificationPermission() async {
        notificationsEnabled = await NotificationService.shared.requestAuthorization()
    }

    func deleteAllData(context: ModelContext) async {
        try? context.delete(model: CompletionLog.self)
        try? context.delete(model: CleaningTask.self)
        try? context.delete(model: Room.self)
        try? context.delete(model: HouseholdMember.self)
        try? context.delete(model: Home.self)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.hasCompletedOnboarding)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.currentUserID)
    }
}
