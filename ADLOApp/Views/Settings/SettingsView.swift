import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authSession: AuthSession
    @AppStorage("preferredLanguage") private var preferredLanguage = "English"
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @State private var isShowingLogoutConfirmation = false

    private let languages = ["English", "Español", "العربية"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Picker("Language", selection: $preferredLanguage) {
                        ForEach(languages, id: \.self) { Text($0) }
                    }
                    Toggle("Case update notifications", isOn: $notificationsEnabled)
                }

                Section("About") {
                    LabeledContent("App Version", value: "1.0.0")
                    Link("Privacy Policy", destination: URL(string: "\(FirmContact.website)/privacy-policy")!)
                    Link("Terms of Service", destination: URL(string: "\(FirmContact.website)/terms")!)
                }

                Section {
                    Button("Log Out", role: .destructive) {
                        isShowingLogoutConfirmation = true
                    }
                }
            }
            .navigationTitle("More")
            .confirmationDialog("Log out of your ADLO account?", isPresented: $isShowingLogoutConfirmation, titleVisibility: .visible) {
                Button("Log Out", role: .destructive) { authSession.logout() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthSession())
}
