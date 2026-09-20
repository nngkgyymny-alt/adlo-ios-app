# ADLO Client Portal API Contract

The iOS app never calls the Lawmatics CRM API directly. Lawmatics has no
concept of a client login, and shipping a CRM API key inside a distributed
app is not safe. Instead, the app expects **ADLO's own backend** to expose
the REST API below; that backend authenticates clients and reads/writes
case data from Lawmatics server-side (see "Backend implementation notes").

Base URL: `APIConfiguration.baseURL` in `ADLOApp/Networking/APIConfiguration.swift`
(currently a placeholder — update once a real host exists).
All endpoints are prefixed with `/v1`. Requests/responses are JSON,
`snake_case` on the wire (the app converts to/from `camelCase`).

## Auth

### `POST /v1/auth/login`
```json
// Request
{ "email": "client@example.com", "password": "••••••••" }

// 200 Response
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "user": { "id": "123", "first_name": "Maria", "last_name": "Gomez", "email": "client@example.com" }
}
```
`401` with `{ "message": "..." }` on bad credentials.

### `POST /v1/auth/refresh`
```json
// Request
{ "refresh_token": "eyJ..." }
// 200 Response
{ "access_token": "eyJ...", "refresh_token": "eyJ..." }
```
`401` if the refresh token is invalid/expired — the app signs the user out.

### `POST /v1/auth/password-reset`
```json
// Request
{ "email": "client@example.com" }
// 200 Response: empty body. Always returns 200 to avoid leaking which emails exist.
```

### `POST /v1/auth/logout`
Invalidates the refresh token server-side. Empty body, bearer token required.

### `GET /v1/me`
Bearer token required.
```json
{ "id": "123", "first_name": "Maria", "last_name": "Gomez", "email": "client@example.com" }
```

## Case data

All endpoints below require `Authorization: Bearer <access_token>`.

### `GET /v1/cases`
Every case the signed-in client has visibility into (the app currently
shows the first one — see `CaseService.fetchPrimaryCase`).
```json
[
  {
    "id": "case_123",
    "case_type": "Family-Based Green Card (I-130/I-485)",
    "reference_number": "ADL-2026-0142",
    "current_stage": "Awaiting Biometrics Appointment",
    "filed_date": "2026-05-01T00:00:00Z",
    "milestones": [
      { "id": "m1", "title": "Retainer Signed", "date": "2026-05-01T00:00:00Z", "is_complete": true },
      { "id": "m2", "title": "Biometrics Appointment", "date": null, "is_complete": false }
    ]
  }
]
```

### `GET /v1/cases/{caseId}/documents`
```json
[
  {
    "id": "doc_1",
    "title": "Valid Passport (all pages)",
    "detail": "Clear copy of every page, including blank ones.",
    "is_submitted": true,
    "due_date": null
  }
]
```

### `POST /v1/cases/{caseId}/documents/{documentId}/submit`
Marks a document as submitted (client confirms they've sent it in some other
channel — email, portal upload, in person). Empty body/response.

> The app does not yet support un-marking a document as submitted via the
> API — `AppState.toggleSubmitted` only calls this endpoint on the
> not-submitted → submitted transition.

## Backend implementation notes

- **Client identity isn't in Lawmatics.** Lawmatics is used today for lead
  intake only (`adlo-diy`'s `/api/screener-lead`, `adlo-case-estimator`'s
  `src/lib/lawmatics.ts`) — write-only, no client accounts, no Matters API
  calls. The backend will need its own client credential store (email +
  hashed password) separate from Lawmatics, most likely keyed by the
  Lawmatics contact/matter ID so case data can still be looked up there.
- **Lawmatics OAuth has been unreliable.** `adlo-case-estimator` falls back
  to a no-auth "Custom Form" submit because Lawmatics OAuth broke
  account-wide in June 2026. Confirm Lawmatics' Matters API is actually
  reachable (and that ADLO's plan includes it) before building the
  `/cases` endpoints against it.
- **Case status has no established mapping.** Nothing in the existing repos
  reads Matters/case-stage data back from Lawmatics — `current_stage` and
  `milestones` above are a UI-level shape the app expects, not a Lawmatics
  field name. Whoever builds the backend needs to decide how Lawmatics
  matter statuses/custom fields map to these milestones.
