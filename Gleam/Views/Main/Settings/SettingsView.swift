import SwiftUI
import SwiftData

struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()
    @EnvironmentObject private var subscriptionVM: SubscriptionViewModel
    @Query private var homes: [Home]

    private var home: Home? { homes.first }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink(destination: AccountView()) {
                        Label("Account & Subscription", systemImage: "person.circle")
                    }
                    .accessibilityLabel("Account and Subscription settings")
                } header: {
                    Text("Account")
                }

                Section {
                    NavigationLink(destination: NotificationSettingsView(vm: vm)) {
                        Label("Notifications", systemImage: "bell")
                    }
                    .accessibilityLabel("Notification settings")

                    NavigationLink(destination: VacationModeView(vm: vm, home: home)) {
                        HStack {
                            Label("Vacation Mode", systemImage: "airplane")
                            Spacer()
                            if vm.isVacationModeActive {
                                Text("On")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.gleamOrange)
                            }
                        }
                    }
                    .accessibilityLabel("Vacation mode")
                } header: {
                    Text("Features")
                }

                Section {
                    Toggle(isOn: Binding(
                        get: { vm.hapticsEnabled },
                        set: { _ in vm.toggleHaptics() }
                    )) {
                        Label("Haptic Feedback", systemImage: "hand.tap")
                    }
                    .accessibilityLabel("Toggle haptic feedback")

                    Toggle(isOn: Binding(
                        get: { vm.soundsEnabled },
                        set: { _ in vm.toggleSounds() }
                    )) {
                        Label("Completion Sounds", systemImage: "speaker.wave.2")
                    }
                    .accessibilityLabel("Toggle completion sounds")
                } header: {
                    Text("Appearance & Feel")
                }

                Section {
                    NavigationLink(destination: HouseholdMembersView()) {
                        HStack {
                            Label("Household Members", systemImage: "person.2")
                            Spacer()
                            if !subscriptionVM.isPremium {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.accent)
                            }
                        }
                    }
                    .accessibilityLabel("Household Members" + (subscriptionVM.isPremium ? "" : " — Premium feature"))
                } header: {
                    Text("Household")
                }

                Section {
                    Button {
                        if let url = URL(string: "https://appfactory.com/gleam/privacy") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Privacy Policy", systemImage: "doc.text")
                            .foregroundStyle(Color(.label))
                    }
                    .accessibilityLabel("View Privacy Policy")

                    Button {
                        if let url = URL(string: "itms-apps://itunes.apple.com/app/idYOUR_APP_ID?action=write-review") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Rate Gleam ⭐", systemImage: "star")
                            .foregroundStyle(Color(.label))
                    }
                    .accessibilityLabel("Rate Gleam on the App Store")
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
