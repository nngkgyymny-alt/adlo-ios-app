import SwiftUI

@main
struct ADLOApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appState)
                .tint(Theme.accent)
        }
    }
}
