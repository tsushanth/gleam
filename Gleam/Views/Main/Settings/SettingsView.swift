import SwiftUI
import SwiftData

struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()
    @EnvironmentObject private var subscriptionVM: SubscriptionViewModel
    @Query private var homes: [Home]
    @State private var showPaywall = false

    private var home: Home? { homes.first }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Premium Banner (non-premium users only)
                if !subscriptionVM.isPremium {
                    Section {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.accent.opacity(0.12))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(Color.accent)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Upgrade to Gleam Premium")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(Color(.label))
                                    Text("Unlock all features · 7-day free trial")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color(.tertiaryLabel))
                            }
                        }
                        .accessibilityLabel("Upgrade to Gleam Premium — 7-day free trial")
                    }
                }

                // MARK: Account
                Section {
                    NavigationLink(destination: AccountView()) {
                        Label("Account & Subscription", systemImage: "person.circle")
                    }
                    .accessibilityLabel("Account and Subscription settings")
                } header: {
                    Text("Account")
                }

                // MARK: Features
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

                // MARK: Appearance & Feel
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

                // MARK: Household (PRO)
                Section {
                    NavigationLink(destination: HouseholdMembersView()) {
                        HStack {
                            Label("Household Members", systemImage: "person.2")
                            Spacer()
                            if !subscriptionVM.isPremium {
                                ProBadge()
                            }
                        }
                    }
                    .accessibilityLabel("Household Members" + (subscriptionVM.isPremium ? "" : " — Premium feature"))
                } header: {
                    Text("Household")
                }

                // MARK: About
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
            .sheet(isPresented: $showPaywall) {
                PaywallView(trigger: "settings")
            }
        }
    }
}

// MARK: - PRO Badge

struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.accent)
            .clipShape(Capsule())
            .accessibilityLabel("Premium feature")
    }
}
