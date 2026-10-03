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
    /// Most endpoints require the bearer token; the request-code/verify-code auth endpoints don't.
    var requiresAuth: Bool = true

    /// Step 1 of sign-in: emails a one-time code to this address. Always
    /// responds 200 regardless of whether the address is known — the backend
    /// never reveals that over an unauthenticated endpoint.
    static func requestCode(email: String) -> Endpoint {
        let body = try? JSONEncoder.adlo.encode(RequestCodeRequest(email: email))
        return Endpoint(path: "/auth/request", method: .post, body: body, requiresAuth: false)
    }

    /// Step 2: exchanges the emailed code for a long-lived bearer token.
    /// Email must match the one the code was requested for — the backend
    /// keys outstanding codes by email specifically to prevent guessing
    /// *any* valid code for *any* pending sign-in (see adlo-portal's
    /// lib/magic-link.ts).
    static func verifyCode(email: String, code: String) -> Endpoint {
        let body = try? JSONEncoder.adlo.encode(VerifyCodeRequest(email: email, code: code))
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

/// Plain `.iso8601` (`ISO8601DateFormatter()` with default options) rejects
/// timestamps with fractional seconds — and every timestamp adlo-portal
/// sends comes from JavaScript's `Date.toISOString()`, which always
/// includes milliseconds (e.g. `2026-10-03T20:04:38.123Z`). Without this,
/// every response containing a date (case lists, milestones, document
/// timestamps) fails to decode. Try fractional seconds first, fall back to
/// without, so this degrades gracefully if a date ever lacks them.
private let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

private let iso8601Plain = ISO8601DateFormatter()

extension JSONEncoder {
    static let adlo: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(iso8601WithFractionalSeconds.string(from: date))
        }
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
}

extension JSONDecoder {
    static let adlo: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = iso8601WithFractionalSeconds.date(from: raw) ?? iso8601Plain.date(from: raw) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected an ISO 8601 date string, got \(raw)"
            )
        }
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}
