import SwiftUI
import SwiftData

struct VacationModeView: View {
    @ObservedObject var vm: SettingsViewModel
    let home: Home?
    @Environment(\.modelContext) private var context

    var body: some View {
        Form {
            Section {
                Toggle("Vacation Mode", isOn: $vm.isVacationModeActive)
                    .onChange(of: vm.isVacationModeActive) { _, enabled in
                        if let home {
                            if enabled {
                                vm.activateVacationMode(home: home, context: context)
                            } else {
                                vm.deactivateVacationMode(home: home, context: context)
                            }
                        }
                    }
                    .accessibilityLabel("Toggle vacation mode")

                if vm.isVacationModeActive {
                    DatePicker(
                        "Paused until",
                        selection: $vm.vacationEndDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .onChange(of: vm.vacationEndDate) { _, date in
                        if let home {
                            home.pausedUntil = date
                            try? context.save()
                        }
                    }
                    .accessibilityLabel("Vacation end date")
                }
            } header: {
                Text("Vacation Mode")
            } footer: {
                Text("While vacation mode is active, dirtiness scores are frozen. Tasks won't become more urgent while you're away.")
            }

            Section {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.accent)
                    Text("Dirtiness accumulation is paused for all rooms and tasks while this mode is on.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Vacation Mode")
        .navigationBarTitleDisplayMode(.inline)
    }
}
