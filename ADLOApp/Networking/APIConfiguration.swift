import Foundation

/// Points the app at the ADLO client-portal API.
///
/// The iOS app never talks to the Lawmatics CRM API directly — Lawmatics has no
/// concept of client login, and embedding a CRM API key in a distributed app is
/// not safe. Instead this app calls ADLO's own backend, which authenticates
/// clients and reads/writes matter data from Lawmatics server-side. See
/// `docs/API_CONTRACT.md` for the endpoints this app expects that backend to expose.
enum APIConfiguration {
    /// Override at build time with `-D API_BASE_URL_STAGING` or by editing this
    /// default once the real backend URL is known.
    static var baseURL: URL {
        #if DEBUG
        URL(string: "https://adlo-case-estimator-git-claude-065c79-american-dream-law-office.vercel.app")!
        #else
        URL(string: "https://api.americandreamlawoffice.com")!
        #endif
    }

    static let apiVersionPath = "/api/portal"

    /// The `adlo-case-estimator` Vercel project gates every preview deployment
    /// (including its API routes, not just the browser homepage) behind Vercel's
    /// own SSO/login wall. This bypass token — generated via
    /// `get_access_to_vercel_url` for the specific preview deployment above —
    /// lets `APIClient` get past that wall on every request. It's tied to that
    /// one deployment and **expires roughly 24 hours after being generated**;
    /// regenerate and paste in a fresh value if requests start failing with a
    /// Vercel login page instead of JSON. Production builds never need this —
    /// production has no such gate. `nil` disables the bypass entirely (plain
    /// requests, e.g. once pointed at a real non-preview backend).
    static let vercelPreviewBypassToken: String? = {
        #if DEBUG
        return "OdzVLmoptTfrA3ZqDLc6jZJVuLC0Ag2x"
        #else
        return nil
        #endif
    }()
}
