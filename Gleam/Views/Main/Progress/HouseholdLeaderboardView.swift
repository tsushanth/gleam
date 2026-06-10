import SwiftUI

struct HouseholdLeaderboardView: View {
    let members: [HouseholdMember]
    @EnvironmentObject private var subscriptionVM: SubscriptionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Leaderboard")
                    .font(.headline)
                Spacer()
                Text("This Week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !subscriptionVM.isPremium {
                PremiumGateView(featureName: "Household Leaderboard")
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if members.isEmpty {
                Text("Invite household members to see the leaderboard.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                    leaderboardRow(rank: index + 1, member: member)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func leaderboardRow(rank: Int, member: HouseholdMember) -> some View {
        HStack(spacing: 14) {
            Text("#\(rank)")
                .font(.caption.bold())
                .foregroundStyle(rankColor(rank))
                .frame(width: 28)

            ZStack {
                Circle()
                    .fill(Color(hex: member.avatarColor))
                    .frame(width: 36, height: 36)
                Text(member.displayName.prefix(1).uppercased())
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }

            Text(member.displayName)
                .font(.subheadline.weight(.medium))

            Spacer()

            Text("\(member.weeklyPoints) pts")
                .font(.caption.bold())
                .foregroundStyle(rankColor(rank))
        }
        .accessibilityLabel("Rank \(rank): \(member.displayName), \(member.weeklyPoints) points")
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color.gleamYellow
        case 2: return Color(.systemGray)
        case 3: return Color.gleamOrange
        default: return Color(.secondaryLabel)
        }
    }
}
