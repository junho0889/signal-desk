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

## APP-004 Audit Follow-Up
- fixed mock cursor fidelity to avoid repeated-page loops:
  - mock cursors now encode page offsets (`kw:<offset>`, `al:<offset>`)
  - legacy cursors (`kw_page_2`, `al_page_2`) are still accepted for compatibility
- tightened empty-state behavior on Home, Ranking, Watchlist, and Alerts:
  - stale-data banner remains visible even when list payloads are empty
  - pull-to-refresh uses `AlwaysScrollableScrollPhysics` so refresh works with short/empty content

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
- `Get-ChildItem app/mobile/lib/features -Recurse -Filter *.dart | Select-String -Pattern 'AlwaysScrollableScrollPhysics|No .*data is available|No watchlist items are being tracked yet'`
- `Get-ChildItem app/mobile/lib/core/network -Recurse -Filter *.dart | Select-String -Pattern '_parseOffsetCursor|_nextOffsetCursor|kw_page_2|al_page_2|next_cursor'`

Outcome:
- all commands blocked with `flutter : The term 'flutter' is not recognized ...`
- static checks confirm empty-state/refresh wiring and mock cursor parsing helpers are present
- SDK/toolchain unavailable in this worker environment, so compile/runtime verification remains pending

## APP-005 Language Toggle
- added a lightweight app-wide language mode controller (`AppLanguageController`) with no external localization package
- toggle entrypoint is in the shared shell app bar (`KO` / `EN`) and applies across all routes
- mode behavior is session-only in this implementation (not persisted across full app restart)

Localization coverage in APP-005:
- app bar titles and bottom navigation labels
- shell-level language toggle label/tooltip
- loading, empty, error, retry, and refresh state text in `LoadableView`
- freshness labels/messages in `DataFreshnessBanner`
- key MVP screen chrome and actions on Home, Ranking, Detail, Watchlist, Alerts
  - section headers
  - key field labels
  - pagination footer labels (`Load More`, retry, end-of-results)
  - watchlist action button and snackbar feedback

APP-004 behavior preservation notes:
- existing cursor pagination flow remains intact for Ranking and Alerts
- stale-data thresholds and rendering paths remain intact
- no backend or ops contract changes

## Verification Status (APP-005 Session)
Commands attempted in `app/mobile`:
- `E:\source\signal-desk\flutter\bin\flutter.bat --version`
- `E:\source\signal-desk\flutter\bin\flutter.bat devices`
- `E:\source\signal-desk\flutter\bin\flutter.bat pub get`
- `E:\source\signal-desk\flutter\bin\flutter.bat analyze`
- `E:\source\signal-desk\flutter\bin\flutter.bat test`
- `E:\source\signal-desk\flutter\bin\flutter.bat run -d chrome --dart-define=SIGNALDESK_USE_MOCK=true --no-resident`
- `E:\source\signal-desk\flutter\bin\flutter.bat run -d windows --dart-define=SIGNALDESK_USE_MOCK=true --no-resident`

Outcome:
- Flutter SDK detected: `Flutter 3.41.4` / `Dart 3.11.1`
- devices detected: `windows`, `chrome`, `edge`
- `pub get`: success
- `analyze`: success (`No issues found!`)
- `test`: success (`app shell language toggle switches home chrome`, `All tests passed!`)
- `run -d chrome ... --no-resident`: launch smoke succeeded (`Waiting for connection from debug service on Chrome...`, `Application finished.`)
- `run -d windows ... --no-resident`: expected failure in this repo because Windows desktop project is not configured

## Current Limitations
- no persistent local cache or offline store yet
- no authentication flow (out of scope for current personal MVP)
- push notification deep-link handling is still deferred

## Next Hardening Targets
- APP-006: push notification deep-link handling implementation and tests
- QA-003: regression review for BE-003, APP-004, and OPS-004 integration
