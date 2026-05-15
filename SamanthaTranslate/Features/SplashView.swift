import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                VoiceOrb(isListening: true, size: 132)
                VStack(spacing: AppSpacing.xs) {
                    Text("app.name")
                        .font(.largeTitle.bold())
                    Text("app.tagline")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(AppSpacing.xl)
        }
    }
}

struct VoiceOrb: View {
    let isListening: Bool
    var size: CGFloat = 220

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: size, height: size)
                .shadow(color: .cyan.opacity(0.18), radius: 28, y: 14)

            Circle()
                .strokeBorder(.white.opacity(0.7), lineWidth: 1)
                .frame(width: size * 0.86, height: size * 0.86)

            Image(systemName: "waveform")
                .font(.system(size: size * 0.24, weight: .semibold))
                .foregroundStyle(.primary)
                .symbolEffect(.variableColor.iterative, isActive: isListening)
        }
        .scaleEffect(isListening ? 1.04 : 1)
        .animation(.smooth(duration: 1.1).repeatForever(autoreverses: true), value: isListening)
        .accessibilityLabel(Text("accessibility.voice_orb"))
    }
}

