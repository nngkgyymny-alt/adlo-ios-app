# ADLO iOS App

Native SwiftUI client-facing app for American Dream Law Office.

## Features (MVP)

- **Home** — welcome screen, case snapshot, outstanding-document alert, quick contact links.
- **Case Status** — milestone timeline for the client's active case.
- **Documents** — document checklist with due dates; tap to mark submitted.
- **Contact** — call, WhatsApp, email, office map, and hours.
- **More** — language preference (English/Español/العربية), notification toggle, legal links.

All data is currently mocked in `AppState` (`ADLOApp/App/AppState.swift`) — wire this
up to ADLO's backend/CRM (e.g. the same API the case-estimator or client portal uses)
before shipping.

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

## Project Structure

```
ADLOApp/
  App/            App entry point, Theme, AppState
  Models/         CaseFile, DocumentItem, FirmContact
  Views/          Home, CaseStatus, Documents, Contact, Settings, shared Components
  Resources/      Info.plist, Assets.xcassets
ADLOAppTests/     Unit tests
```

## Notes

- Bundle identifier: `com.americandreamlawoffice.adlo` — update in `project.yml` if different.
- Colors in `Theme.swift` and `AccentColor` are placeholders — replace with ADLO's
  official brand palette and app icon before release.
- Contact details in `FirmContact.swift` are placeholders — update with the real
  phone number, email, and address.
