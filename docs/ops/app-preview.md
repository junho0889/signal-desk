# App Preview

## Purpose
Define a repeatable way to run the mobile app against live local API data.

## Live Integration Baseline
- backend/API must run first (`infra/local/docker-compose.yml`)
- mobile app must run with mock disabled:
  - `--dart-define=SIGNALDESK_USE_MOCK=false`
- current live preview reads the central app DB/API data path
- collector spool data is not app-visible until collector-intake contracts are implemented (BE-005/BE-008/BE-009)

## Commands (Windows PowerShell)
1. Start backend:
- `Set-Location E:\source\signal-desk`
- `docker compose --env-file .\infra\local\.env -f .\infra\local\docker-compose.yml up -d`
- `docker compose --env-file .\infra\local\.env -f .\infra\local\docker-compose.yml ps`

2. Verify API:
- `Invoke-RestMethod "http://127.0.0.1:8000/healthz"`
- `Invoke-RestMethod "http://127.0.0.1:8000/v1/dashboard"`

3. Run app:
- `Set-Location E:\source\signal-desk\app\mobile`
- `flutter pub get`
- `flutter devices`

4. Run app with live API:
- web server:
  - `flutter run -d web-server --dart-define=SIGNALDESK_USE_MOCK=false --dart-define=SIGNALDESK_API_BASE_URL=http://127.0.0.1:8000 --web-port=7357`
- chrome:
  - `flutter run -d chrome --dart-define=SIGNALDESK_USE_MOCK=false --dart-define=SIGNALDESK_API_BASE_URL=http://127.0.0.1:8000`
- android emulator:
  - `flutter run -d emulator-5554 --dart-define=SIGNALDESK_USE_MOCK=false --dart-define=SIGNALDESK_API_BASE_URL=http://10.0.2.2:8000`

## Base URL Rules
- web/chrome/windows preview on same host: `http://127.0.0.1:8000`
- Android emulator: `http://10.0.2.2:8000`
- physical Android device: `http://<developer-pc-lan-ip>:8000`

## Verification Checklist
- dashboard/ranking/detail/watchlist/alerts load from live API
- watchlist add or remove succeeds and refresh reflects changes
- alerts list returns server data (not static mock payload)
- API errors show retry-capable UI state without app crash
