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
  "summary": "Submitted via consultation screener, urgency: same_day",
  "has_lawmatics_contact": true
}
```
`case_type`/`summary` are `null` if no Lawmatics contact was found for this
email (`has_lawmatics_contact: false`) — e.g. the prospect signed up cold,
without ever going through the consultation screener at
americandreamlawoffice.com/consultation/ (the primary source this links
to — see `docs/PORTAL_BACKEND.md` in `adlo-case-estimator`) or any other
lead form. There is deliberately **no fee estimate here** — that only ever
existed for fee-estimator leads specifically, and this endpoint no longer
sources from that. `status` is a staff-editable free-text string (e.g.
"New Inquiry", "Consultation Requested") — there's no automatic progression.

## Government case status lookup (any account type)

### `GET /v1/uscis-status?receipt_number=IOE1234567890`
Bearer token required — but available to **any** signed-in account, client
or prospect. A USCIS receipt number isn't tied to whether its holder has
retained ADLO.
```json
{
  "receipt_number": "IOE1234567890",
  "form_type": "I-130",
  "submitted_date": "2026-01-15",
  "modified_date": "2026-06-01",
  "status": "Case Was Approved",
  "description": "We approved your Form I-130.",
  "history": [
    { "status": "Case Was Received", "date": "2026-01-15", "description": "We received your form." },
    { "status": "Case Was Approved", "date": "2026-06-01", "description": "We approved your Form I-130." }
  ]
}
```
`400` for a malformed receipt number (checked before ever calling USCIS —
must be a 3-letter prefix + 10 digits, e.g. `EAC/LIN/SRC/IOE/MSC/NBC/WAC/YSC`),
`404` if USCIS has no record of it, `502` for anything else (USCIS down,
rate-limited, or an unexpected response shape). **The exact field names
above are sourced from a third-party OpenAPI mirror, not confirmed against
USCIS directly** — see the "unverified" note in `adlo-case-estimator`'s
`docs/PORTAL_BACKEND.md`.

There is deliberately no equivalent endpoint for EOIR (immigration court)
status — EOIR has no public API, only the lookup website at
acis.eoir.justice.gov (A-Number, no login). The app links out to it
directly (`FirmContact.eoirStatusURL`) instead of attempting to scrape it.
Both the USCIS lookup form and the EOIR link live in one shared
`CaseStatusLookupView`, reached via a "Check USCIS / EOIR Status" link from
both `CaseStatusView` (clients) and `ProspectStatusView` (prospects) — not
its own tab, to keep the tab bar at 5 items.

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
  linked; `milestones` are backend-native (staff-edited), not sourced from
  Lawmatics at all.
- **`/inquiry` links to a Lawmatics *contact* by email**, not a local
  record — `case_type`/`summary` come from that contact's `case_title`/
  `case_blurb` fields, read live on each call (with a persisted-id
  shortcut so repeat calls skip the search). Contact search-by-email is a
  verified pattern (already used in production in `adlo-diy`); reading a
  single contact's full record for display fields is new and, like
  `getMatter`, unverified against a real response. `inquiry_status` is
  unrelated — plain backend-native state, staff-edited.
