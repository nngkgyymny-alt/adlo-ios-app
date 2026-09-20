import SwiftUI

/// Tab shell for `AccountType.prospect` accounts — no case/document tabs
/// since no case exists yet. See `RootTabView` for retained clients.
struct ProspectTabView: View {
    var body: some View {
        TabView {
            ProspectStatusView()
                .tabItem { Label("Status", systemImage: "house.fill") }

            ContactView()
                .tabItem { Label("Contact", systemImage: "phone.fill") }

            SettingsView()
                .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
        }
    }
}

#Preview {
    ProspectTabView()
        .environmentObject(AppState())
        .environmentObject(AuthSession())
}
