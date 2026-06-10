import SwiftUI

struct SubscriptionOptionView: View {
    let product: SubscriptionProduct
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(product.displayName)
                            .font(.subheadline.bold())

                        if let badge = product.badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.gleamGreen)
                                .clipShape(Capsule())
                        }
                    }

                    if let perMonth = product.perMonthPrice {
                        Text(perMonth)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(product.price)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isSelected ? Color.accent : Color(.label))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.accent.opacity(0.08) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.accent : Color(.systemFill), lineWidth: isSelected ? 2 : 1)
            )
        }
        .accessibilityLabel("\(product.displayName), \(product.price)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
