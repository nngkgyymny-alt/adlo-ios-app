import SwiftUI

@main
struct ADLOApp: App {
    @StateObject private var authSession = AuthSession()
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootContentView()
                .environmentObject(authSession)
                .environmentObject(appState)
                .tint(Theme.accent)
                .task { await authSession.restoreSession() }
        }
    }
}
