import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var entitlementStore: EntitlementStore

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                VoiceOrb(isListening: false, size: 150)
                    .padding(.top, AppSpacing.lg)

                VStack(spacing: AppSpacing.sm) {
                    Text("paywall.title")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text("paywall.subtitle")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    PaywallLine(icon: "checkmark.seal", text: "paywall.line.trial")
                    PaywallLine(icon: "speaker.wave.3", text: "paywall.line.realtime")
                    PaywallLine(icon: "lock", text: "paywall.line.privacy")
                }
                .padding(AppSpacing.lg)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))

                VStack(spacing: AppSpacing.sm) {
                    PrimaryButton(title: "paywall.start_trial", systemImage: "sparkles") {
                        Task { await entitlementStore.purchaseWeekly() }
                    }
                    SecondaryButton(title: "paywall.restore", systemImage: "arrow.clockwise") {
                        Task { await entitlementStore.restore() }
                    }
                    Text("paywall.disclaimer")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if let error = entitlementStore.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(AppSpacing.lg)
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
    }
}

