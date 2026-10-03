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

    private enum Keys {
        static let accessToken = "accessToken"
    }

    init(client: APIClient = .shared) {
        self.client = client
        client.accessTokenProvider = { [weak self] in self?.accessToken }
        client.onUnauthorized = { [weak self] in await self?.handleUnauthorized() }
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
        await loadCurrentUser()
    }

    /// Step 1: emails a one-time code to this address.
    func requestCode(email: String) async -> Bool {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await client.sendVoid(.requestCode(email: email))
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Step 2: exchanges the emailed code for a session.
    func verifyCode(_ code: String) async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let response: VerifyCodeResponse = try await client.send(.verifyCode(code))
            accessToken = response.accessToken
            await loadCurrentUser()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        // No server-side session to revoke — the bearer token is a stateless
        // JWT (see adlo-portal's lib/mobile-auth.ts) — so this is local-only.
        accessToken = nil
        state = .signedOut
    }

    private func handleUnauthorized() async {
        accessToken = nil
        state = .signedOut
    }

    private func loadCurrentUser() async {
        do {
            let user: ClientUser = try await client.send(.currentUser())
            state = .signedIn(user)
        } catch {
            state = .signedOut
        }
    }
}
