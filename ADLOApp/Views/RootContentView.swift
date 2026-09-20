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
                WelcomeView()
            case .signedIn(let user):
                switch user.accountType {
                case .client:
                    RootTabView()
                        .task(id: user.id) {
                            appState.configure(for: user)
                            await appState.loadCaseData()
                        }
                case .prospect:
                    ProspectTabView()
                        .task(id: user.id) {
                            appState.configure(for: user)
                        }
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
