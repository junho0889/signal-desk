## Task
- id: APP-005
- owner: signal-desk-qa
- status: blocked

## QA Scope Reviewed
- branch ref: `codex/app-005` at `1ec49c5`
- commits reviewed:
  - `1ec49c5` APP-005 feat: add app-wide Korean language toggle mode
- worker artifacts:
  - `coordination/handoffs/APP-005.md`
  - `coordination/resume/APP-005.md`
- code and docs:
  - `app/mobile/lib/core/localization/app_localization.dart`
  - `app/mobile/lib/src/app.dart`
  - `app/mobile/lib/features/shared/signal_desk_shell.dart`
  - `app/mobile/lib/features/shared/loadable_view.dart`
  - `app/mobile/lib/features/shared/data_freshness_banner.dart`
  - `app/mobile/lib/features/home/home_screen.dart`
  - `app/mobile/lib/features/ranking/ranking_screen.dart`
  - `app/mobile/lib/features/detail/keyword_detail_screen.dart`
  - `app/mobile/lib/features/watchlist/watchlist_screen.dart`
  - `app/mobile/lib/features/alerts/alerts_screen.dart`
  - `docs/mobile/implementation-notes.md`

## Findings
1. APP-005 does not yet provide sufficient verification evidence for merge or release gating.
- dispatch required `flutter pub get`, `flutter analyze`, `flutter test`, and at least one runtime smoke
- worker and QA reruns of all four Flutter commands returned `flutter-missing`
- no screenshot, browser, or device-runtime artifacts were present in the `app-005` worktree, so Korean toggle behavior is not verified end-to-end

2. Static review shows the Korean toggle wiring is app-wide and reaches the intended MVP surfaces.
- `app.dart:21,46,52-71` introduces `AppLanguageController`, wraps the app in `AppLanguageScope`, and keeps all routed screens under the localization scope
- `signal_desk_shell.dart:43-71` binds the app-bar `KO`/`EN` toggle plus localized bottom-nav labels to `AppLanguageScope`
- `loadable_view.dart:30-71` localizes shared loading, empty, retry, and refresh state text
- `data_freshness_banner.dart:33-47,82-98` localizes freshness labels, messages, and time-unit text
- routed screens consume localized titles and key UI strings:
  - Home: `home_screen.dart:41-48,61,81,143`
  - Ranking: `ranking_screen.dart:93-143,159,180,197,214`
  - Detail: `keyword_detail_screen.dart:47,62,73,89,93,156`
  - Watchlist: `watchlist_screen.dart:41-48,63,77,94,111`
  - Alerts: `alerts_screen.dart:93-143,156-160,179,193,219,228`

3. Korean source strings are not corrupted in the repo.
- QA verified the Korean literals in `app_localization.dart` by reading the file as UTF-8 and inspecting unicode escapes
- the garbled Korean shown in shell `Get-Content` output is terminal-encoding noise, not source-file corruption

## Blocked Checks
- Flutter SDK/toolchain is missing in the current QA environment
- runtime smoke evidence is absent, so visible KO/EN switching behavior is unconfirmed

## QA Commands Run
- `Get-Content E:\source\signal-desk-worktrees\app-005\coordination\handoffs\APP-005.md`
- `Get-Content E:\source\signal-desk-worktrees\app-005\coordination\resume\APP-005.md`
- `git log --oneline --decorate -6`
- `git status --short --branch`
- `git diff --stat d863c84..HEAD`
- `git diff --check d863c84 -- app/mobile docs/mobile/implementation-notes.md`
- `Select-String -Path app\mobile\lib\src\app.dart -Pattern 'AppLanguageController|AppLanguageScope|MaterialApp|HomeScreen|RankingScreen|WatchlistScreen|AlertsScreen|KeywordDetailScreen'`
- `Select-String -Path app\mobile\lib\features\shared\signal_desk_shell.dart -Pattern 'languageToggleTooltip|languageToggleLabel|navHome|navRanking|navWatchlist|navAlerts|controllerOf|stringsOf'`
- `Select-String -Path app\mobile\lib\features\shared\loadable_view.dart -Pattern 'loadingTitle|couldNotLoadTitle|retryAction|refreshAction|noDataTitle|nothingYetTitle|loadingDataMessage|nothingToShowMessage'`
- `Select-String -Path app\mobile\lib\features\shared\data_freshness_banner.dart -Pattern 'freshnessStaleLabel|freshnessFreshLabel|freshnessStaleMessage|freshnessFreshMessage|underOneMinute|minutesLabel|hoursLabel|daysLabel'`
- `Select-String -Path app\mobile\lib\features\home\home_screen.dart,app\mobile\lib\features\ranking\ranking_screen.dart,app\mobile\lib\features\detail\keyword_detail_screen.dart,app\mobile\lib\features\watchlist\watchlist_screen.dart,app\mobile\lib\features\alerts\alerts_screen.dart -Pattern 'strings\.homeTitle|strings\.rankingTitle|strings\.detailTitle|strings\.watchlistTitle|strings\.alertsTitle|strings\.noDashboardData|strings\.noRankingData|strings\.noKeywordDetail|strings\.noWatchlistData|strings\.noAlertsData|strings\.loadMoreAction|strings\.retryAction|strings\.addToWatchlistAction|strings\.addedToWatchlistMessage|strings\.watchlistUpdateFailedMessage|strings\.severityOption|strings\.periodOption|strings\.targetType'`
- `Get-ChildItem -Path E:\source\signal-desk-worktrees\app-005 -Recurse -File -Include *.png,*.jpg,*.jpeg,*.gif,*.mp4,*.webm`
- `if (Get-Command flutter -ErrorAction SilentlyContinue) { flutter pub get } else { 'flutter-missing' }`
- `if (Get-Command flutter -ErrorAction SilentlyContinue) { flutter analyze } else { 'flutter-missing' }`
- `if (Get-Command flutter -ErrorAction SilentlyContinue) { flutter test } else { 'flutter-missing' }`
- `if (Get-Command flutter -ErrorAction SilentlyContinue) { flutter run -d chrome --dart-define=SIGNALDESK_USE_MOCK=true } else { 'flutter-missing' }`
- inline Python UTF-8 inspection of `app_localization.dart` using `unicode_escape`

## Verdict
- `blocked`

## Release Gate
- APP-005 QA evidence is not sufficient to reopen merge or release work yet.

## Next Step
- run APP-005 verification on a Flutter-capable machine:
  - `flutter pub get`
  - `flutter analyze`
  - `flutter test`
  - `flutter run -d chrome --dart-define=SIGNALDESK_USE_MOCK=true`
- capture explicit runtime evidence of:
  - default English shell state
  - KO toggle switching all routed shell chrome and shared states
  - at least one localized screen per route family after toggle
