import SwiftUI

/// The first screen a signed-out user sees — choosing the "current client" vs.
/// "new client" track up front, rather than burying that choice under a link
/// on the login form. Existing clients go straight to sign-in; new/potential
/// clients land on `NewClientView`, which leads with scheduling a
/// consultation.
struct WelcomeView: View {
    @State private var isShowingLogin = false
    @State private var isShowingNewClient = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 6) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.navy)
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
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthSession())
}
