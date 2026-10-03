import Foundation

/// Thin, testable HTTP client. Token access and 401-handling are injected via
/// closures so this type has no dependency on `AuthSession` (avoids a retain
/// cycle / import cycle between networking and auth).
final class APIClient {
    static let shared = APIClient()

    /// Supplies the current access token, if any.
    var accessTokenProvider: () -> String? = { nil }
    /// Awaited once when a request receives a 401 on an endpoint that
    /// required auth — there's no refresh token to silently exchange in the
    /// OTP model, so this just signals the caller to sign out.
    var onUnauthorized: () async -> Void = {}

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func send<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type = Response.self) async throws -> Response {
        let data = try await sendRaw(endpoint)
        let decoder: JSONDecoder = endpoint.usesRawKeys ? .adloRawKeys : .adlo
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    /// For endpoints with no response body (e.g. request-code).
    func sendVoid(_ endpoint: Endpoint) async throws {
        _ = try await sendRaw(endpoint)
    }

    /// For endpoints whose response is raw bytes rather than JSON (e.g. a
    /// downloaded document's file contents).
    func sendData(_ endpoint: Endpoint) async throws -> Data {
        try await sendRaw(endpoint)
    }

    private func sendRaw(_ endpoint: Endpoint) async throws -> Data {
        let request = try makeRequest(for: endpoint)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch http.statusCode {
        case 200..<300:
            return data
        case 401 where endpoint.requiresAuth:
            // An expired/invalid access token — there's no refresh exchange
            // to retry with in the OTP model, so sign the user out and
            // surface a clear error rather than a misleading generic one.
            await onUnauthorized()
            throw APIError.unauthorized
        default:
            let message = try? JSONDecoder.adlo.decode(ServerErrorBody.self, from: data).displayMessage
            throw APIError.server(status: http.statusCode, message: message)
        }
    }

    private func makeRequest(for endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(
            url: APIConfiguration.baseURL.appendingPathComponent(APIConfiguration.apiVersionPath + endpoint.path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = endpoint.query.isEmpty ? nil : endpoint.query

        guard let url = components?.url else { throw APIError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.setValue(endpoint.contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if endpoint.requiresAuth, let token = accessTokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }
}

/// adlo-portal's `/api/mobile/*` routes return `{ "error": "..." }`;
/// decode either key defensively rather than assuming one.
private struct ServerErrorBody: Decodable {
    let error: String?
    let message: String?

    var displayMessage: String? { error ?? message }
}
