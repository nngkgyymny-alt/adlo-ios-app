import Foundation

@MainActor
final class AuthSession: ObservableObject {
    enum State: Equatable {
        case checking
        case signedOut
        case signedIn(ClientUser)
    }

    @Published private(set) var state: State = .checking
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    private let client: APIClient
    private var accessToken: String? {
        didSet {
            if let accessToken {
                KeychainStore.save(accessToken, for: Keys.accessToken)
            } else {
                KeychainStore.delete(Keys.accessToken)
            }
        }
    }
    /// Remembered between `requestCode` and `verifyCode` — verify needs the
    /// same email the code was requested for (see `Endpoint.verifyCode`).
    private var pendingEmail: String?

    private enum Keys {
        static let accessToken = "accessToken"
        /// From the old password+refresh-token backend — never read anymore,
        /// just deleted once so it doesn't sit in the Keychain forever on
        /// upgraded installs (the Keychain survives app deletion).
        static let legacyRefreshToken = "refreshToken"
    }

    init(client: APIClient = .shared) {
        self.client = client
        client.accessTokenProvider = { [weak self] in self?.accessToken }
        client.onUnauthorized = { [weak self] in await self?.handleUnauthorized() }
        KeychainStore.delete(Keys.legacyRefreshToken)
    }

    var isSignedIn: Bool {
        if case .signedIn = state { return true }
        return false
    }

    /// Call once at launch: restores a session from the stored bearer token, if any.
    func restoreSession() async {
        guard let storedToken = KeychainStore.read(Keys.accessToken), !storedToken.isEmpty else {
            state = .signedOut
            return
        }
        accessToken = storedToken
        await loadCurrentUser(signOutOnFailure: true)
    }

    /// Step 1: emails a one-time code to this address.
    func requestCode(email: String) async -> Bool {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await client.sendVoid(.requestCode(email: email))
            pendingEmail = email
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Step 2: exchanges the emailed code for a session.
    func verifyCode(_ code: String) async {
        guard let email = pendingEmail else {
            errorMessage = "Enter your email again to request a new code."
            return
        }

        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let response: VerifyCodeResponse = try await client.send(.verifyCode(email: email, code: code))
            accessToken = response.accessToken
            // The token we just got is fresh and valid — a failure loading
            // the profile right now is almost certainly transient (network,
            // a momentary 5xx), not an invalid session. Don't sign out and
            // silently drop back to the code screen with no explanation;
            // keep the token (it's still good for restoreSession next
            // launch) and surface a clear, retryable error instead.
            await loadCurrentUser(signOutOnFailure: false)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        // No server-side session to revoke — the bearer token is a stateless
        // JWT (see adlo-portal's lib/mobile-auth.ts) — so this is local-only.
        accessToken = nil
        pendingEmail = nil
        state = .signedOut
    }

    private func handleUnauthorized() async {
        accessToken = nil
        state = .signedOut
    }

    private func loadCurrentUser(signOutOnFailure: Bool) async {
        do {
            let user: ClientUser = try await client.send(.currentUser())
            pendingEmail = nil
            state = .signedIn(user)
        } catch {
            if signOutOnFailure {
                accessToken = nil
                state = .signedOut
            } else {
                errorMessage = "Signed in, but couldn't load your account: \(error.localizedDescription)"
            }
        }
    }
}
