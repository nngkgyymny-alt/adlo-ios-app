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
///
/// `apiVersionPath` is deliberately just `/api`, not `/api/mobile` — the
/// account/case/document endpoints (`Endpoint.currentUser`, `.cases`, etc.)
/// live under `/api/mobile/*`, but the forms/submissions endpoints
/// (`Endpoint.forms`, `.submission`, etc.) are the same `/api/forms` and
/// `/api/submissions/*` routes the web portal calls directly — they predate
/// the mobile-specific snake_case convention and use plain camelCase JSON
/// (see `JSONDecoder.adloRawKeys` / `Endpoint.usesRawKeys`). Each `Endpoint`
/// spells out its own full path below the shared `/api` root accordingly.
enum APIConfiguration {
    static let baseURL = URL(string: "https://adlo-portal.vercel.app")!
    static let apiVersionPath = "/api"
}
