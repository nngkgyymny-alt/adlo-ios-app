import Foundation

struct RequestCodeRequest: Encodable {
    let email: String
}

struct VerifyCodeRequest: Encodable {
    let code: String
}

struct VerifyCodeResponse: Decodable {
    let accessToken: String
    let email: String
}

enum AccountType: String, Decodable {
    case client
    case prospect
}

/// No `id` field — the backend has no separate account-record primary key;
/// email is the identity everywhere (matches adlo-portal's magic-link model).
struct ClientUser: Decodable, Equatable {
    let email: String
    let firstName: String
    let lastName: String
    let accountType: AccountType
}
