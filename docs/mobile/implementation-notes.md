# Mobile Implementation Notes

## Scope Delivered
APP-004 extends the APP-003 baseline with:
- cursor-based next-page loading on Ranking and Alerts using `next_cursor`
- stale-data context on Home, Ranking, Detail, Watchlist, and Alerts based on `generated_at`
- repository/controller updates to support page merge behavior while keeping screen code inside the existing abstraction boundaries

## Key APP-004 Changes
- `LoadableController` now supports `replaceData(...)` so list flows can append pages without bypassing the shared state primitive.
- `SignalDeskRepository` now owns cursor-page merge logic:
  - `mergeKeywordsPages(...)`
  - `mergeAlertsPages(...)`
- `SignalDeskApiClient` mock mode now respects cursor + filter query inputs for `GET /keywords` and `GET /alerts`.
- `MockPayloads` now returns multi-page ranking and alerts data with realistic `next_cursor` behavior.
- shared `DataFreshnessBanner` renders:
  - snapshot age
  - local generated timestamp
  - stale warning when age exceeds the policy threshold

## Freshness Rules
- default stale threshold: 6 hours
- ranking period overrides:
  - `intraday`: 2 hours
  - `weekly`: 24 hours
  - `daily`: 6 hours (default)
- screens with stale-data context:
  - Home
  - Ranking
  - Keyword Detail
  - Watchlist
  - Alerts

## Pagination Behavior
- Ranking:
  - initial page load still uses shared `LoadableController`
  - `Load More` uses the current `next_cursor`, merges results, and updates controller data
  - footer states: loading spinner, retry action, and end-of-results marker
  - pull-to-refresh resets to page 1
- Alerts:
  - same cursor flow and footer states as Ranking
  - severity filter changes reset to page 1
  - guarded against stale async merges when filter changes mid-request

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
4. `flutter analyze`
5. `flutter test`
6. `flutter run --dart-define=SIGNALDESK_USE_MOCK=true`

## Verification Status (APP-004 Session)
Commands attempted in `app/mobile`:
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter run --dart-define=SIGNALDESK_USE_MOCK=true --debug`

Outcome:
- all commands blocked with `flutter : The term 'flutter' is not recognized ...`
- SDK/toolchain unavailable in this worker environment, so compile/runtime verification remains pending

## Current Limitations
- no persistent local cache or offline store yet
- no authentication flow (out of scope for current personal MVP)
- push notification deep-link handling is still deferred

## Next Hardening Targets
- APP-005: push notification deep-link handling implementation and tests
- QA-003: regression review for BE-003, APP-004, and OPS-004 integration
