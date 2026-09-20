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
        URL(string: "https://staging-api.americandreamlawoffice.com")!
        #else
        URL(string: "https://api.americandreamlawoffice.com")!
        #endif
    }

    static let apiVersionPath = "/v1"
}
