import SwiftUI
import SwiftData
import AuthenticationServices

struct AccountView: View {
    @EnvironmentObject private var subscriptionVM: SubscriptionViewModel
    @Environment(\.modelContext) private var context
    @StateObject private var vm = SettingsViewModel()
    @State private var showDeleteConfirmation = false
    @State private var showPaywall = false

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.accent.opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gleam User")
                            .font(.subheadline.bold())
                        Text(subscriptionVM.tier.displayName)
                            .font(.caption)
                            .foregroundStyle(subscriptionVM.isPremium ? Color.accent : Color.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Account: \(subscriptionVM.tier.displayName)")
            } header: {
                Text("Account")
            }

            Section {
                if subscriptionVM.isPremium {
                    HStack {
                        Label("Active subscription", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Color.gleamGreen)
                        Spacer()
                        Text(subscriptionVM.tier.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        Label("Upgrade to Premium", systemImage: "sparkles")
                    }
                    .accessibilityLabel("Upgrade to Gleam Premium")
                }

                Button {
                    Task { await subscriptionVM.restorePurchases() }
                } label: {
                    Label("Restore Purchases", systemImage: "arrow.clockwise")
                }
                .foregroundStyle(Color(.label))
                .accessibilityLabel("Restore previous purchases")
            } header: {
                Text("Subscription")
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete My Data", systemImage: "trash.fill")
                }
                .accessibilityLabel("Delete all my data")
                .accessibilityHint("This action cannot be undone")
            } header: {
                Text("Data")
            } footer: {
                Text("Deletes all rooms, tasks, and history from this device. This cannot be undone.")
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
            Button("Delete Everything", role: .destructive) {
                Task { await vm.deleteAllData(context: context) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your rooms, tasks, and cleaning history. This cannot be undone.")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}
