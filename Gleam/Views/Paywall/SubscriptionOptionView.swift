import SwiftUI
import StoreKit

struct SubscriptionOptionView: View {
    let product: SubscriptionProduct
    let liveProduct: Product?          // nil when offline / products not yet loaded
    let isSelected: Bool
    let onTap: () -> Void

    /// Formatted price from App Store; falls back to static string when offline.
    private var priceString: String {
        guard let live = liveProduct else { return product.fallbackPrice }
        switch product {
        case .weekly:    return "\(live.displayPrice)/week"
        case .monthly:   return "\(live.displayPrice)/month"
        case .yearly:    return "\(live.displayPrice)/year"
        case .lifetime,
             .removeAds: return live.displayPrice
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Selection indicator
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.accent : Color(.systemFill), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.accent)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(product.displayName)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color(.label))

                        if let badge = product.badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.accent)
                                .clipShape(Capsule())
                        }
                    }

                    if let note = product.perMonthNote {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(priceString)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.accent : Color(.secondaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected
                          ? Color.accent.opacity(0.08)
                          : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.accent : Color(.systemFill),
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .accessibilityLabel("\(product.displayName), \(priceString)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
