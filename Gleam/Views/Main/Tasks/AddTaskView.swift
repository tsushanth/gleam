import SwiftUI
import SwiftData

struct AddTaskView: View {
    let room: Room
    @StateObject private var vm = TaskDetailViewModel()
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let presetTasks: [(String, Int)] = [
        ("Vacuum", 7),
        ("Mop floor", 14),
        ("Wipe surfaces", 7),
        ("Clean windows", 30),
        ("Deep clean", 30),
        ("Organize", 30),
        ("Disinfect", 14),
        ("Dust", 14)
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Name") {
                    TextField("e.g. Vacuum, Wipe counters", text: $vm.name)
                        .textInputAutocapitalization(.sentences)
                        .accessibilityLabel("Task name")
                }

                Section("Quick Presets") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(presetTasks, id: \.0) { name, freq in
                                Button {
                                    vm.name = name
                                    vm.frequencyDays = freq
                                    HapticService.shared.trigger(.selection)
                                } label: {
                                    Text(name)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(vm.name == name ? Color.accent : Color(.secondarySystemBackground))
                                        .foregroundStyle(vm.name == name ? .white : Color(.label))
                                        .clipShape(Capsule())
                                }
                                .accessibilityLabel("\(name) preset")
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Frequency") {
                    ForEach(TaskFrequency.allCases) { freq in
                        Button {
                            vm.frequencyDays = freq.rawValue
                            HapticService.shared.trigger(.selection)
                        } label: {
                            HStack {
                                Text(freq.displayName)
                                    .foregroundStyle(Color(.label))
                                Spacer()
                                if vm.frequencyDays == freq.rawValue {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accent)
                                }
                            }
                        }
                    }
                }

                Section("Notes (Optional)") {
                    TextField("Any notes about this task", text: $vm.notes, axis: .vertical)
                        .lineLimit(2...4)
                        .accessibilityLabel("Notes")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !vm.name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        HapticService.shared.trigger(.medium)
                        vm.createTask(
                            name: vm.name.trimmingCharacters(in: .whitespaces),
                            frequencyDays: vm.frequencyDays,
                            room: room,
                            context: context
                        )
                        dismiss()
                    }
                    .disabled(vm.name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityLabel("Add task")
                }
            }
        }
    }
}
