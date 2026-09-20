# ADLO iOS App

Native SwiftUI client-facing app for American Dream Law Office.

## Features (MVP)

- **Welcome screen** — the first thing a signed-out user sees: two tracks,
  "Current Client" and "New / Potential Client" (`WelcomeView`), rather than
  one shared login form with a small signup link buried in it. An "Email Us"
  button lets a visitor who isn't ready to log in or sign up email the firm
  directly — it asks current-vs-potential first so the message lands in the
  right inbox (`clients@` vs. `intake@`, same routing `ContactView` uses).
- **Login** — email + password, forgot-password flow, session persisted via Keychain.
- **New Client** — leads with "Schedule a Consultation" (opens the firm's
  consultation booking page) since that's the primary action for someone
  without an existing relationship with the firm; "Create a Free Account" and
  "Log In" are secondary options for tracking an inquiry already in progress
  (`NewClientView`). Self-service signup is for potential clients/leads only
  (`AccountType.prospect`) — retained clients don't sign up; their accounts
  are staff-provisioned. See "Two account types" below.
- **Home** *(clients)* — welcome screen, case snapshot, outstanding-document alert, quick contact links.
- **Case Status** *(clients)* — milestone timeline for the client's active case.
- **Documents** *(clients)* — document checklist with due dates; tap to mark
  submitted, or upload a photo/PDF of the actual document (uploading a file
  is the submission). An already-uploaded file can be viewed in place via
  QuickLook. Files are stored in a private Vercel Blob store and only ever
  served back through an authenticated backend route — see
  `adlo-case-estimator`'s `docs/PORTAL_BACKEND.md`.
- **Inquiry Status** *(prospects)* — leads with "Schedule a Consultation", then case details from a linked Lawmatics contact (if any) + intake status.
- **Check USCIS / EOIR Status** *(both)* — a receipt-number lookup against USCIS's real Case Status API, plus a link out to EOIR's official ACIS site (no public API exists for EOIR). Reached from a link on Case Status (clients) / Inquiry Status (prospects), not its own tab.
- **Contact** — call, WhatsApp, email, a "Meet the Staff" link to the firm's
  team page, office map, hours, and social links.
- **More** — language preference (English/Español/العربية), notification toggle, log out, legal links.

## Two account types

`ClientUser.accountType` drives which tabs the app shows after sign-in
(`RootContentView`) — reached via either track on `WelcomeView`, since
`/auth/login` doesn't care which button got you there:

- **`.client`** — retained, has (or will have) a Lawmatics matter.
  Staff-provisioned only. Sees `RootTabView` (Home/Case Status/Documents/Contact/More).
- **`.prospect`** — self-signed-up lead. Sees `ProspectTabView`
  (Inquiry Status/Contact/More) — no case exists yet, just a linked
  Lawmatics contact (if any) and a staff-editable status string.

Case/document/inquiry data and auth now go through a real networking layer
(`ADLOApp/Networking/`, `ADLOApp/Auth/`) — and, as of the
`adlo-case-estimator` client-portal-backend PR, **a real backend to talk
to.** See [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md) for the REST
contract, and `adlo-case-estimator`'s `docs/PORTAL_BACKEND.md` for how it's
actually implemented.

## Requirements

- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Getting Started

```bash
xcodegen generate
open ADLOApp.xcodeproj
```

The generated `.xcodeproj` is gitignored — `project.yml` is the source of truth.
Run `xcodegen generate` again after adding/removing files or changing build settings.

Until a real backend exists, point `APIConfiguration.baseURL`
(`ADLOApp/Networking/APIConfiguration.swift`) at a mock server (e.g.
[json-server](https://github.com/typicode/json-server) or a
[Postman mock](https://www.postman.com/mock-server/)) implementing
`docs/API_CONTRACT.md` to run the app end-to-end.

## Project Structure

```
ADLOApp/
  App/            App entry point, Theme, AppState
  Auth/           AuthSession, Keychain-backed token storage, auth models
  Networking/     APIClient, Endpoint definitions, APIConfiguration, APIError
  Services/       CaseService (clients), ProspectService (prospects),
                  CaseStatusLookupService (USCIS, both account types)
  Models/         CaseFile, DocumentItem, InquiryStatus, USCISCaseStatus, FirmContact
  Views/          Auth (Welcome, Login, SignUp, NewClient), Home, CaseStatus,
                  Documents, Prospect, CaseStatusLookup, Contact, Settings,
                  shared Components; RootContentView shows WelcomeView when
                  signed out, else branches to RootTabView (client) or
                  ProspectTabView (prospect)
  Resources/      Info.plist, Assets.xcassets
ADLOAppTests/     Unit tests
docs/             API contract for the backend
```

## Auth & Networking Architecture

- `AuthSession` (`ADLOApp/Auth/AuthSession.swift`) owns the signed-in state,
  drives login/logout/password-reset, and transparently refreshes the
  access token on a 401 via `APIClient.onUnauthorized`.
- Access tokens are held in memory only; refresh tokens are persisted in
  the Keychain (`KeychainStore.swift`) so a session survives app relaunch.
- `APIClient` (`ADLOApp/Networking/APIClient.swift`) is a thin, protocol-free
  HTTP client — no dependency on `AuthSession`, so it's easy to unit test in
  isolation. Endpoints are declared in `Endpoint.swift`.
- `CaseService` conforms to `CaseDataProviding` so `AppState` can be tested
  with a fake implementation (see `ADLOAppTests`) instead of hitting the network.

## Notes

- Bundle identifier: `com.americandreamlawoffice.adlo` — update in `project.yml` if different.
- Colors in `Theme.swift` and `AccentColor` match the live site's brand
  palette (`adlo-case-estimator/src/app/globals.css` is the source of truth —
  navy `#1C2B46`, red `#EE2110`, teal `#00436E`; there is no "gold" in the
  real brand). The app icon and in-app branding (`WelcomeView`, `LoginView`)
  now use the real ADLO seal logo (`FirmLogo` in Assets.xcassets, sourced
  from `adlo-diy/sales-site/dist/assets/brand/adlo-seal-logo.png`) instead
  of a placeholder SF Symbol.
- Contact details in `FirmContact.swift` are real, verified against
  `adlo-diy`'s vCards and `adlo-case-estimator`'s structured data — not
  placeholders. Phone number reuses the sales site's EN tracking number
  (`PHONE_I18N["en"]` in `adlo-diy/tools/site-backup/build_sales_site.py`)
  rather than a separate number provisioned just for the app. Email is
  track-specific (`FirmContact.contactEmail(for:)`, driven by
  `AppState.accountType`): `intake@americandreamlawoffice.com` for
  new/potential clients, `clients@americandreamlawoffice.com` for existing
  ones — the sales site itself never displays a public email, but these are
  specific to the app's own two tracks.
- `APIConfiguration.baseURL` is a placeholder — update once the real backend is deployed.
