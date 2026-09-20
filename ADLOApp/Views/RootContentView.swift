import SwiftUI

struct RootContentView: View {
    @EnvironmentObject private var authSession: AuthSession
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            switch authSession.state {
            case .checking:
                ProgressView()
            case .signedOut:
                LoginView()
            case .signedIn(let user):
                RootTabView()
                    .task(id: user.id) {
                        appState.configure(for: user)
                        await appState.loadCaseData()
                    }
            }
        }
    }
}

#Preview {
    RootContentView()
        .environmentObject(AuthSession())
        .environmentObject(AppState())
}
