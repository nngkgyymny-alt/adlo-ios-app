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

            FormsListView()
                .tabItem { Label("Forms", systemImage: "doc.text.magnifyingglass") }

            // Contact is folded into this tab (not a separate one) — see
            // ClientMoreView's own doc comment for why: a 6th tab would push
            // into iOS's auto-generated "More" overflow tab, which
            // ProspectTabView doesn't hit (only 3 tabs there), so
            // ContactView still exists standalone for that one.
            ClientMoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppState())
        .environmentObject(AuthSession())
}
