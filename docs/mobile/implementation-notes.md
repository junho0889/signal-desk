# Mobile Implementation Notes

## Scope Delivered
APP-003 hardens the executable Flutter baseline under `app/mobile/` with:
- shared repository layer over the frozen BE-001 API client
- reusable loading, error, empty, and retry state controller/view primitives
- feature screens updated to use consistent refresh and retry behavior
- watchlist mutation feedback that now reports request failures explicitly

## Structure
- `app/mobile/lib/main.dart`: app entrypoint
- `app/mobile/lib/src/app.dart`: `MaterialApp`, route registration, shared API client and repository instances
- `app/mobile/lib/core/repositories/signaldesk_repository.dart`: repository layer wrapping the typed API client
- `app/mobile/lib/core/state/loadable_controller.dart`: reusable async state controller for first load and refresh paths
- `app/mobile/lib/features/shared/loadable_view.dart`: shared loading/error/empty/retry surface
- `app/mobile/lib/features/*`: screen implementations updated to consume repository + controller flow

## Runtime Behavior
- Home, Ranking, Detail, Watchlist, and Alerts now share the same first-load error and retry pattern
- filter changes on Ranking and Alerts trigger controller refresh instead of rebuilding ad hoc `FutureBuilder` trees
- manual pull-to-refresh is available on list/detail surfaces with scrollable content
- watchlist add failures now surface user-visible error feedback instead of silently failing

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
6. `flutter run`

## Verification Status
- code-level hardening completed in repo
- Flutter runtime verification is still environment-dependent until Flutter SDK is available in this session

## Current Limitations
- no persistent local cache or offline store yet
- pagination and cursor-driven stale-data handling are not implemented yet
- no authentication flow (out of scope for current personal MVP)
- push notification deep-link handling is still deferred

## Next Hardening Targets
- APP-004: pagination and stale-data strategy for production-like list behavior
- APP-005: push notification deep-link handling implementation and tests
- QA-002: regression review for the combined OPS-003 and APP-003 changes

## APP-007 Premium Publishing Baseline (2026-03-08)
APP-007 implemented the premium mobile shell baseline for Home, Ranking, Detail, Watchlist, and Alerts with frozen spacing, typography, trust/freshness cues, chart shells, and first-class state surfaces.

### What Changed
- theme and localization foundation:
  - migrated app theme to `flex_color_scheme` with Material 3 tokenized shape/typography defaults
  - added app-level locale toggle (`EN/KO`) with localizations delegate wiring
- package baseline:
  - added `flutter_localizations`, `intl`, `flex_color_scheme`, `fl_chart`
- shared UI contract layer:
  - added context rail, section card, metric row, trust strip, freshness badge, risk callout, trend chart card, and state surface components
  - migrated shared loading/error/empty handling to premium state cards with stale-data treatment
- screen-shell upgrades:
  - Home: premium top-keyword cards with trust/freshness, sectors, and alert sections
  - Ranking: fixed-row metric layout with stable ordering and period chips
  - Detail: top-fold movement/trust/freshness, risk callout, trend chart shell, dimension contributions, and related context sections
  - Watchlist: upgraded keyword/stock sections with consistent row geometry
  - Alerts: severity chips, stable row structure, and trust/freshness-aware cards

### Verification (APP-007)
- `E:\source\signal-desk\flutter\bin\flutter.bat pub get`
  - passed after aligning `intl` to SDK-pinned `0.20.2`
- `E:\source\signal-desk\flutter\bin\flutter.bat analyze`
  - passed with no issues
- `E:\source\signal-desk\flutter\bin\flutter.bat test`
  - passed (`test/app_smoke_test.dart`)
- `E:\source\signal-desk\flutter\bin\flutter.bat run -d chrome --dart-define=SIGNALDESK_USE_MOCK=true --no-resident`
  - launched and finished successfully
  - runtime reported: `This application is not configured to build on the web. To add web support to a project, run flutter create .`
  - smoke still reached `Application finished` on Chrome in this environment
