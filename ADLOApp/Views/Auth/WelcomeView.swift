import SwiftUI

/// The first screen a signed-out user sees — choosing the "current client" vs.
/// "new client" track up front, rather than burying that choice under a link
/// on the login form. Existing clients go straight to sign-in; new/potential
/// clients land on `NewClientView`, which leads with scheduling a
/// consultation.
struct WelcomeView: View {
    @State private var isShowingLogin = false
    @State private var isShowingNewClient = false
    @State private var isShowingEmailChooser = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 6) {
                    Image("FirmLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                    Text(FirmContact.firmName)
                        .font(.title2.weight(.bold))
                    Text("Client Portal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 14) {
                    Button {
                        isShowingLogin = true
                    } label: {
                        Text("Current Client")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.navy)

                    Button {
                        isShowingNewClient = true
                    } label: {
                        Text("New / Potential Client")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.accent)
                }
                .padding(.horizontal, 32)

                // For anyone who'd rather email than log in or schedule —
                // asks current-vs-potential first since that decides which
                // inbox (clients@ vs. intake@) actually gets it.
                Button {
                    isShowingEmailChooser = true
                } label: {
                    Label("Email Us", systemImage: "envelope")
                        .font(.subheadline.weight(.semibold))
                }
                .tint(Theme.gray3)

                Spacer()
                Spacer()
            }
            .background(Theme.background)
        }
        .sheet(isPresented: $isShowingLogin) {
            LoginView()
        }
        .sheet(isPresented: $isShowingNewClient) {
            NewClientView()
        }
        .confirmationDialog("Are you a current client or a new/potential client?", isPresented: $isShowingEmailChooser, titleVisibility: .visible) {
            Button("Current Client") { emailUs(as: .client) }
            Button("New / Potential Client") { emailUs(as: .prospect) }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func emailUs(as accountType: AccountType) {
        guard let url = URL(string: "mailto:\(FirmContact.contactEmail(for: accountType))") else { return }
        openURL(url)
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthSession())
}
