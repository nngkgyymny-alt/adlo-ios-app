import Foundation

struct Endpoint {
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    let path: String
    let method: Method
    var query: [URLQueryItem] = []
    var body: Data? = nil
    /// Most endpoints require the bearer token; auth endpoints (login, refresh) don't.
    var requiresAuth: Bool = true

    static func login(email: String, password: String) -> Endpoint {
        let body = try? JSONEncoder.adlo.encode(LoginRequest(email: email, password: password))
        return Endpoint(path: "/auth/login", method: .post, body: body, requiresAuth: false)
    }

    static func signup(email: String, password: String, firstName: String, lastName: String) -> Endpoint {
        let body = try? JSONEncoder.adlo.encode(SignupRequest(email: email, password: password, firstName: firstName, lastName: lastName))
        return Endpoint(path: "/auth/signup", method: .post, body: body, requiresAuth: false)
    }

    static func refreshToken(_ refreshToken: String) -> Endpoint {
        let body = try? JSONEncoder.adlo.encode(RefreshRequest(refreshToken: refreshToken))
        return Endpoint(path: "/auth/refresh", method: .post, body: body, requiresAuth: false)
    }

    static func requestPasswordReset(email: String) -> Endpoint {
        let body = try? JSONEncoder.adlo.encode(PasswordResetRequest(email: email))
        return Endpoint(path: "/auth/password-reset", method: .post, body: body, requiresAuth: false)
    }

    static func logout() -> Endpoint {
        Endpoint(path: "/auth/logout", method: .post)
    }

    static func currentUser() -> Endpoint {
        Endpoint(path: "/me", method: .get)
    }

    static func cases() -> Endpoint {
        Endpoint(path: "/cases", method: .get)
    }

    static func documents(caseID: String) -> Endpoint {
        Endpoint(path: "/cases/\(caseID)/documents", method: .get)
    }

    static func markDocumentSubmitted(caseID: String, documentID: String) -> Endpoint {
        Endpoint(path: "/cases/\(caseID)/documents/\(documentID)/submit", method: .post)
    }

    static func inquiry() -> Endpoint {
        Endpoint(path: "/inquiry", method: .get)
    }

    static func uscisStatus(receiptNumber: String) -> Endpoint {
        Endpoint(path: "/uscis-status", method: .get, query: [URLQueryItem(name: "receipt_number", value: receiptNumber)])
    }
}

extension JSONEncoder {
    static let adlo: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
}

extension JSONDecoder {
    static let adlo: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}
