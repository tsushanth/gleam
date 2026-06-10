import SwiftUI
import SwiftData

struct TaskDetailView: View {
    let task: CleaningTask
    @StateObject private var vm = TaskDetailViewModel()
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionVM: SubscriptionViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Task name", text: $vm.name)
                        .accessibilityLabel("Task name")

                    HStack {
                        Text("Frequency")
                        Spacer()
                        Menu {
                            ForEach(TaskFrequency.allCases) { freq in
                                Button(freq.displayName) {
                                    vm.frequencyDays = freq.rawValue
                                }
                            }
                        } label: {
                            Text(TaskFrequency.closest(to: vm.frequencyDays).displayName)
                                .foregroundStyle(Color.accent)
                        }
                    }

                    HStack {
                        Text("Estimated time")
                        Spacer()
                        Stepper("\(vm.estimatedMinutes) min", value: $vm.estimatedMinutes, in: 1...120, step: 5)
                            .labelsHidden()
                        Text("\(vm.estimatedMinutes) min")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notes") {
                    TextField("Add a note (optional)", text: $vm.notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Notes")
                }

                Section {
                    if subscriptionVM.isPremium {
                        Toggle("Notification reminder", isOn: $vm.notificationEnabled)
                            .accessibilityLabel("Enable notification reminder")

                        if vm.notificationEnabled {
                            DatePicker(
                                "Reminder time",
                                selection: Binding(
                                    get: {
                                        Calendar.current.date(bySettingHour: vm.notificationHour,
                                                             minute: vm.notificationMinute,
                                                             second: 0, of: Date()) ?? Date()
                                    },
                                    set: { date in
                                        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                                        vm.notificationHour = components.hour ?? 9
                                        vm.notificationMinute = components.minute ?? 0
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                        }
                    } else {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Per-task notifications")
                                    .font(.subheadline)
                                Text("Premium feature")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "lock.fill")
                                .foregroundStyle(Color.accent)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            AppRouter.shared.presentPaywall(trigger: "feature_gate")
                        }
                    }
                } header: {
                    Text("Reminders")
                }

                Section {
                    Button {
                        vm.completeTask(task, context: context)
                        dismiss()
                    } label: {
                        Label("Mark as Done", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(Color.gleamGreen)
                    }
                    .accessibilityLabel("Mark \(task.name) as done")

                    Menu {
                        Button("Snooze 1 day") { vm.snoozeTask(task, days: 1, context: context) }
                        Button("Snooze 3 days") { vm.snoozeTask(task, days: 3, context: context) }
                        Button("Snooze 1 week") { vm.snoozeTask(task, days: 7, context: context) }
                    } label: {
                        Label("Snooze Task", systemImage: "moon.zzz.fill")
                            .foregroundStyle(Color.gleamYellow)
                    }
                    .accessibilityLabel("Snooze task")

                    Button(role: .destructive) {
                        vm.deleteTask(task, context: context)
                        dismiss()
                    } label: {
                        Label("Delete Task", systemImage: "trash")
                    }
                    .accessibilityLabel("Delete \(task.name)")
                } header: {
                    Text("Actions")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        vm.save(task: task, context: context)
                        dismiss()
                    }
                    .accessibilityLabel("Save changes")
                }
            }
            .onAppear { vm.load(task: task) }
        }
    }
}
