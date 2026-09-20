import SwiftUI
import MapKit

struct ContactView: View {
    @EnvironmentObject private var appState: AppState

    // Matches adlo-case-estimator's LegalService structured data (the real
    // office address's verified coordinates), not the old placeholder address.
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 28.0395, longitude: -82.3834),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    var body: some View {
        NavigationStack {
            List {
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
            }
            .navigationTitle("Contact Us")
        }
    }
}

#Preview {
    ContactView()
        .environmentObject(AppState())
}
