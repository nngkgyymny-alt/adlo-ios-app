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
    /// The raw `_vercel_jwt=...` cookie pair captured from the priming
    /// response, attached explicitly to every request's `Cookie` header. NOT
    /// left to `URLSession`'s automatic cookie jar — verified via a live curl
    /// reproduction that the cookie itself works perfectly when attached
    /// explicitly, but `URLSession`'s ambient cookie storage was not reliably
    /// picking it up from the priming hit's 307 response (untested exactly
    /// why — possibly how it interacts with automatic redirect-following).
    /// Managing it ourselves removes that whole class of uncertainty.
    private var manualBypassCookie: String?

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// A delegate that stops the priming request from following its 307
    /// redirect — we only need that redirect response's `Set-Cookie` header,
    /// not the page it points to.
    private final class NoRedirectDelegate: NSObject, URLSessionTaskDelegate {
        func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            willPerformHTTPRedirection response: HTTPURLResponse,
            newRequest request: URLRequest,
            completionHandler: @escaping (URLRequest?) -> Void
        ) {
            completionHandler(nil)
        }
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

    /// A protected Vercel preview deployment needs its SSO bypass cookie set
    /// once per session, then attached explicitly to every request (see
    /// `manualBypassCookie`). Deliberately NOT appended as a `_vercel_share`
    /// query param on every request: once the cookie exists, Vercel
    /// 307-redirects any further request that still carries that param (to
    /// strip it from the URL), and URLSession drops the `Authorization`
    /// header when it follows a redirect — silently turning every
    /// authenticated call into a 401. One clean priming hit avoids that.
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
            do {
                let (_, response) = try await session.data(for: URLRequest(url: url), delegate: NoRedirectDelegate())
                if let http = response as? HTTPURLResponse, let setCookie = http.value(forHTTPHeaderField: "Set-Cookie") {
                    self.manualBypassCookie = setCookie.components(separatedBy: ";").first
                }
            } catch {
                // Leave manualBypassCookie as-is; the real request that follows
                // will surface a clear .previewAccessBlocked error if this
                // genuinely failed, rather than failing silently here.
            }
        }
        bypassPrimingTask = task
        await task.value
    }

    private func sendRaw(_ endpoint: Endpoint, isRetry: Bool = false, bypassRetried: Bool = false) async throws -> Data {
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

        if Self.isBlockedByVercelProtection(status: http.statusCode, data: data) {
            // The priming hit ran, but this specific request still didn't carry
            // the bypass cookie (e.g. it raced ahead of the cookie actually
            // landing in storage). Force one fresh priming attempt and retry
            // this exact request before giving up with a clear error — don't
            // let it fall through to the generic "Something went wrong".
            guard !bypassRetried else { throw APIError.previewAccessBlocked }
            bypassPrimingTask = nil
            manualBypassCookie = nil
            await primeVercelBypassIfNeeded()
            return try await sendRaw(endpoint, isRetry: isRetry, bypassRetried: true)
        }

        switch http.statusCode {
        case 200..<300:
            return data
        case 401 where endpoint.requiresAuth:
            // A 401 here means an expired/invalid access token on an already
            // authenticated call — try a silent refresh-and-retry. A 401 on an
            // endpoint that never required auth (e.g. a bad login attempt) is a
            // completely different situation and falls through to `default`
            // below, where the server's actual message ("Invalid email or
            // password") is shown instead of a misleading "session expired".
            guard !isRetry, let newToken = await onUnauthorized() else {
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

    /// Vercel's own deployment-protection block returns a distinctive JSON
    /// shape (`{"error":{"code":"401","message":"Protected deployment"},
    /// "protection":{"vercel_auth_enabled":true,...}}`) that our own API never
    /// produces — this is how we tell "blocked before reaching our backend"
    /// apart from a real 401 from our own auth logic.
    private static func isBlockedByVercelProtection(status: Int, data: Data) -> Bool {
        guard status == 401 else { return false }
        return String(data: data, encoding: .utf8)?.contains("\"vercel_auth_enabled\"") ?? false
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

        if let cookie = manualBypassCookie {
            request.setValue(cookie, forHTTPHeaderField: "Cookie")
        }

        return request
    }
}

private struct ServerErrorBody: Decodable {
    let message: String?
}
