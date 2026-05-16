import SwiftUI

struct TranslatorView: View {
    @EnvironmentObject private var translationSession: TranslationSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("outputLanguage") private var outputLanguageRaw = AppLanguage.english.rawValue
    let outputLanguage: AppLanguage

    private let transcriptBottomID = "transcript-bottom"

    private var stateText: LocalizedStringKey {
        switch translationSession.state {
        case .idle: "translator.state.idle"
        case .preparing: "translator.state.preparing"
        case .listening: "translator.state.listening"
        case .error: "translator.state.error"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageBackground.ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: AppSpacing.lg) {
                            VStack(spacing: AppSpacing.md) {
                                statusPill

                                VoiceOrb(isListening: translationSession.state == .listening, size: 116)
                                    .padding(.top, AppSpacing.xs)
                            }
                            .padding(.top, AppSpacing.md)

                            statusBlock
                            languagePicker
                            transcriptPanel

                            Color.clear
                                .frame(height: 1)
                                .id(transcriptBottomID)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.xl)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .onChange(of: translationSession.lastTranscript) { _, _ in
                        scrollToLatest(using: proxy)
                    }
                    .onChange(of: translationSession.lastTranslation) { _, _ in
                        scrollToLatest(using: proxy)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("app.name")
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(Text("settings.title"))
                }
            }
            .onChange(of: outputLanguageRaw) { _, newValue in
                guard let language = AppLanguage(rawValue: newValue) else { return }
                translationSession.updateOutputLanguage(language)
            }
            .safeAreaInset(edge: .bottom) {
                bottomControls
            }
        }
    }

    private var statusBlock: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(stateText)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Text("translator.subtitle")
                .font(.footnote)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private var statusPill: some View {
        Label(statusLabel, systemImage: statusSymbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(statusForeground)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(statusBackground, in: Capsule(style: .continuous))
            .accessibilityHidden(true)
    }

    private var statusLabel: LocalizedStringKey {
        switch translationSession.state {
        case .idle: "translator.status.ready"
        case .preparing: "translator.status.secure"
        case .listening: "translator.status.live"
        case .error: "translator.status.error"
        }
    }

    private var statusSymbol: String {
        switch translationSession.state {
        case .idle: "checkmark.circle.fill"
        case .preparing: "lock.fill"
        case .listening: "waveform"
        case .error: "exclamationmark.triangle.fill"
        }
    }

    private var statusForeground: Color {
        switch translationSession.state {
        case .listening: return .black
        case .error: return .red
        default: return .primary
        }
    }

    private var statusBackground: Color {
        switch translationSession.state {
        case .listening: return AppTheme.successTint
        case .error: return Color.red.opacity(0.12)
        default: return AppTheme.elevatedSurface
        }
    }

    private var languagePicker: some View {
        AppSection {
            HStack(spacing: AppSpacing.md) {
                Label("settings.output_language", systemImage: "globe")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: AppSpacing.sm)

                Picker("settings.output_language", selection: $outputLanguageRaw) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
    }

    private var transcriptPanel: some View {
        AppSection {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    Text("translator.transcript.title")
                        .font(.headline)

                    Spacer()

                    Text(translationSession.lastTranslation.isEmpty ? "translator.transcript.waiting" : "translator.transcript.live")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                }

                if translationSession.lastTranscript.isEmpty && translationSession.lastTranslation.isEmpty {
                    Text("translator.transcript.empty")
                        .font(.callout)
                        .foregroundStyle(AppTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, AppSpacing.xs)
                } else {
                    if !translationSession.lastTranscript.isEmpty {
                        TranscriptBlock(
                            title: "translator.transcript.source",
                            text: translationSession.lastTranscript,
                            isPrimary: false
                        )
                    }

                    if !translationSession.lastTranslation.isEmpty {
                        TranscriptBlock(
                            title: "translator.transcript.translation",
                            text: translationSession.lastTranslation,
                            isPrimary: true
                        )
                    }
                }
            }
        }
        .textSelection(.enabled)
    }

    private var bottomControls: some View {
        VStack(spacing: AppSpacing.sm) {
            switch translationSession.state {
            case .listening, .preparing:
                SecondaryButton(title: "translator.stop", systemImage: "stop.fill") {
                    translationSession.stop()
                }
            default:
                DarkPrimaryButton(title: "translator.start", systemImage: "mic.fill") {
                    Task {
                        let selected = AppLanguage(rawValue: outputLanguageRaw) ?? .english
                        await translationSession.start(outputLanguage: selected)
                    }
                }
            }

            if case .error(let message) = translationSession.state {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(AppSpacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.sm)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }

    private func scrollToLatest(using proxy: ScrollViewProxy) {
        guard !translationSession.lastTranscript.isEmpty || !translationSession.lastTranslation.isEmpty else { return }
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.25)) {
            proxy.scrollTo(transcriptBottomID, anchor: .bottom)
        }
    }
}

private struct TranscriptBlock: View {
    let title: LocalizedStringKey
    let text: String
    let isPrimary: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
                .textCase(.uppercase)

            Text(text)
                .font(isPrimary ? .body.weight(.medium) : .callout)
                .foregroundStyle(isPrimary ? .primary : AppTheme.muted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .fill(isPrimary ? AppTheme.successTint.opacity(0.18) : AppTheme.elevatedSurface)
        )
    }
}
