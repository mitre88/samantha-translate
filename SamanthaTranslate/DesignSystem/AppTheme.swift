import SwiftUI

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let ml: CGFloat = 20
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum AppRadius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 18
    static let lg: CGFloat = 28
}

enum AppTheme {
    static let pageBackground = Color(.systemGroupedBackground)
    static let surface = Color(.secondarySystemGroupedBackground)
    static let elevatedSurface = Color(.tertiarySystemGroupedBackground)
    static let muted = Color.secondary
    static let successTint = Color(red: 0.53, green: 0.95, blue: 0.76)
    static let voiceTint = Color(red: 0.42, green: 0.88, blue: 1.0)
    static let panelStroke = Color.primary.opacity(0.08)
    static let quietInk = Color.primary.opacity(0.82)
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case italian = "it"
    case chinese = "zh-Hans"
    case japanese = "ja"

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .english: "language.english"
        case .spanish: "language.spanish"
        case .french: "language.french"
        case .italian: "language.italian"
        case .chinese: "language.chinese"
        case .japanese: "language.japanese"
        }
    }

    var realtimeLabel: String {
        switch self {
        case .english: "English"
        case .spanish: "Spanish"
        case .french: "French"
        case .italian: "Italian"
        case .chinese: "Simplified Chinese"
        case .japanese: "Japanese"
        }
    }

    var realtimeTranslationCode: String {
        switch self {
        case .english: "en"
        case .spanish: "es"
        case .french: "fr"
        case .italian: "it"
        case .chinese: "zh"
        case .japanese: "ja"
        }
    }
}

struct PrimaryButton: View {
    let title: LocalizedStringKey
    var systemImage: String? = nil
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage ?? "arrow.right")
                .font(.body.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .foregroundStyle(Color(white: 0.88))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.black, in: Capsule(style: .continuous))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .modifier(PressFeedbackModifier(disabled: reduceMotion))
        .contentShape(Capsule(style: .continuous))
    }
}

struct DarkPrimaryButton: View {
    let title: LocalizedStringKey
    var systemImage: String? = nil
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage ?? "arrow.right")
                .font(.body.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .foregroundStyle(Color(white: 0.72))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.black, in: Capsule(style: .continuous))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .modifier(PressFeedbackModifier(disabled: reduceMotion))
        .contentShape(Capsule(style: .continuous))
    }
}

struct SecondaryButton: View {
    let title: LocalizedStringKey
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage ?? "arrow.clockwise")
                .font(.body.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .clipShape(Capsule(style: .continuous))
    }
}

struct AppSection<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            content
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(AppTheme.panelStroke, lineWidth: 1)
        )
    }
}

private struct PressFeedbackModifier: ViewModifier {
    let disabled: Bool

    func body(content: Content) -> some View {
        if disabled {
            content
        } else {
            content.buttonStyle(ScaleOnPressButtonStyle())
        }
    }
}

private struct ScaleOnPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.smooth(duration: 0.12), value: configuration.isPressed)
    }
}
