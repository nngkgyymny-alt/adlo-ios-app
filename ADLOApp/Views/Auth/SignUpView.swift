import SwiftUI

/// Self-signup for prospects (potential clients) — see `AccountType.prospect`.
/// Existing/retained clients don't use this; their accounts are staff-provisioned.
struct SignUpView: View {
    @EnvironmentObject private var authSession: AuthSession
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case firstName, lastName, email, password
    }

    private var canSubmit: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !lastName.trimmingCharacters(in: .whitespaces).isEmpty
            && !email.trimmingCharacters(in: .whitespaces).isEmpty
            && password.count >= 8
            && !authSession.isSubmitting
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Track your fee estimate and hear back from our office — no case yet, just your inquiry.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Your Information") {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                        .focused($focusedField, equals: .firstName)
                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                        .focused($focusedField, equals: .lastName)
                    TextField("Email", text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                    SecureField("Password (min. 8 characters)", text: $password)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .password)
                }

                if let errorMessage = authSession.errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        submit()
                    } label: {
                        if authSession.isSubmitting {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text("Create Account").frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!canSubmit)
                }
            }
            .navigationTitle("Create Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func submit() {
        guard canSubmit else { return }
        focusedField = nil
        Task { await authSession.signup(email: email, password: password, firstName: firstName, lastName: lastName) }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthSession())
}
