import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            AppTheme.pageBackground
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.md) {
                VoiceOrb(isListening: true, size: 118)
                VStack(spacing: AppSpacing.xxs) {
                    Text("app.name")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("app.tagline")
                        .font(.callout)
                        .foregroundStyle(AppTheme.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(AppSpacing.xl)
        }
    }
}

struct VoiceOrb: View {
    let isListening: Bool
    var size: CGFloat = 156
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let orbFill = Color.white
    private let orbMark = Color.black.opacity(0.86)
    private let orbInnerRing = Color.black.opacity(0.12)

    var body: some View {
        ZStack {
            Circle()
                .fill(orbFill)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.08), radius: 24, y: 14)
                .shadow(color: .cyan.opacity(isListening ? 0.22 : 0.08), radius: isListening ? 34 : 18)

            Circle()
                .strokeBorder(orbInnerRing, lineWidth: 1)
                .frame(width: size * 0.82, height: size * 0.82)

            Circle()
                .strokeBorder(.cyan.opacity(isListening ? 0.34 : 0.14), lineWidth: 2)
                .frame(width: size * 0.98, height: size * 0.98)
                .scaleEffect(isListening && !reduceMotion ? 1.08 : 1)
                .opacity(isListening ? 0.7 : 0.35)

            Image(systemName: "waveform")
                .font(.system(size: size * 0.24, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(orbMark)
        }
        .scaleEffect(isListening && !reduceMotion ? 1.03 : 1)
        .animation(reduceMotion ? nil : .smooth(duration: 1.2).repeatForever(autoreverses: true), value: isListening)
        .accessibilityLabel(Text("accessibility.voice_orb"))
    }
}
