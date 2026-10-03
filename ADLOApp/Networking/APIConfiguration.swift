import Foundation

/// Points the app at the ADLO client-portal API.
///
/// The iOS app never talks to the Lawmatics CRM API directly — Lawmatics has no
/// concept of client login, and embedding a CRM API key in a distributed app is
/// not safe. Instead this app calls ADLO's own backend, which authenticates
/// clients and reads/writes matter data from Lawmatics server-side.
///
/// This used to point at the `adlo-case-estimator` project's `/api/portal/*`
/// routes. Both apps' client-portal backends have been consolidated into
/// `adlo-portal` (see its `/api/mobile/*` routes) — one backend, one auth
/// model (magic-link/OTP), instead of two. `adlo-portal` has no Vercel
/// Deployment Protection gate on any environment, so unlike the old
/// configuration this needs no preview-bypass token or cookie priming at all.
enum APIConfiguration {
    static let baseURL = URL(string: "https://adlo-portal.vercel.app")!
    static let apiVersionPath = "/api/mobile"
}
