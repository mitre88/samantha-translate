import SwiftUI

struct OnboardingView: View {
    let onContinue: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageBackground.ignoresSafeArea()

                VStack(spacing: AppSpacing.lg) {
                    Spacer(minLength: AppSpacing.md)
                    HeaderBlock()
                    FeatureList()
                    Spacer(minLength: AppSpacing.md)
                    PrimaryButton(title: "onboarding.continue", systemImage: "arrow.right", action: onContinue)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.lg)
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct HeaderBlock: View {
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            VoiceOrb(isListening: true, size: 112)
                .padding(.bottom, AppSpacing.xs)

            VStack(spacing: AppSpacing.sm) {
                Text("onboarding.title")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)

                Text("onboarding.body")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FeatureList: View {
    var body: some View {
        AppSection {
            FeatureRow(
                icon: "sparkles",
                title: "onboarding.feature.detect",
                detail: "onboarding.feature.detect.body"
            )

            FeatureRow(
                icon: "speaker.wave.2.fill",
                title: "onboarding.feature.speak",
                detail: "onboarding.feature.speak.body"
            )

            FeatureRow(
                icon: "lock.shield.fill",
                title: "onboarding.feature.private",
                detail: "onboarding.feature.private.body"
            )
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .lineSpacing(1.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
