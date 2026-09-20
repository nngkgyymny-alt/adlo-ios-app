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
    private var bypassPrimingTask: Task<Void, Never>?

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

    /// A protected Vercel preview deployment needs its SSO bypass cookie set once
    /// per session — after that, `URLSession`'s shared cookie storage carries it
    /// on every subsequent request automatically. Deliberately NOT appended as a
    /// `_vercel_share` query param on every request: once the cookie exists,
    /// Vercel 307-redirects any further request that still carries that param
    /// (to strip it from the URL), and URLSession drops the `Authorization`
    /// header when it follows a redirect — silently turning every authenticated
    /// call into a 401. One clean priming hit avoids that entirely.
    private func primeVercelBypassIfNeeded() async {
        guard let bypassToken = APIConfiguration.vercelPreviewBypassToken else { return }
        if let existing = bypassPrimingTask {
            await existing.value
            return
        }
        let session = session
        let task = Task<Void, Never> {
            guard var components = URLComponents(url: APIConfiguration.baseURL, resolvingAgainstBaseURL: false) else { return }
            components.queryItems = [URLQueryItem(name: "_vercel_share", value: bypassToken)]
            guard let url = components.url else { return }
            _ = try? await session.data(from: url)
        }
        bypassPrimingTask = task
        await task.value
    }

    private func sendRaw(_ endpoint: Endpoint, isRetry: Bool = false) async throws -> Data {
        await primeVercelBypassIfNeeded()
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
        components?.queryItems = endpoint.query.isEmpty ? nil : endpoint.query

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
