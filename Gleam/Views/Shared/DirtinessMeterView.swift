import SwiftUI

struct DirtinessMeterView: View {
    let score: Double
    let showLabel: Bool

    private var level: DirtinessLevel { DirtinessCalculator.level(for: score) }
    private var fillPercent: Double { DirtinessCalculator.percentage(for: score) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemFill))
                        .frame(height: 8)

                    Capsule()
                        .fill(level.color)
                        .frame(width: max(geo.size.width * fillPercent, 0), height: 8)
                        .animation(.spring(duration: 0.4), value: fillPercent)
                }
            }
            .frame(height: 8)

            if showLabel {
                Text(level.accessibilityLabel)
                    .font(.caption2)
                    .foregroundStyle(level.color)
            }
        }
        .accessibilityLabel(level.accessibilityLabel)
        .accessibilityValue("\(Int(min(score, 100)))% dirty")
    }
}

#Preview {
    VStack(spacing: 16) {
        DirtinessMeterView(score: 20, showLabel: true)
        DirtinessMeterView(score: 60, showLabel: true)
        DirtinessMeterView(score: 80, showLabel: true)
        DirtinessMeterView(score: 95, showLabel: true)
    }
    .padding()
}
