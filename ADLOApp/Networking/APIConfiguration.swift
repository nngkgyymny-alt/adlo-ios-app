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
    /// lets `APIClient` get past that wall by hitting it ONCE to set a bypass
    /// cookie (see `APIClient.primeVercelBypassIfNeeded`), not by attaching it
    /// to every request — Vercel 307-redirects any request that still carries
    /// this param once the cookie already exists, and URLSession drops the
    /// `Authorization` header across that redirect, breaking every
    /// authenticated call. It's tied to that one deployment and **expires
    /// roughly 24 hours after being generated**; regenerate and paste in a
    /// fresh value if requests start failing with a Vercel login page instead
    /// of JSON. Production builds never need this — production has no such
    /// gate. `nil` disables the bypass entirely (plain requests, e.g. once
    /// pointed at a real non-preview backend).
    ///
    /// **Trap:** calling `get_access_to_vercel_url` again for this same
    /// deployment ROTATES the token — the previous value (including whatever
    /// is hardcoded below) stops working immediately, with no warning. Ran
    /// into this directly: repeated calls made for unrelated debugging
    /// silently broke this exact value mid-session. Only regenerate this when
    /// you intend to replace the value below with the new one right away.
    ///
    /// **Second trap:** redeploying the underlying preview deployment
    /// (e.g. to pick up a new env var) also invalidates the current token,
    /// even though the alias URL above doesn't change — regenerate again
    /// after any redeploy.
    static let vercelPreviewBypassToken: String? = {
        #if DEBUG
        return "nFOOWuo6Iugdu1nEOfS8CmQkblmZE3Z9"
        #else
        return nil
        #endif
    }()

    /// A cleaner long-term fix than `vercelPreviewBypassToken`: Vercel projects
    /// support a static "Automation Bypass Secret" (Project Settings →
    /// Deployment Protection) sent as a plain `x-vercel-protection-bypass`
    /// header on every request — no cookies, no redirect, no 24-hour
    /// expiration, and none of the Authorization-header-stripping fragility
    /// that motivated `APIClient.primeVercelBypassIfNeeded`. Generating one
    /// requires an account permission this session's Vercel connection
    /// doesn't have (403 on `update_project_protection_bypass`). Whoever does
    /// have that permission: generate it, then swap this whole file's bypass
    /// mechanism for a single `request.setValue(secret, forHTTPHeaderField:
    /// "x-vercel-protection-bypass")` in `APIClient.makeRequest` and delete
    /// `vercelPreviewBypassToken`/`primeVercelBypassIfNeeded` entirely.
}
