import SwiftUI

struct TranslatorView: View {
    @EnvironmentObject private var translationSession: TranslationSession
    @AppStorage("outputLanguage") private var outputLanguageRaw = AppLanguage.english.rawValue
    let outputLanguage: AppLanguage

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

                VStack(spacing: AppSpacing.lg) {
                    Spacer(minLength: AppSpacing.lg)

                    VoiceOrb(isListening: translationSession.state == .listening, size: 132)

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

                    AppSection {
                        Picker("settings.output_language", selection: $outputLanguageRaw) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.displayName).tag(language.rawValue)
                            }
                        }
                        .pickerStyle(.menu)

                        if !translationSession.lastTranslation.isEmpty {
                            Divider()
                            Text(translationSession.lastTranslation)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer(minLength: AppSpacing.lg)

                    switch translationSession.state {
                    case .listening, .preparing:
                        SecondaryButton(title: "translator.stop", systemImage: "stop.fill") {
                            translationSession.stop()
                        }
                    default:
                        PrimaryButton(title: "translator.start", systemImage: "mic.fill") {
                            Task {
                                let selected = AppLanguage(rawValue: outputLanguageRaw) ?? .english
                                await translationSession.start(outputLanguage: selected)
                            }
                        }
                    }

                    if case .error(let message) = translationSession.state {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("app.name")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(Text("settings.title"))
                }
            }
        }
    }
}
