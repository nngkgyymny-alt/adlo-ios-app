# ADLO Client Portal API Contract

The iOS app never calls the Lawmatics CRM API directly. Lawmatics has no
concept of a client login, and shipping a CRM API key inside a distributed
app is not safe. Instead, the app calls **ADLO's own backend** — the
`adlo-portal` Next.js app, which also serves the web client portal — over
the REST API below.

Base URL: `APIConfiguration.baseURL` in `ADLOApp/Networking/APIConfiguration.swift`.
All endpoints are prefixed with `/api/mobile` (`APIConfiguration.apiVersionPath`),
matching `adlo-portal`'s actual route layout (`src/app/api/mobile/...`).
Requests/responses are JSON, `snake_case` on the wire (the app converts
to/from `camelCase`).

This used to point at a separate backend (`adlo-case-estimator`'s
`/api/portal/*`, password + refresh-token auth). The two client-portal
backends were consolidated into `adlo-portal` — one backend, one auth
model — rather than maintained in parallel; see that repo's own commit
history for the migration. `adlo-case-estimator`'s `/api/portal/*` routes
still exist but are no longer canonical.

## Auth

There's no separate signup step. The same emailed one-time-code flow works
whether or not this email has been seen before — the backend only learns
whether someone is a retained `client` vs. a `prospect` from whether their
email has ever synced to Lawmatics (see `lib/portal-accounts.ts` in
`adlo-portal`), not from a distinct account-creation call.

### `POST /api/mobile/auth/request`
```json
// Request
{ "email": "client@example.com" }
// 200 Response: { "ok": true } — always 200, whether or not the email is known,
// to avoid leaking which addresses exist.
```
Emails a one-time numeric code if the address is valid and not currently
rate-limited.

### `POST /api/mobile/auth/verify`
```json
// Request
{ "email": "client@example.com", "code": "123456" }
// 200 Response
{ "access_token": "eyJ...", "email": "client@example.com" }
```
`400` with `{ "error": "..." }` if either field is missing. `401` if the
code is invalid, expired, or doesn't match the one on file for this email
— codes are keyed by email specifically so a guess has to target a known
address, not just any outstanding code (see `lib/magic-link.ts` in
`adlo-portal`); wrong guesses are capped at 5 attempts before the code is
burned entirely. The access token is a stateless 30-day JWT (see
`lib/mobile-auth.ts` in `adlo-portal`) — there's no refresh token and
nothing to revoke server-side; signing out is local-only (delete the
stored token).

### `GET /api/mobile/me`
Bearer token required.
```json
{ "email": "client@example.com", "first_name": "Maria", "last_name": "Gomez", "account_type": "client" }
```
`account_type` is `"client"` (has synced at least one real intake form to
Lawmatics — sees `/cases`) or `"prospect"` (sees `/inquiry` instead).
`first_name`/`last_name` default to `""` until something's synced for this
email. One sign-in screen either way; the app branches on this field.

## Case data (`account_type: "client"`)

All endpoints below require `Authorization: Bearer <access_token>`.
A prospect account gets `[]` from `/cases` (not an error) — the app should
call `/inquiry` instead once `/me`'s `account_type` says `"prospect"`.

### `GET /api/mobile/cases`
One entry per intake form the client has started/submitted in the web
portal (there's no separate "case" concept — a case *is* a form
submission). The app currently shows the first one (see
`CaseService.fetchPrimaryCase`).
```json
[
  {
    "id": "submission:f3a9...",
    "case_type": "I-130 — Petition for Alien Relative",
    "reference_number": "On file with Lawmatics",
    "current_stage": "Engagement Letter Sent",
    "filed_date": "2026-05-01T00:00:00Z",
    "milestones": [
      { "id": "started", "title": "Form Started", "date": "2026-05-01T00:00:00Z", "is_complete": true },
      { "id": "submitted", "title": "Submitted to Attorney", "date": "2026-05-03T00:00:00Z", "is_complete": true },
      { "id": "confirmed", "title": "Confirmed Received by Firm", "date": "2026-05-03T00:05:00Z", "is_complete": true },
      { "id": "status", "title": "Case Status: Engagement Letter Sent", "date": "2026-05-10T00:00:00Z", "is_complete": true }
    ]
  }
]
```
`id` is the backend's own submission key — percent-encode it (it contains a
colon) before building any `/cases/{id}/...` path; see
`Endpoint.encodedPathComponent`. Every milestone is backed by a real
timestamp: `confirmed` only appears once a genuine Lawmatics webhook event
confirmed the push was processed (not just that our own POST got a 2xx),
and the trailing `status` milestone only appears once a real
`matter.status_changed`/`matter.stage_changed`/`matter.converted` webhook
has told us the matter's stage — never guessed or fabricated. There is
currently no real-time matter/reference number exposed by Lawmatics'
webhooks, so `reference_number` is a placeholder string, not a real case
number.

