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
    /// The forms/submissions endpoints predate the `/api/mobile/*` snake_case
    /// convention and use plain camelCase JSON (matching their TypeScript
    /// interfaces directly) — set true so `APIClient` decodes/encodes their
    /// bodies without key conversion. See `JSONDecoder.adloRawKeys`.
    var usesRawKeys: Bool = false

    // MARK: - Auth (/api/mobile/auth/*)

    /// Step 1 of sign-in: emails a one-time code to this address. Always
    /// responds 200 regardless of whether the address is known — the backend
    /// never reveals that over an unauthenticated endpoint.
    static func requestCode(email: String) -> Endpoint {
        let body = try? JSONEncoder.adlo.encode(RequestCodeRequest(email: email))
        return Endpoint(path: "/mobile/auth/request", method: .post, body: body, requiresAuth: false)
    }

    /// Step 2: exchanges the emailed code for a long-lived bearer token.
    /// Email must match the one the code was requested for — the backend
    /// keys outstanding codes by email specifically to prevent guessing
    /// *any* valid code for *any* pending sign-in (see adlo-portal's
    /// lib/magic-link.ts).
    static func verifyCode(email: String, code: String) -> Endpoint {
        let body = try? JSONEncoder.adlo.encode(VerifyCodeRequest(email: email, code: code))
        return Endpoint(path: "/mobile/auth/verify", method: .post, body: body, requiresAuth: false)
    }

    // MARK: - Account / cases (/api/mobile/*)

    static func currentUser() -> Endpoint {
        Endpoint(path: "/mobile/me", method: .get)
    }

    static func cases() -> Endpoint {
        Endpoint(path: "/mobile/cases", method: .get)
    }

    static func documents(caseID: String) -> Endpoint {
        Endpoint(path: "/mobile/cases/\(encodedPathComponent(caseID))/documents", method: .get)
    }

    static func documentFile(caseID: String, documentID: String) -> Endpoint {
        Endpoint(path: "/mobile/cases/\(encodedPathComponent(caseID))/documents/\(documentID)/file", method: .get)
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
            path: "/mobile/cases/\(encodedPathComponent(caseID))/documents/\(documentID)/upload",
            method: .post,
            body: body,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
    }

    static func inquiry() -> Endpoint {
        Endpoint(path: "/mobile/inquiry", method: .get)
    }

    static func uscisStatus(receiptNumber: String) -> Endpoint {
        Endpoint(path: "/mobile/uscis-status", method: .get, query: [URLQueryItem(name: "receipt_number", value: receiptNumber)])
    }

    // MARK: - Forms / submissions (/api/forms, /api/submissions/*)
    //
    // These are the same routes the web portal calls directly (and that
    // adlo-cross's Forms feature already calls — see its src/api/endpoints/
    // forms.ts) — plain camelCase JSON, no /mobile prefix, no snake_case
    // conversion. `usesRawKeys: true` on every one of these.

    static func forms() -> Endpoint {
        Endpoint(path: "/forms", method: .get, usesRawKeys: true)
    }

    static func form(formId: String) -> Endpoint {
        Endpoint(path: "/forms/\(encodedPathComponent(formId))", method: .get, usesRawKeys: true)
    }

    static func submissionsList() -> Endpoint {
        Endpoint(path: "/submissions/list", method: .get, usesRawKeys: true)
    }

    static func submission(key: String) -> Endpoint {
        Endpoint(path: "/submissions/\(encodedPathComponent(key))", method: .get, usesRawKeys: true)
    }

    static func createSubmission(formId: String) -> Endpoint {
        let body = try? JSONEncoder.adloRawKeys.encode(CreateSubmissionRequest(formId: formId))
        return Endpoint(path: "/submissions/create", method: .post, body: body, usesRawKeys: true)
    }

    /// `data` is only the changed fields, not the whole form — matches the
    /// web/adlo-cross autosave behavior (PATCH merges server-side).
    static func saveDraft(key: String, data: FormData) -> Endpoint {
        let body = try? JSONEncoder.adloRawKeys.encode(SaveDraftRequest(data: data))
        return Endpoint(path: "/submissions/\(encodedPathComponent(key))", method: .patch, body: body, usesRawKeys: true)
    }

    static func submitSubmission(key: String) -> Endpoint {
        Endpoint(path: "/submissions/\(encodedPathComponent(key))", method: .post, usesRawKeys: true)
    }

    /// Case/submission keys look like `submission:<uuid>` on the backend —
    /// percent-encode the whole segment (matching the web client's own
    /// `encodeURIComponent`) rather than relying on the colon being
    /// path-legal as-is.
    private static func encodedPathComponent(_ raw: String) -> String {
        raw.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? raw
    }
}

private struct CreateSubmissionRequest: Encodable {
    let formId: String
}

private struct SaveDraftRequest: Encodable {
    let data: FormData
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

private let customDateEncoding: (Date, Encoder) throws -> Void = { date, encoder in
    var container = encoder.singleValueContainer()
    try container.encode(iso8601WithFractionalSeconds.string(from: date))
}

private let customDateDecoding: (Decoder) throws -> Date = { decoder in
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

extension JSONEncoder {
    /// For `/api/mobile/*` bodies — snake_case on the wire.
    static let adlo: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom(customDateEncoding)
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    /// For `/api/forms` and `/api/submissions/*` bodies — plain camelCase,
    /// matching those routes' TypeScript interfaces directly.
    static let adloRawKeys: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom(customDateEncoding)
        return encoder
    }()
}

extension JSONDecoder {
    /// For `/api/mobile/*` responses — snake_case on the wire.
    static let adlo: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(customDateDecoding)
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    /// For `/api/forms` and `/api/submissions/*` responses — plain camelCase.
    static let adloRawKeys: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(customDateDecoding)
        return decoder
    }()
}
