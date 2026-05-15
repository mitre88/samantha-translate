import StoreKit
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var entitlementStore: EntitlementStore

    var body: some View {
        NavigationStack {
            SubscriptionStoreView(productIDs: [EntitlementStore.weeklyProductID]) {
                PaywallHeader()
            }
            .subscriptionStoreControlStyle(.buttons)
            .subscriptionStoreButtonLabel(.multiline)
            .storeButton(.visible, for: .restorePurchases)
            .background(AppTheme.pageBackground.ignoresSafeArea())
            .navigationTitle("app.name")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await entitlementStore.refresh() }
    }
}

private struct PaywallHeader: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            VoiceOrb(isListening: false, size: 108)
                .padding(.top, AppSpacing.lg)

            VStack(spacing: AppSpacing.sm) {
                Text("paywall.title")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)

                Text("paywall.subtitle")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            AppSection {
                PaywallLine(icon: "checkmark.seal.fill", text: "paywall.line.trial")
                PaywallLine(icon: "speaker.wave.3.fill", text: "paywall.line.realtime")
                PaywallLine(icon: "lock.fill", text: "paywall.line.privacy")
            }

            Text("paywall.disclaimer")
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.md)
    }
}

struct PaywallLine: View {
    let icon: String
    let text: LocalizedStringKey

    var body: some View {
        Label(text, systemImage: icon)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
