import SwiftUI

struct PaywallView: View {
    var isOnboarding: Bool = false
    @StateObject private var vm = SubscriptionViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isOnboarding {
                    HStack {
                        Spacer()
                        Button("Maybe Later") {
                            dismiss()
                        }
                        .foregroundStyle(.secondary)
                        .padding()
                        .accessibilityLabel("Skip and continue without Premium")
                    }
                }

                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accent)

                    Text("Gleam Premium")
                        .font(.largeTitle.bold())

                    Text("The cleanest home you've ever lived in.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                FeatureComparisonView()

                VStack(spacing: 12) {
                    ForEach(SubscriptionProduct.allCases) { product in
                        SubscriptionOptionView(
                            product: product,
                            isSelected: vm.selectedProduct == product,
                            onTap: {
                                vm.selectedProduct = product
                                HapticService.shared.trigger(.selection)
                            }
                        )
                    }
                }
                .padding(.horizontal)

                Button {
                    HapticService.shared.trigger(.medium)
                    Task { await vm.purchase() }
                } label: {
                    Group {
                        if vm.isPurchasing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Label(vm.ctaTitle, systemImage: "arrow.right")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)
                .disabled(vm.isPurchasing)
                .accessibilityLabel(vm.ctaTitle)

                Text("7-day free trial included. Cancel anytime.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Restore Purchase") {
                    Task { await vm.restorePurchases() }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Restore previous purchase")
            }
            .padding(.vertical)
        }
        .alert("Error", isPresented: Binding(
            get: { vm.error != nil },
            set: { if !$0 { vm.error = nil } }
        )) {
            Button("OK") { vm.error = nil }
        } message: {
            Text(vm.error ?? "")
        }
        .onAppear {
            FirebaseAnalyticsService.shared.log(.paywallViewed(trigger: isOnboarding ? "post_onboarding" : "settings"))
        }
    }
}
