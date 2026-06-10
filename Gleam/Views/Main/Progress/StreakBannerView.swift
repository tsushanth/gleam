import SwiftUI

struct StreakBannerView: View {
    let streak: Int
    @State private var flameScale: CGFloat = 1

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.gleamOrange.opacity(0.15))
                    .frame(width: 56, height: 56)
                Text("🔥")
                    .font(.system(size: 28))
                    .scaleEffect(flameScale)
                    .animation(
                        UIAccessibility.isReduceMotionEnabled
                            ? nil
                            : .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: flameScale
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak) day streak")
                    .font(.headline.bold())
                Text(streakMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if streak > 0 {
                Text("+\(streak * 10) pts")
                    .font(.caption.bold())
                    .foregroundStyle(Color.gleamOrange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.gleamOrange.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            guard !UIAccessibility.isReduceMotionEnabled else { return }
            flameScale = 1.1
        }
        .accessibilityLabel("Current streak: \(streak) days. \(streakMessage)")
    }

    private var streakMessage: String {
        if streak == 0 { return "Complete a task today to start your streak!" }
        if streak < 3  { return "Keep it up — you're building a habit!" }
        if streak < 7  { return "Impressive! \(7 - streak) more days for a week streak." }
        if streak < 30 { return "Unstoppable! \(30 - streak) days until a month streak." }
        return "You're a cleaning legend! 🏆"
    }
}
