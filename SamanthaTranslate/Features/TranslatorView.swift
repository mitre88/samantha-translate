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
            VStack(spacing: AppSpacing.xl) {
                Spacer()

                VoiceOrb(isListening: translationSession.state == .listening)

                VStack(spacing: AppSpacing.xs) {
                    Text(stateText)
                        .font(.title2.bold())
                    Text("translator.subtitle")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: AppSpacing.md) {
                    Picker("settings.output_language", selection: $outputLanguageRaw) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

                    if !translationSession.lastTranslation.isEmpty {
                        Text(translationSession.lastTranslation)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                    }
                }

                Spacer()

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
                }
            }
            .padding(AppSpacing.lg)
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

