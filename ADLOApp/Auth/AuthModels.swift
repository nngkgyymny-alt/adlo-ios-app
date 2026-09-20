import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RefreshRequest: Encodable {
    let refreshToken: String
}

struct PasswordResetRequest: Encodable {
    let email: String
}

struct AuthTokens: Decodable {
    let accessToken: String
    let refreshToken: String
}

struct LoginResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let user: ClientUser
}

struct ClientUser: Decodable, Equatable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
}
