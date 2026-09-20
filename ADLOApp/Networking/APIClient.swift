import Foundation

/// Thin, testable HTTP client. Token access and 401-handling are injected via
/// closures so this type has no dependency on `AuthSession` (avoids a retain
/// cycle / import cycle between networking and auth).
final class APIClient {
    static let shared = APIClient()

    /// Supplies the current access token, if any.
    var accessTokenProvider: () -> String? = { nil }
    /// Called once, synchronously, when a request receives a 401. Return a new
    /// access token to retry the original request once, or `nil` to give up
    /// (the caller should then sign the user out).
    var onUnauthorized: () async -> String? = { nil }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func send<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type = Response.self) async throws -> Response {
        let data = try await sendRaw(endpoint)
        do {
            return try JSONDecoder.adlo.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    /// For endpoints with no response body (e.g. logout, mark-submitted).
    func sendVoid(_ endpoint: Endpoint) async throws {
        _ = try await sendRaw(endpoint)
    }

    private func sendRaw(_ endpoint: Endpoint, isRetry: Bool = false) async throws -> Data {
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
        case 401:
            guard endpoint.requiresAuth, !isRetry, let newToken = await onUnauthorized() else {
                throw APIError.unauthorized
            }
            var retryEndpoint = endpoint
            retryEndpoint.requiresAuth = true
            return try await sendRaw(retryEndpoint, isRetry: true)
        default:
            let message = try? JSONDecoder.adlo.decode(ServerErrorBody.self, from: data).message
            throw APIError.server(status: http.statusCode, message: message)
        }
    }

    private func makeRequest(for endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(
            url: APIConfiguration.baseURL.appendingPathComponent(APIConfiguration.apiVersionPath + endpoint.path),
            resolvingAgainstBaseURL: false
        )
        var queryItems = endpoint.query
        if let bypassToken = APIConfiguration.vercelPreviewBypassToken {
            queryItems.append(URLQueryItem(name: "_vercel_share", value: bypassToken))
        }
        components?.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components?.url else { throw APIError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if endpoint.requiresAuth, let token = accessTokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }
}

private struct ServerErrorBody: Decodable {
    let message: String?
}
