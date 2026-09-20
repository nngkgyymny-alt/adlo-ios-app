# ADLO iOS App

Native SwiftUI client-facing app for American Dream Law Office.

## Features (MVP)

- **Login** — email + password, forgot-password flow, session persisted via Keychain.
- **Sign Up** — self-service, for potential clients/leads only (`AccountType.prospect`).
  Retained clients don't sign up — their accounts are staff-provisioned; see
  "Two account types" below.
- **Home** *(clients)* — welcome screen, case snapshot, outstanding-document alert, quick contact links.
- **Case Status** *(clients)* — milestone timeline for the client's active case.
- **Documents** *(clients)* — document checklist with due dates; tap to mark submitted.
- **Inquiry Status** *(prospects)* — case details from a linked Lawmatics contact (if any) + intake status, with a "Book a Consultation" link.
- **Contact** — call, WhatsApp, email, office map, and hours.
- **More** — language preference (English/Español/العربية), notification toggle, log out, legal links.

## Two account types

`ClientUser.accountType` drives which tabs the app shows after sign-in
(`RootContentView`) — one login screen either way:

- **`.client`** — retained, has (or will have) a Lawmatics matter.
  Staff-provisioned only. Sees `RootTabView` (Home/Case Status/Documents/Contact/More).
- **`.prospect`** — self-signed-up lead. Sees `ProspectTabView`
  (Inquiry Status/Contact/More) — no case exists yet, just their fee
  estimate and a staff-editable status string.

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
  Services/       CaseService (clients), ProspectService (prospects)
  Models/         CaseFile, DocumentItem, InquiryStatus, FirmContact
  Views/          Auth (incl. SignUp), Home, CaseStatus, Documents, Prospect,
                  Contact, Settings, shared Components; RootContentView
                  branches to RootTabView (client) or ProspectTabView (prospect)
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
- Colors in `Theme.swift` and `AccentColor` are placeholders — replace with ADLO's
  official brand palette and app icon before release.
- Contact details in `FirmContact.swift` are placeholders — update with the real
  phone number, email, and address.
- `APIConfiguration.baseURL` is a placeholder — update once the real backend is deployed.
