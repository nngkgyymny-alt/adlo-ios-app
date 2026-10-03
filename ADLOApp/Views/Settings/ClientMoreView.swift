import SwiftUI
import MapKit

/// The client tab bar's "More" tab — combines Contact and Settings into one
/// screen. Adding the Forms tab would otherwise push `RootTabView` from 5
/// tabs to 6, and iOS's `TabView` auto-collapses anything past the 5th tab
/// into a system-generated "More" tab — which would have bundled this
/// screen (itself titled "More") inside that system tab, showing a
/// confusing "More" inside "More" with a duplicated nav bar.
/// `ProspectTabView` doesn't hit this (only 3 tabs), so it still shows
/// `ContactView` and `SettingsView` as separate tabs — this view exists
/// only for the 5-tab client shell.
struct ClientMoreView: View {
    @EnvironmentObject private var authSession: AuthSession
    @EnvironmentObject private var appState: AppState
    @AppStorage("preferredLanguage") private var preferredLanguage = "English"
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @State private var isShowingLogoutConfirmation = false

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 28.0395, longitude: -82.3834),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    private let languages = ["English", "Español", "العربية"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Map(coordinateRegion: $region)
                        .frame(height: 180)
                        .listRowInsets(EdgeInsets())
                }

                Section {
                    Link(destination: URL(string: FirmContact.consultationURL)!) {
                        Label("Book a Consultation", systemImage: "calendar.badge.plus")
                            .font(.subheadline.weight(.semibold))
                    }
                    Link(destination: URL(string: FirmContact.teamURL)!) {
                        Label("Meet the Staff", systemImage: "person.2.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                    Link(destination: URL(string: FirmContact.directionsURL)!) {
                        Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                }

                Section("Get in touch") {
                    Link(destination: URL(string: "tel:\(FirmContact.phoneNumber)")!) {
                        Label(FirmContact.phoneDisplay, systemImage: "phone.fill")
                    }
                    Link(destination: URL(string: "https://wa.me/\(FirmContact.whatsappNumber)")!) {
                        Label("WhatsApp", systemImage: "message.fill")
                    }
                    let email = FirmContact.contactEmail(for: appState.accountType)
                    Link(destination: URL(string: "mailto:\(email)")!) {
                        Label(email, systemImage: "envelope.fill")
                    }
                    Link(destination: URL(string: FirmContact.website)!) {
                        Label("americandreamlawoffice.com", systemImage: "safari.fill")
                    }
                }

                Section("Office") {
                    Text(FirmContact.address)
                    Text(FirmContact.officeHours)
                        .foregroundStyle(.secondary)
                }

                Section("Follow Us") {
                    ForEach(FirmContact.socialLinks) { social in
                        Link(destination: URL(string: social.url)!) {
                            Label(social.name, systemImage: social.systemImage)
                        }
                    }
                }

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
            .navigationTitle("Contact & Settings")
            .confirmationDialog("Log out of your ADLO account?", isPresented: $isShowingLogoutConfirmation, titleVisibility: .visible) {
                Button("Log Out", role: .destructive) { authSession.logout() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

#Preview {
    ClientMoreView()
        .environmentObject(AuthSession())
        .environmentObject(AppState())
}
