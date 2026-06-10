import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @ObservedObject var vm: SettingsViewModel
    @Query private var allTasks: [CleaningTask]

    var body: some View {
        Form {
            Section {
                Toggle("Enable Notifications", isOn: $vm.notificationsEnabled)
                    .onChange(of: vm.notificationsEnabled) { _, enabled in
                        if enabled {
                            Task { await vm.requestNotificationPermission() }
                        } else {
                            NotificationService.shared.cancelAll()
                        }
                    }
                    .accessibilityLabel("Toggle push notifications")
            } header: {
                Text("Global Settings")
            } footer: {
                Text("Gleam can remind you when rooms need attention. Per-task notification times are available with Premium.")
            }

            if vm.notificationsEnabled {
                Section {
                    ForEach(allTasks.filter(\.isActive).prefix(10)) { task in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.name)
                                    .font(.subheadline)
                                if let roomName = task.room?.name {
                                    Text(roomName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if task.notificationHour != nil {
                                Text("\(String(format: "%02d", task.notificationHour ?? 9)):\(String(format: "%02d", task.notificationMinute ?? 0))")
                                    .font(.caption)
                                    .foregroundStyle(Color.accent)
                            } else {
                                Text("Not set")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Per-Task Reminders")
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}
