import SwiftUI

struct PremiumGateView: View {
    let featureName: String
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.accent)

                Text(featureName)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Button {
                    router.presentPaywall(trigger: "feature_gate")
                } label: {
                    Text("Upgrade to Premium")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accent)
                        .clipShape(Capsule())
                }
            }
            .padding(24)
        }
        .accessibilityLabel("\(featureName) — Premium feature. Tap to upgrade.")
    }
}
