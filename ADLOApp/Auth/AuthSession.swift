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
    private var accessToken: String?
    private var refreshToken: String? {
        didSet {
            if let refreshToken {
                KeychainStore.save(refreshToken, for: Keys.refreshToken)
            } else {
                KeychainStore.delete(Keys.refreshToken)
            }
        }
    }

    private enum Keys {
        static let refreshToken = "refreshToken"
    }

    init(client: APIClient = .shared) {
        self.client = client
        client.accessTokenProvider = { [weak self] in self?.accessToken }
        client.onUnauthorized = { [weak self] in
            await self?.refreshSession()
        }
    }

    var isSignedIn: Bool {
        if case .signedIn = state { return true }
        return false
    }

    /// Call once at launch: attempts to restore a session from the stored refresh token.
    func restoreSession() async {
        guard let storedRefreshToken = KeychainStore.read(Keys.refreshToken), !storedRefreshToken.isEmpty else {
            state = .signedOut
            return
        }
        refreshToken = storedRefreshToken
        if let newAccessToken = await refreshSession() {
            accessToken = newAccessToken
            await loadCurrentUser()
        } else {
            state = .signedOut
        }
    }

    func login(email: String, password: String) async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let response: LoginResponse = try await client.send(.login(email: email, password: password))
            accessToken = response.accessToken
            refreshToken = response.refreshToken
            state = .signedIn(response.user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func requestPasswordReset(email: String) async -> Bool {
        do {
            try await client.sendVoid(.requestPasswordReset(email: email))
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func logout() {
        Task { try? await client.sendVoid(.logout()) }
        accessToken = nil
        refreshToken = nil
        state = .signedOut
    }

    /// Attempts to exchange the stored refresh token for a new access token.
    /// Returns the new access token on success, or `nil` if the refresh token is invalid/expired.
    @discardableResult
    private func refreshSession() async -> String? {
        guard let refreshToken else { return nil }
        do {
            let tokens: AuthTokens = try await client.send(.refreshToken(refreshToken))
            self.accessToken = tokens.accessToken
            self.refreshToken = tokens.refreshToken
            return tokens.accessToken
        } catch {
            self.refreshToken = nil
            self.accessToken = nil
            state = .signedOut
            return nil
        }
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
