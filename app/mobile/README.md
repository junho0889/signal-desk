# SignalDesk Mobile (APP-002)

This folder contains the first executable Flutter shell and BE-001 API wiring baseline.

## Scope
- app routes: Home, Ranking, Detail, Watchlist, Alerts
- typed API client for `/v1` endpoints in `docs/backend/api-contract.md`
- placeholder UI with contract-shaped data loading

## Run
1. Install Flutter SDK and Android toolchain.
2. `cd app/mobile`
3. `flutter pub get`
4. `flutter run`

## Notes
- Current implementation favors contract safety over visual polish.
- See `docs/mobile/implementation-notes.md` for limitations and next steps.
