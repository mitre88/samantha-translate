import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var entitlementStore: EntitlementStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    VoiceOrb(isListening: false, size: 96)
                        .padding(.top, AppSpacing.lg)

                    VStack(spacing: AppSpacing.sm) {
                        Text("paywall.title")
                            .font(.title2.bold())
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

                    VStack(spacing: AppSpacing.sm) {
                        PrimaryButton(title: "paywall.start_trial", systemImage: "sparkles") {
                            Task { await entitlementStore.purchaseWeekly() }
                        }
                        SecondaryButton(title: "paywall.restore", systemImage: "arrow.clockwise") {
                            Task { await entitlementStore.restore() }
                        }
                        Text("paywall.disclaimer")
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let error = entitlementStore.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(AppTheme.pageBackground.ignoresSafeArea())
            .navigationTitle("app.name")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await entitlementStore.refresh() }
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
