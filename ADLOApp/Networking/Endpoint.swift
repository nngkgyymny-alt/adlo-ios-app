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
    var contentType: String = "application/json"
    /// Most endpoints require the bearer token; auth endpoints (login, refresh) don't.
    var requiresAuth: Bool = true

    /// Step 1 of sign-in: emails a one-time code to this address. Always
    /// responds 200 regardless of whether the address is known — the backend
    /// never reveals that over an unauthenticated endpoint.
    static func requestCode(email: String) -> Endpoint {
        let body = try? JSONEncoder.adlo.encode(RequestCodeRequest(email: email))
        return Endpoint(path: "/auth/request", method: .post, body: body, requiresAuth: false)
    }

    /// Step 2: exchanges the emailed code for a long-lived bearer token.
    static func verifyCode(_ code: String) -> Endpoint {
        let body = try? JSONEncoder.adlo.encode(VerifyCodeRequest(code: code))
        return Endpoint(path: "/auth/verify", method: .post, body: body, requiresAuth: false)
    }

    static func currentUser() -> Endpoint {
        Endpoint(path: "/me", method: .get)
    }

    static func cases() -> Endpoint {
        Endpoint(path: "/cases", method: .get)
    }

    static func documents(caseID: String) -> Endpoint {
        Endpoint(path: "/cases/\(encodedPathComponent(caseID))/documents", method: .get)
    }

    static func markDocumentSubmitted(caseID: String, documentID: String) -> Endpoint {
        Endpoint(path: "/cases/\(encodedPathComponent(caseID))/documents/\(documentID)/submit", method: .post)
    }

    static func documentFile(caseID: String, documentID: String) -> Endpoint {
        Endpoint(path: "/cases/\(encodedPathComponent(caseID))/documents/\(documentID)/file", method: .get)
    }

    /// Multipart/form-data upload, matching the backend's single `file` field
    /// (see docs/API_CONTRACT.md's "Document data" section).
    static func uploadDocument(caseID: String, documentID: String, fileData: Data, fileName: String, mimeType: String) -> Endpoint {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        return Endpoint(
            path: "/cases/\(encodedPathComponent(caseID))/documents/\(documentID)/upload",
            method: .post,
            body: body,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
    }

    /// Case keys look like `submission:<uuid>` on the backend — percent-encode
    /// the whole segment (matching the web client's own `encodeURIComponent`)
    /// rather than relying on the colon being path-legal as-is.
    private static func encodedPathComponent(_ raw: String) -> String {
        raw.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? raw
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
