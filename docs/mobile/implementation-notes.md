# Mobile Implementation Notes (APP-002)

## Scope
Implemented the first executable mobile baseline under `app/mobile/` aligned to frozen BE-001 contract fields.

## What Was Implemented
- Flutter app shell with route structure for:
  - Home (`/`)
  - Keyword Ranking (`/ranking`)
  - Keyword Detail (`/detail`)
  - Watchlist (`/watchlist`)
  - Alerts (`/alerts`)
- Typed API domain models for BE-001 endpoints:
  - `GET /dashboard`
  - `GET /keywords`
  - `GET /keywords/{keyword_id}`
  - `GET /watchlist`
  - `POST /watchlist`
  - `GET /alerts`
- Concrete HTTP API client wiring with query/body encoding and JSON mapping.
- Mock API provider with contract-shaped payloads for local UI smoke checks without backend runtime.

## Run
From `app/mobile`:

```powershell
flutter pub get
flutter run --dart-define=USE_MOCK_API=true
```

For live API wiring:

```powershell
flutter run --dart-define=USE_MOCK_API=false --dart-define=SIGNAL_DESK_BASE_URL=http://10.0.2.2:8080
```

## Current Limitations
- Flutter SDK is not installed in current worker environment, so build/analyze/test could not be executed here.
- UI is baseline shell-focused and intentionally minimal; pagination and richer error recovery are next-step hardening.
- No push notification runtime integration yet (out of APP-002 baseline).

## Contract Notes
- Enums and field names follow `docs/backend/api-contract.md` v1 frozen contract.
- Nullable fields are represented as nullable Dart types to avoid schema mismatch on partial payloads.

## Verification Commands And Outcomes
1. `flutter --version` -> failed: command not found (`flutter` not installed).
2. `flutter pub get` -> failed: command not found (`flutter` not installed).
3. `flutter analyze` -> failed: command not found (`flutter` not installed).
