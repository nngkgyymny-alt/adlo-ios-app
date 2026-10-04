import SwiftUI

/// Sign-in with a one-time emailed code — no passwords, no separate signup.
/// First-time and returning users go through the exact same two steps;
/// the backend only learns which bucket (client/prospect) an email falls
/// into from whether it's ever synced to Lawmatics (see adlo-portal's
/// lib/portal-accounts.ts), not from a distinct "create account" step.
struct LoginView: View {
    @EnvironmentObject private var authSession: AuthSession
    @Environment(\.dismiss) private var dismiss

    private enum Step {
        case email
        case code
    }

    @State private var step: Step = .email
    @State private var email = ""
    @State private var code = ""
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Image("FirmLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                        Text(FirmContact.firmName)
                            .font(.title3.weight(.bold))
                        Text("Client Portal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 32)

                    switch step {
                    case .email:
                        emailStep
                    case .code:
                        codeStep
                    }

                    if let errorMessage = authSession.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var emailStep: some View {
        VStack(spacing: 16) {
            Text("Enter your email and we'll send you a one-time sign-in code.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("Email", text: $email)
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFieldFocused)
                .submitLabel(.go)
                .onSubmit { Task { await sendCode() } }
                .textFieldStyle(.roundedBorder)

            Button(action: { Task { await sendCode() } }) {
                if authSession.isSubmitting {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Send Code").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.navy)
            .disabled(!canSendCode)
        }
        .onAppear { isFieldFocused = true }
    }

    private var codeStep: some View {
        VStack(spacing: 16) {
            Text("We sent a code to \(trimmedEmail). Enter it below.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("Code", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFieldFocused)
                .submitLabel(.go)
                .onSubmit { Task { await verifyCode() } }
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .font(.title3.monospacedDigit())

            Button(action: { Task { await verifyCode() } }) {
                if authSession.isSubmitting {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Sign In").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.navy)
            .disabled(!canVerifyCode)

            Button("Use a different email") {
                step = .email
                code = ""
                authSession.errorMessage = nil
            }
            .font(.footnote)
        }
        .onAppear { isFieldFocused = true }
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSendCode: Bool {
        !trimmedEmail.isEmpty && !authSession.isSubmitting
    }

    private var canVerifyCode: Bool {
        !code.trimmingCharacters(in: .whitespaces).isEmpty && !authSession.isSubmitting
    }

    private func sendCode() async {
        guard canSendCode else { return }
        isFieldFocused = false
        guard await authSession.requestCode(email: trimmedEmail) else { return }
        step = .code
    }

    private func verifyCode() async {
        guard canVerifyCode else { return }
        isFieldFocused = false
        await authSession.verifyCode(code.trimmingCharacters(in: .whitespaces))
        if authSession.isSignedIn { dismiss() }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthSession())
}
