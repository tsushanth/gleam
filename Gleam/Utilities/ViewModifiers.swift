import SwiftUI

struct PremiumGateModifier: ViewModifier {
    @EnvironmentObject var subscriptionVM: SubscriptionViewModel
    let feature: String

    func body(content: Content) -> some View {
        content
            .overlay {
                if !subscriptionVM.isPremium {
                    PremiumGateView(featureName: feature)
                }
            }
            .allowsHitTesting(subscriptionVM.isPremium)
    }
}

struct HapticOnTapModifier: ViewModifier {
    let style: HapticStyle

    func body(content: Content) -> some View {
        content.onTapGesture {
            HapticService.shared.trigger(style)
        }
    }
}

extension View {
    func premiumGate(feature: String) -> some View {
        modifier(PremiumGateModifier(feature: feature))
    }

    func hapticOnTap(_ style: HapticStyle = .light) -> some View {
        modifier(HapticOnTapModifier(style: style))
    }
}
