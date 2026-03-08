# Mobile Implementation Notes (APP-002)

## Scope Delivered
APP-002 establishes an executable Flutter baseline under `app/mobile/` with:
- route shell for Home, Ranking, Detail, Watchlist, Alerts
- typed BE-001 API client wiring
- contract-shaped mock payload fallback for local boot without backend dependency

## Structure
- `app/mobile/lib/main.dart`: app entrypoint
- `app/mobile/lib/src/app.dart`: MaterialApp, route registration, shared API client instance
- `app/mobile/lib/core/routes/app_routes.dart`: route constants
- `app/mobile/lib/core/network/signaldesk_api_client.dart`: BE-001 endpoint client
- `app/mobile/lib/core/network/api_exception.dart`: normalized API exception model
- `app/mobile/lib/core/network/mock_payloads.dart`: contract-shaped mock responses
- `app/mobile/lib/core/models/api_models.dart`: typed DTO mapping for BE-001 payloads
- `app/mobile/lib/features/*`: screen stubs and baseline data loading flows

## Endpoint Wiring
- Home -> `GET /v1/dashboard`
- Ranking -> `GET /v1/keywords`
- Detail -> `GET /v1/keywords/{keyword_id}`
- Watchlist -> `GET /v1/watchlist`, `POST /v1/watchlist`
- Alerts -> `GET /v1/alerts`

## Runtime Configuration
- API base URL:
  - compile-time define: `SIGNALDESK_API_BASE_URL`
  - default: `http://127.0.0.1:8000`
- mock mode:
  - compile-time define: `SIGNALDESK_USE_MOCK`
  - default: `true`

Example (live API):
```bash
flutter run --dart-define=SIGNALDESK_USE_MOCK=false --dart-define=SIGNALDESK_API_BASE_URL=http://127.0.0.1:8000
```

## Local Setup
1. Install Flutter SDK + Android toolchain.
2. `cd app/mobile`
3. `flutter pub get`
4. `flutter run`

## Current Limitations
- no persistent local cache/offline store yet
- no authentication flow (out of scope for current personal MVP)
- watchlist mutation success path only; optimistic/error reconciliation is minimal
- visual polish and interaction refinements are intentionally deferred

## Next Hardening Targets
- APP-003: feature-level state management and repository abstraction hardening
- APP-004: pagination, retry, and stale-data UI strategy for production-like behavior
- APP-005: push notification deep-link handling implementation and tests
