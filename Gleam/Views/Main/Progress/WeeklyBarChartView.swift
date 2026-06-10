import SwiftUI
import Charts

struct WeeklyBarChartView: View {
    let dailyCounts: [DailyCount]

    private var maxCount: Int {
        max(dailyCounts.map(\.count).max() ?? 0, 5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            Chart(dailyCounts) { day in
                BarMark(
                    x: .value("Day", day.label),
                    y: .value("Tasks", day.count)
                )
                .foregroundStyle(
                    day.date.isToday
                        ? Color.accent
                        : Color.accent.opacity(0.4)
                )
                .cornerRadius(6)
                .annotation(position: .top) {
                    if day.count > 0 {
                        Text("\(day.count)")
                            .font(.caption2.bold())
                            .foregroundStyle(day.date.isToday ? Color.accent : Color(.secondaryLabel))
                    }
                }
            }
            .chartYScale(domain: 0...maxCount)
            .chartYAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
            .frame(height: 160)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel("Weekly bar chart showing tasks completed each day")
    }
}
