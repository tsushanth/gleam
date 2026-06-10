import SwiftUI
import SwiftData

struct GleamProgressView: View {
    @StateObject private var vm = ProgressViewModel()
    @Query private var completionLogs: [CompletionLog]
    @Query private var rooms: [Room]
    @Query private var members: [HouseholdMember]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    StreakBannerView(streak: vm.currentStreak)

                    HStack(spacing: 16) {
                        statCard(value: "\(vm.totalCompletionsThisWeek)", label: "This Week")
                        statCard(value: "\(completionLogs.count)", label: "All Time")
                    }

                    WeeklyBarChartView(dailyCounts: vm.dailyCounts)

                    RoomHealthGridView(rooms: rooms)

                    HouseholdLeaderboardView(members: vm.leaderboard)
                }
                .padding()
            }
            .navigationTitle("Progress")
            .onChange(of: completionLogs) { _, logs in
                vm.load(completionLogs: logs, members: members)
            }
            .onAppear {
                vm.load(completionLogs: completionLogs, members: members)
            }
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Color.accent)
                .contentTransition(.numericText())

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel("\(label): \(value)")
    }
}
