import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var entitlementStore: EntitlementStore
    @AppStorage("outputLanguage") private var outputLanguageRaw = AppLanguage.english.rawValue

    var body: some View {
        Form {
            Section {
                Picker("settings.output_language", selection: $outputLanguageRaw) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language.rawValue)
                    }
                }
            }

            Section("settings.subscription") {
                Button("paywall.restore") {
                    Task { await entitlementStore.restore() }
                }
                Text("settings.subscription.note")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("settings.privacy") {
                Text("settings.privacy.note")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Link("settings.privacy.link", destination: URL(string: "https://samantha-translate-mitre88.vercel.app/#privacy")!)
                Link("settings.support.link", destination: URL(string: "https://samantha-translate-mitre88.vercel.app/#support")!)
            }
        }
        .navigationTitle("settings.title")
    }
}
