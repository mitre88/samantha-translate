import SwiftUI

@main
struct SamanthaTranslateApp: App {
    @StateObject private var entitlementStore = EntitlementStore()
    @StateObject private var translationSession = TranslationSession()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(entitlementStore)
                .environmentObject(translationSession)
                .task {
                    await entitlementStore.refresh()
                    await translationSession.configure(entitlementProvider: entitlementStore)
                }
        }
    }
}

