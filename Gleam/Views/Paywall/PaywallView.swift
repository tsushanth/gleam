import SwiftUI
import StoreKit

struct PaywallView: View {
    var trigger: String = "settings"
    var isOnboarding: Bool = false

    @StateObject private var vm = SubscriptionViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                featuresSection
                pricingSection
                ctaSection
                removeAdsSection
                legalSection
            }
        }
        .scrollIndicators(.hidden)
        // Purchase-state alerts
        .alert("Purchase Pending", isPresented: pendingBinding) {
            Button("OK") { vm.dismissError() }
        } message: {
            Text("Your purchase is awaiting approval. You'll be notified once it's confirmed.")
        }
        .alert("No Connection", isPresented: networkBinding) {
            Button("Try Again") { Task { await vm.purchase() } }
            Button("Cancel", role: .cancel) { vm.dismissError() }
        } message: {
            Text("Check your internet connection and try again.")
        }
        .alert("Purchase Failed", isPresented: errorBinding) {
            Button("OK") { vm.dismissError() }
        } message: {
            Text(vm.errorMessage ?? "Something went wrong. Please try again.")
        }
        .onAppear {
            FirebaseAnalyticsService.shared.log(.paywallViewed(trigger: isOnboarding ? "post_onboarding" : trigger))
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.accent)
                    .padding(.top, isOnboarding ? 24 : 48)

                Text("Gleam Premium")
                    .font(.largeTitle.bold())

                Text("The cleanest home you've ever had.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)

            // Always show a close / skip button
            Button {
                dismiss()
            } label: {
                Image(systemName: isOnboarding ? "xmark" : "xmark.circle.fill")
                    .font(isOnboarding ? .body.weight(.semibold) : .title2)
                    .foregroundStyle(isOnboarding ? Color(.label) : Color(.tertiaryLabel))
                    .padding(16)
            }
            .accessibilityLabel(isOnboarding ? "Skip paywall" : "Close")
        }
    }

    // MARK: - Feature Highlights

    private struct FeatureHighlight: Identifiable {
        let id = UUID()
        let icon: String
        let color: Color
        let title: String
        let subtitle: String
    }

    private let highlights: [FeatureHighlight] = [
        FeatureHighlight(icon: "infinity",           color: .blue,   title: "Unlimited AI Routines",   subtitle: "Generate smart cleaning plans anytime"),
        FeatureHighlight(icon: "person.2.fill",      color: .purple, title: "Multi-User Household",    subtitle: "Invite family members, share the load"),
        FeatureHighlight(icon: "trophy.fill",        color: .yellow, title: "Household Leaderboard",   subtitle: "Friendly competition keeps everyone on track"),
        FeatureHighlight(icon: "bell.badge.fill",    color: .red,    title: "Per-Task Notifications",  subtitle: "Reminders exactly when a room needs attention"),
        FeatureHighlight(icon: "chart.bar.fill",     color: .green,  title: "Advanced Analytics",      subtitle: "Streaks, trends, and room health heatmaps"),
        FeatureHighlight(icon: "iphone",             color: .mint,   title: "iOS Widgets",             subtitle: "Quick glance at your home health from the home screen"),
    ]

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What you get")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                ForEach(highlights) { highlight in
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(highlight.color.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: highlight.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(highlight.color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(highlight.title)
                                .font(.subheadline.weight(.semibold))
                            Text(highlight.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.accent)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)

                    if highlight.id != highlights.last?.id {
                        Divider()
                            .padding(.leading, 78)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Pricing Tiers

    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a plan")
                .font(.headline)
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(SubscriptionProduct.subscriptionCases) { product in
                    SubscriptionOptionView(
                        product: product,
                        liveProduct: vm.storeKitProduct(for: product),
                        isSelected: vm.selectedProduct == product,
                        onTap: {
                            vm.selectedProduct = product
                            HapticService.shared.trigger(.selection)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 8) {
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
                .padding(.vertical, 16)
                .background(Color.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 16)
            .disabled(vm.isPurchasing || vm.isRestoring)
            .accessibilityLabel(vm.ctaTitle)

            if !vm.selectedProduct.isOneTime {
                Text("7-day free trial · Cancel anytime")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Pending state banner
            if vm.purchaseState == .pending {
                HStack(spacing: 8) {
                    Image(systemName: "clock.badge.fill")
                        .foregroundStyle(Color.gleamOrange)
                    Text("Purchase pending approval")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.gleamOrange)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Remove Ads IAP

    private var removeAdsSection: some View {
        VStack(spacing: 10) {
            HStack {
                Rectangle()
                    .fill(Color(.systemFill))
                    .frame(height: 1)
                Text("or")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
                Rectangle()
                    .fill(Color(.systemFill))
                    .frame(height: 1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            SubscriptionOptionView(
                product: .removeAds,
                liveProduct: vm.storeKitProduct(for: .removeAds),
                isSelected: vm.selectedProduct == .removeAds,
                onTap: {
                    vm.selectedProduct = .removeAds
                    HapticService.shared.trigger(.selection)
                }
            )
            .padding(.horizontal, 16)

            Text("One-time purchase · No subscription")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 16)
    }

    // MARK: - Legal Footer

    private var legalSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await vm.restorePurchases() }
            } label: {
                Group {
                    if vm.isRestoring {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    } else {
                        Text("Restore Purchases")
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .disabled(vm.isRestoring || vm.isPurchasing)
            .accessibilityLabel("Restore previous purchases")

            HStack(spacing: 16) {
                Button("Privacy Policy") {
                    if let url = URL(string: "https://appfactory.com/gleam/privacy") {
                        UIApplication.shared.open(url)
                    }
                }
                Text("·")
                Button("Terms of Use") {
                    if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)

            Text("Subscriptions auto-renew unless cancelled at least 24 hours before the current period ends. Manage or cancel any time in App Store settings.")
                .font(.caption2)
                .foregroundStyle(Color(.quaternaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
        .padding(.top, 8)
    }

    // MARK: - Alert Bindings

    private var pendingBinding: Binding<Bool> {
        Binding(
            get: { vm.purchaseState == .pending },
            set: { if !$0 { vm.dismissError() } }
        )
    }

    private var networkBinding: Binding<Bool> {
        Binding(
            get: { vm.purchaseState == .noNetwork },
            set: { if !$0 { vm.dismissError() } }
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.dismissError() } }
        )
    }
}

