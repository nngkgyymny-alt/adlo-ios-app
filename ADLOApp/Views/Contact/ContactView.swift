import SwiftUI
import MapKit

struct ContactView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 27.9506, longitude: -82.4572),
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

                Section("Get in touch") {
                    Link(destination: URL(string: "tel:\(FirmContact.phoneNumber)")!) {
                        Label(FirmContact.phoneDisplay, systemImage: "phone.fill")
                    }
                    Link(destination: URL(string: "https://wa.me/\(FirmContact.whatsappNumber)")!) {
                        Label("WhatsApp", systemImage: "message.fill")
                    }
                    Link(destination: URL(string: "mailto:\(FirmContact.email)")!) {
                        Label(FirmContact.email, systemImage: "envelope.fill")
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
            }
            .navigationTitle("Contact Us")
        }
    }
}

#Preview {
    ContactView()
}
