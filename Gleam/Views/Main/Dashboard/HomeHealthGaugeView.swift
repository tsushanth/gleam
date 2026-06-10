import SwiftUI

struct HomeHealthGaugeView: View {
    let score: Double

    private var displayScore: Int { Int(score) }
    private var level: DirtinessLevel { DirtinessCalculator.level(for: 100 - score) }
    private var strokeColor: Color {
        if score >= 80 { return Color.gleamGreen }
        if score >= 60 { return Color.gleamYellow }
        if score >= 40 { return Color.gleamOrange }
        return Color.gleamRed
    }

    private var healthLabel: String {
        if score >= 80 { return "Looking great!" }
        if score >= 60 { return "Pretty good" }
        if score >= 40 { return "Needs attention" }
        return "Urgent care needed"
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color(.systemFill), style: StrokeStyle(lineWidth: 14, lineCap: .round))

                Circle()
                    .trim(from: 0, to: score / 100)
                    .stroke(strokeColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.8), value: score)

                VStack(spacing: 4) {
                    Text("\(displayScore)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(strokeColor)
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.5), value: displayScore)

                    Text("Home Health")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 160, height: 160)

            Text(healthLabel)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(strokeColor)
        }
        .accessibilityLabel("Home health score: \(displayScore) out of 100")
        .accessibilityValue(healthLabel)
    }
}
