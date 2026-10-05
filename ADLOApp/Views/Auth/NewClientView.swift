import SwiftUI

/// The "new / potential client" track from `WelcomeView`. Leads with
/// scheduling a consultation — the primary action for someone without an
/// existing relationship with the firm — and offers sign-in as a secondary
/// option for tracking an inquiry already in progress (sign-in doubles as
/// account creation: the same emailed-code flow works whether or not we've
/// seen this email before — see `AuthSession`).
struct NewClientView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var isShowingLogin = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.navy)
                        Text("New to \(FirmContact.firmName)?")
                            .font(.title3.weight(.bold))
                            .multilineTextAlignment(.center)
                        Text("The fastest way to get started is scheduling a consultation with an attorney.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)

                    Button {
                        if let url = URL(string: FirmContact.consultationURL) {
                            openURL(url)
                        }
                    } label: {
                        Text("Schedule a Consultation")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)

                    Divider()
                        .padding(.vertical, 4)

                    VStack(spacing: 10) {
                        Text("Already started an inquiry?")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Sign In") {
                            isShowingLogin = true
                        }
                        .buttonStyle(.bordered)
                        .tint(Theme.navy)
                    }
                }
                .padding(.horizontal, 24)
            }
            .background(Theme.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $isShowingLogin) {
            LoginView()
        }
    }
}

#Preview {
    NewClientView()
        .environmentObject(AuthSession())
}
