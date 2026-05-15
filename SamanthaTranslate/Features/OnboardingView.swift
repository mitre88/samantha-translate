import SwiftUI

struct OnboardingView: View {
    let onContinue: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                VoiceOrb(isListening: true)

                VStack(spacing: AppSpacing.sm) {
                    Text("onboarding.title")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text("onboarding.body")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    FeatureRow(icon: "sparkles", title: "onboarding.feature.detect", detail: "onboarding.feature.detect.body")
                    FeatureRow(icon: "speaker.wave.2", title: "onboarding.feature.speak", detail: "onboarding.feature.speak.body")
                    FeatureRow(icon: "lock.shield", title: "onboarding.feature.private", detail: "onboarding.feature.private.body")
                }

                Spacer()
                PrimaryButton(title: "onboarding.continue", systemImage: "arrow.right", action: onContinue)
            }
            .padding(AppSpacing.lg)
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
