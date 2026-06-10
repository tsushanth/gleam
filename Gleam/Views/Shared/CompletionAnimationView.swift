import SwiftUI

struct CompletionAnimationView: View {
    let taskName: String
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var checkmarkScale: CGFloat = 0
    @State private var sparkleOffsets: [CGSize] = Array(repeating: .zero, count: 8)
    @State private var sparkleOpacities: [Double] = Array(repeating: 0, count: 8)

    private let sparkleAngles: [Double] = (0..<8).map { Double($0) * 45 }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.gleamGreen.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(Color.gleamGreen)
                        .frame(width: 80, height: 80)
                        .scaleEffect(scale)

                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(checkmarkScale)

                    ForEach(0..<8, id: \.self) { i in
                        Image(systemName: "sparkle")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.gleamGreen)
                            .offset(sparkleOffsets[i])
                            .opacity(sparkleOpacities[i])
                    }
                }

                VStack(spacing: 4) {
                    Text("Done!")
                        .font(.title.bold())
                    Text(taskName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
            )
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            guard !UIAccessibility.isReduceMotionEnabled else {
                scale = 1
                opacity = 1
                checkmarkScale = 1
                return
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1
                opacity = 1
                checkmarkScale = 1
            }
            for i in 0..<8 {
                let angle = sparkleAngles[i] * .pi / 180
                let radius: CGFloat = 70
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                    sparkleOffsets[i] = CGSize(
                        width: cos(angle) * radius,
                        height: sin(angle) * radius
                    )
                    sparkleOpacities[i] = 1
                }
                withAnimation(.easeIn(duration: 0.3).delay(0.5)) {
                    sparkleOpacities[i] = 0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onDismiss()
            }
        }
    }
}
