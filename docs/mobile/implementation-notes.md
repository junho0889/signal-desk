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
- APP-005: Korean and English toggle support for shell-level UI and core chrome
- QA-002: regression review for the combined OPS-003 and APP-003 changes

## APP-006 Planning Addendum (2026-03-08)
APP-006 is planning-only. No feature code changes are included in this task.

### Objective
Define how chart surfaces, trust/freshness UX, and multilingual analytics should integrate into the mobile app without changing frozen contracts early.

### Stable Inputs (Ready For Implementation Design)
- current `v1` fields: `timeseries[]`, `confidence`, `risk_flags`, `is_alert_eligible`, `generated_at`, `published_at`, `triggered_at`
- existing app architecture: repository + loadable controller/view patterns from APP-003
- list behavior baseline from APP-004 and language-mode baseline from APP-005 (once merged)

### Open Inputs (Do Not Freeze Yet)
- chart/card interaction specs from DESIGN-002
- storage/read-model field publication from BE-004
- explanation and contribution structures from MODEL-001
- contradiction, coverage, and trust-summary output shape from TRUST-001

### Planned Implementation Sequence (Post-Planning)
1. align screen-level extension points to APP-004 and APP-005 baselines
2. ship chart surfaces using current detail timeseries payloads
3. standardize trust and freshness surfaces using current fields
4. adopt additive payload fields only after upstream contracts are explicitly frozen
5. run QA regression for scan speed, null-state rendering, and risk visibility

### Contract Safety Rules For APP-006 Follow-Up
- no rename/remove changes to `v1` fields or enum literals
- additive payload candidates stay documented as `open` until backend/trust/model lanes freeze names
- multilingual support localizes UI labels first; transport literals remain canonical until an approved localization contract exists

## APP-007 Implementation Contract (Planning Output)
This section is the execution contract for APP-007. Implement only this scope unless a new planning task updates it.

### Required Package Edits
- `app/mobile/pubspec.yaml`
  - add `flex_color_scheme`
  - add `fl_chart`
  - add `flutter_localizations` (SDK)
  - add `intl`
- no other package additions in APP-007

### Required File Targets
- `app/mobile/lib/src/app.dart`
  - replace ad hoc seed-color theme setup with tokenized Material 3 theme wiring
  - connect localization delegates and locale selection to APP-005 language mode source
- `app/mobile/lib/features/shared/signal_desk_shell.dart`
  - apply premium shell spacing/action hierarchy rules and stable stale/retry surface slots
- `app/mobile/lib/features/home/home_screen.dart`
- `app/mobile/lib/features/ranking/ranking_screen.dart`
- `app/mobile/lib/features/detail/keyword_detail_screen.dart`
- `app/mobile/lib/features/watchlist/watchlist_screen.dart`
- `app/mobile/lib/features/alerts/alerts_screen.dart`
  - migrate these screens to the shared component contract without changing repository calls

### Required Shared Component Layer
Create and use a shared component package for APP-007 shell work:
- `SignalDeskMetricRow`
- `SignalDeskTrustStrip`
- `SignalDeskFreshnessBadge`
- `SignalDeskTrendChartCard`
- `SignalDeskRiskCallout`
- `SignalDeskSectionCard`
- `SignalDeskStateSurface`

### Hard Guardrails
- do not change `app/mobile/lib/core/network/*`
- do not change `app/mobile/lib/core/models/*` payload structures
- do not change API endpoint contracts or enum literals
- do not add design patterns not listed in this APP-007 contract
- if a required field is missing from `v1`, render placeholder state instead of inventing data

### APP-007 Verification Baseline
- `cd app/mobile`
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- runtime smoke in both language modes with current preview target:
  - verify no clipping/overflow in Korean and English on Home, Ranking, Detail, Watchlist, Alerts
  - verify trust/freshness cues remain visible in loading, success, stale, and error states