### `GET /api/mobile/cases/{caseId}/documents`
```json
[
  {
    "id": "pet_id",
    "title": "Petitioner's Photo ID",
    "detail": "U.S. passport, driver's license, or state ID",
    "is_submitted": true,
    "due_date": null,
    "has_file": true,
    "file_url": "/api/mobile/cases/submission%3Af3a9.../documents/pet_id/file"
  }
]
```
`file_url` is only ever this backend's own authenticated proxy path (never
a raw storage URL) — see the upload/file endpoint below. It's `null` when
`has_file` is `false`. There's no backend concept of a document being
"submitted" separately from "uploaded" — the two are the same state;
`is_submitted` mirrors `has_file`, and there's no separate submit step to
call.

### `POST /api/mobile/cases/{caseId}/documents/{documentId}/upload`
`multipart/form-data` with a single `file` field, up to 20 MB. Uploading a
file **is** the submission: it marks the item submitted as part of the same
call. Returns the updated document (same shape as the list above). `413`
if the file's too large, `400` for an unknown checklist item or a
missing/empty file.

`DocumentsView` builds the multipart body itself (`Endpoint.uploadDocument`)
and picks a file via `.fileImporter`; `AppState.uploadDocument` calls this
endpoint and replaces the matching entry in `AppState.documents` with the
response.

### `GET /api/mobile/cases/{caseId}/documents/{documentId}/file`
Streams the uploaded file's raw bytes back (with the original
`Content-Type`) rather than redirecting to a storage URL — the backing
store is private specifically so there is no public URL for it. `404` if
nothing's been uploaded for that document yet, or if the document/case
doesn't belong to the caller.

`AppState.fetchDocumentFile` calls this and hands the bytes to
`DocumentsView`, which writes them to a temp file and previews it with
QuickLook.

## Inquiry status (`account_type: "prospect"`)

### `GET /api/mobile/inquiry`
Bearer token required.
```json
{
  "status": "Fee estimate received — schedule a consultation to move forward",
  "case_type": "Family-Based Green Card (I-130/I-485)",
  "summary": "Estimate: $3,200–$4,800, moderate complexity",
  "has_lawmatics_contact": false
}
```
Backed by this email's most recent estimator-lead submission (the public
fee estimator on americandreamlawoffice.com), if any — `case_type`/`summary`
are `null` if there isn't one. `has_lawmatics_contact` is `true` once a
Lawmatics push for this email has actually synced (see `/me`'s
`account_type` logic) — at that point `status` reflects that, rather than
the estimator-lead copy. `status` is plain generated text, not a
staff-editable field.

## Government case status lookup (any account type)

### `GET /api/mobile/uscis-status?receipt_number=IOE1234567890`
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
USCIS directly** — see the "unverified" note at the top of `lib/uscis.ts`
in `adlo-portal`.

There is deliberately no equivalent endpoint for EOIR (immigration court)
status — EOIR has no public API, only the lookup website at
acis.eoir.justice.gov (A-Number, no login). The app links out to it
directly (`FirmContact.eoirStatusURL`) instead of attempting to scrape it.
Both the USCIS lookup form and the EOIR link live in one shared
`CaseStatusLookupView`, reached via a "Check USCIS / EOIR Status" link from
both `CaseStatusView` (clients) and `ProspectStatusView` (prospects) — not
its own tab, to keep the tab bar at 5 items.

## Backend implementation notes

- **Lawmatics OAuth is broken account-wide** (since June 2026, across every
  ADLO repo that's tried to use it) — `adlo-portal` never attempts an
  authenticated read. Writes go through Lawmatics' no-auth Custom Form
  endpoint (`lib/lawmatics-form.ts`); confirmation that a push actually
  landed, and all live case-status data, comes from a signed Lawmatics
  **webhook** receiver (`/api/webhooks/lawmatics`) instead of polling —
  see `lib/lawmatics-webhook.ts` and `lib/portal-accounts.ts`.
- **There's no staff-provisioning step.** Every account — client or
  prospect — is created the same way: sign in with an email, and the
  backend figures out which bucket you're in from whether anything's
  synced to Lawmatics for that email yet. A brand-new client who hasn't
  filled out any form yet still sees `account_type: "prospect"` until
  they do.
- **`current_stage`/milestones in `/cases` and `status` in `/inquiry`**
  reflect only what's actually been observed (a stored submission's own
  timestamps, or a genuine webhook event) — never a guess or a synthetic
  default. If something isn't known yet, the field says so in plain
  language rather than inventing a plausible-looking value.
