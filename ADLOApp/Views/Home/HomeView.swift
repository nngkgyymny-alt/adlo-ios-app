import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            LoadStateView(loadState: appState.loadState, retry: appState.loadCaseData) {
                if let caseFile = appState.caseFile {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            header

                            SectionCard(title: "Your Case") {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(caseFile.caseType)
                                        .font(.subheadline.weight(.semibold))
                                    Text(caseFile.currentStage)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("Reference: \(caseFile.referenceNumber)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            SectionCard(title: "Outstanding Documents") {
                                HStack {
                                    Image(systemName: appState.outstandingDocumentsCount == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundStyle(appState.outstandingDocumentsCount == 0 ? .green : Theme.warning)
                                    Text(appState.outstandingDocumentsCount == 0
                                         ? "All documents submitted"
                                         : "\(appState.outstandingDocumentsCount) item(s) still needed")
                                        .font(.subheadline)
                                    Spacer()
                                }
                            }

                            SectionCard(title: "Need to reach us?") {
                                VStack(spacing: 10) {
                                    Link(destination: URL(string: "tel:\(FirmContact.phoneNumber)")!) {
                                        Label("Call \(FirmContact.phoneDisplay)", systemImage: "phone.fill")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    Link(destination: URL(string: "https://wa.me/\(FirmContact.whatsappNumber)")!) {
                                        Label("Message us on WhatsApp", systemImage: "message.fill")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .buttonStyle(.plain)
                                .tint(Theme.navy)
                            }
                        }
                        .padding()
                    }
                    .background(Theme.background)
                }
            }
            .navigationTitle("Welcome")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hello, \(appState.clientFirstName) 👋")
                .font(.title2.weight(.bold))
            Text(FirmContact.firmName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
