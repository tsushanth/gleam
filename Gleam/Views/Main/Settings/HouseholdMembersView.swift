import SwiftUI
import SwiftData

struct HouseholdMembersView: View {
    @Query private var members: [HouseholdMember]
    @EnvironmentObject private var subscriptionVM: SubscriptionViewModel
    @State private var showInviteSheet = false

    var body: some View {
        Group {
            if !subscriptionVM.isPremium {
                PremiumGateView(featureName: "Household Members")
                    .navigationTitle("Household Members")
            } else {
                Form {
                    Section {
                        if members.isEmpty {
                            Text("No other members yet. Invite someone to share your home!")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        } else {
                            ForEach(members) { member in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: member.avatarColor))
                                            .frame(width: 36, height: 36)
                                        Text(member.displayName.prefix(1).uppercased())
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.white)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(member.displayName)
                                            .font(.subheadline.weight(.medium))
                                        Text("Joined \(member.joinedAt.shortFormatted)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Text("\(member.totalPoints) pts")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                }
                                .accessibilityLabel("\(member.displayName), \(member.totalPoints) total points, joined \(member.joinedAt.shortFormatted)")
                            }
                        }
                    } header: {
                        Text("Members")
                    }

                    Section {
                        Button {
                            showInviteSheet = true
                        } label: {
                            Label("Invite a Member", systemImage: "person.badge.plus")
                        }
                        .accessibilityLabel("Invite a household member")
                    }
                }
                .navigationTitle("Household Members")
                .sheet(isPresented: $showInviteSheet) {
                    Text("Invite flow coming soon")
                        .presentationDetents([.medium])
                }
            }
        }
    }
}
