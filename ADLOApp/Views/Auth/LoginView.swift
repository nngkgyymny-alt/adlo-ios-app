import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authSession: AuthSession
    @State private var email = ""
    @State private var password = ""
    @State private var isShowingForgotPassword = false
    @State private var isShowingSignUp = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password
    }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty && !authSession.isSubmitting
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.navy)
                        Text(FirmContact.firmName)
                            .font(.title3.weight(.bold))
                        Text("Client Portal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 32)

                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                            .textFieldStyle(.roundedBorder)

                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit { submit() }
                            .textFieldStyle(.roundedBorder)
                    }

                    if let errorMessage = authSession.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: submit) {
                        if authSession.isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.navy)
                    .disabled(!canSubmit)

                    Button("Forgot password?") {
                        isShowingForgotPassword = true
                    }
                    .font(.footnote)

                    Divider()
                        .padding(.vertical, 4)

                    VStack(spacing: 10) {
                        Text("Just getting a fee estimate or exploring your options?")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Create a Free Account") {
                            isShowingSignUp = true
                        }
                        .buttonStyle(.bordered)
                        .tint(Theme.navy)

                        Text("Already a client but don't have portal access? Contact our office.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)
            }
            .sheet(isPresented: $isShowingForgotPassword) {
                ForgotPasswordView()
            }
            .sheet(isPresented: $isShowingSignUp) {
                SignUpView()
            }
        }
    }

    private func submit() {
        guard canSubmit else { return }
        focusedField = nil
        Task { await authSession.login(email: email, password: password) }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthSession())
}
