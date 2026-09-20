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
  "user": { "id": "123", "first_name": "Maria", "last_name": "Gomez", "email": "client@example.com", "account_type": "client" }
}
```
`401` with `{ "message": "..." }` on bad credentials. `account_type` is `"client"`
(retained — sees `/cases`) or `"prospect"` (self-signed-up lead — sees
`/inquiry`). One login screen either way; the app branches on this field.

### `POST /v1/auth/signup`
Public, no auth required — self-service, **prospects only**. Existing/retained
clients don't sign up here; their accounts are staff-provisioned (see
`docs/PORTAL_BACKEND.md` in `adlo-case-estimator`) and set up via the invite
link from `/auth/password-reset/confirm`.
```json
// Request
{ "email": "lead@example.com", "password": "••••••••", "first_name": "Jane", "last_name": "Doe" }

// 201 Response — same shape as login, account_type is always "prospect"
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "user": { "id": "456", "first_name": "Jane", "last_name": "Doe", "email": "lead@example.com", "account_type": "prospect" }
}
```
`409` with `{ "message": "..." }` if the email is already registered.

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
{ "id": "123", "first_name": "Maria", "last_name": "Gomez", "email": "client@example.com", "account_type": "client" }
```

## Case data (`account_type: "client"`)

All endpoints below require `Authorization: Bearer <access_token>`.
A prospect account gets `[]` from `/cases` (not an error) — the app should
call `/inquiry` instead once `/me`'s `account_type` says `"prospect"`.

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

## Inquiry status (`account_type: "prospect"`)

### `GET /v1/inquiry`
Bearer token required. `404` if called by a `"client"` account (use `/cases`
instead).
```json
{
  "status": "New Inquiry",
  "case_type": "Family-Based Green Card (I-130/I-485)",
  "fee_low": 3500,
  "fee_high": 5500,
  "summary": "Based on your answers...",
  "submitted_at": "2026-09-01T00:00:00Z"
}
```
`case_type`/`fee_low`/`fee_high`/`summary`/`submitted_at` are all `null` if
the prospect signed up without ever submitting the fee estimator on
immigrationcost.com. `status` is a staff-editable free-text string (e.g.
"New Inquiry", "Consultation Requested") — there's no automatic progression.

## Backend implementation notes

This contract is now implemented — see `docs/PORTAL_BACKEND.md` in
`adlo-case-estimator` for the actual design (Redis-backed accounts,
scrypt/JWT auth, and the reasoning below in more detail).

- **Client identity isn't in Lawmatics.** Confirmed: neither Lawmatics nor
  this backend's `client` accounts are self-service — staff provision them
  via `POST /api/staff/portal/clients`, which locks the account and emails
  an invite link reusing the `/auth/password-reset/confirm` flow. Prospect
  accounts (`POST /auth/signup` above) are the one self-service path, and
  they don't touch Lawmatics case data at all.
- **Lawmatics OAuth has been unreliable** (broke account-wide June 2026,
  `adlo-case-estimator` has a no-auth Custom Form fallback for lead intake).
  The backend's `getMatter` (`src/lib/lawmatics-matters.ts`) is unverified
  against a live account for this reason — it fails soft (falls back to
  "In Progress") rather than breaking `/cases`.
- **Case status has no established mapping** from Lawmatics — confirmed
  after building it: nothing in the existing repos ever read a Matter back,
  only created them. `current_stage` in `/cases` comes from Lawmatics'
  documented (not verified) `stage`/`status` fields when a matter is
  linked; `milestones` and everything under `/inquiry` are backend-native
  (staff-edited), not sourced from Lawmatics at all.
