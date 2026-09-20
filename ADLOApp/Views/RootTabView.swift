import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            CaseStatusView()
                .tabItem { Label("Case Status", systemImage: "checklist") }

            DocumentsView()
                .tabItem { Label("Documents", systemImage: "doc.text.fill") }

            ContactView()
                .tabItem { Label("Contact", systemImage: "phone.fill") }

            SettingsView()
                .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppState())
}
