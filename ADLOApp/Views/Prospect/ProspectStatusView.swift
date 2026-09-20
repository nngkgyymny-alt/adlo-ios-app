import SwiftUI

struct ProspectStatusView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openURL) private var openURL

    private enum LoadState {
        case loading
        case loaded(InquiryStatus)
        case failed(String)
    }

    @State private var loadState: LoadState = .loading
    private let service = ProspectService()

    var body: some View {
        NavigationStack {
            Group {
                switch loadState {
                case .loading:
                    ProgressView("Loading your status…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failed(let message):
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text(message)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Button("Try Again") { Task { await load() } }
                            .buttonStyle(.bordered)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loaded(let inquiry):
                    content(for: inquiry)
                }
            }
            .background(Theme.background)
            .navigationTitle("Your Inquiry")
        }
        .task { await load() }
    }

    private func content(for inquiry: InquiryStatus) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello, \(appState.clientFirstName) 👋")
                        .font(.title2.weight(.bold))
                    Text(FirmContact.firmName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                SectionCard(title: "Inquiry Status") {
                    Text(inquiry.status)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.navy)
                }

                if inquiry.hasLawmaticsContact {
                    SectionCard(title: "Your Case Details") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(inquiry.caseType ?? "On file with our office")
                                .font(.subheadline.weight(.semibold))
                            if let summary = inquiry.summary {
                                Text(summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    SectionCard(title: "We Haven't Heard From You Yet") {
                        Text("Book a consultation below and we'll get your case details on file.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                SectionCard(title: "Ready to Talk to an Attorney?") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Book a consultation to discuss your case and next steps.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button {
                            if let url = URL(string: FirmContact.consultationURL) {
                                openURL(url)
                            }
                        } label: {
                            Text("Book a Consultation")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.gold)
                    }
                }

                SectionCard(title: "Check a Case Status") {
                    NavigationLink("Check USCIS / EOIR Status") {
                        CaseStatusLookupView()
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
            .padding()
        }
    }

    private func load() async {
        loadState = .loading
        do {
            let inquiry = try await service.fetchInquiry()
            loadState = .loaded(inquiry)
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }
}

#Preview {
    ProspectStatusView()
        .environmentObject(AppState())
}
