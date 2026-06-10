import UserNotifications
import Foundation

final class NotificationService {
    static let shared = NotificationService()

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        return granted
    }

    func schedule(for task: CleaningTask) {
        guard let hour = task.notificationHour,
              let minute = task.notificationMinute else { return }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])

        let content = UNMutableNotificationContent()
        content.title = "Time to clean"
        content.body = "\(task.name) is due for cleaning."
        content.sound = .default
        content.badge = 1

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    func cancel(for task: CleaningTask) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
