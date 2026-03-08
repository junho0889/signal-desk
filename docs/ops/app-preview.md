# App Preview

## Purpose
Make mobile preview and verification repeatable on Flutter-capable machines without changing global Windows settings from repo-owned workflows.

## Machine Prerequisites
These are operator-managed prerequisites, not repo automation steps:
- Flutter SDK installed and reachable through `flutter` or `SIGNALDESK_FLUTTER_BIN`
- Android Studio plus an emulator, or a USB-connected Android device with developer mode enabled
- Docker Desktop running when previewing against the live local API
- optional desktop or web toolchain already enabled by the operator if `chrome` or `windows` preview is required

The repo workflow must not call `flutter config`, edit PATH, or generate machine-wide Windows settings.

## Repo-Owned Helper
Use `scripts/orchestrator/mobile-preview.ps1` to keep preview and verification commands consistent.

Run it through `powershell -ExecutionPolicy Bypass -File ...` so the session can execute the helper without changing machine-wide execution policy settings.

The helper supports three commands:
- `doctor`: print the full preflight report and fail once with every current blocker category
- `verify`: require a clean preflight, then run `flutter pub get`, `flutter analyze`, and `flutter test`
- `run`: require a clean preflight, rerun `verify`, and then launch `flutter run` with the correct SignalDesk defines

The helper supports two runtime modes:
- `mock`: forces `SIGNALDESK_USE_MOCK=true`
- `live`: forces `SIGNALDESK_USE_MOCK=false` and checks `GET /healthz` on the configured API base URL before launch

## Preflight Categories
`doctor` reports all relevant categories in one pass so a future session does not have to discover blockers one by one:
- `app-path`
- `platform-scaffold`
- `flutter`
- `devices`
- `device-selection`
- `api-mode` or `api-health`

`doctor` exits non-zero when any blocker exists.

## Ready-Now Sequence
Use this sequence on the active mobile worktree as soon as Flutter and the required platform scaffold exist.

1. run `doctor` in `mock` mode for the intended target
2. if `doctor` is clean, run `verify` in `mock` mode
3. run `run` in `mock` mode on the exact device you want to smoke
4. start the local Docker stack from `docs/ops/deploy-runbook.md`
5. rerun `doctor` in `live` mode
6. if `doctor` is clean, run `verify` in `live` mode
7. run `run` in `live` mode on the same device and capture the result in the handoff

## Copy-Paste Commands
Replace the app path and device id with the active mobile session values.

Mock preflight:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\orchestrator\mobile-preview.ps1 `
  -Command doctor `
  -Mode mock `
  -Target android `
  -AppPath E:\source\signal-desk-worktrees\app-004\app\mobile `
  -DeviceId emulator-5554
```

Mock verification:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\orchestrator\mobile-preview.ps1 `
  -Command verify `
  -Mode mock `
  -Target android `
  -AppPath E:\source\signal-desk-worktrees\app-004\app\mobile `
  -DeviceId emulator-5554
```

Mock Android run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\orchestrator\mobile-preview.ps1 `
  -Command run `
  -Mode mock `
  -Target android `
  -AppPath E:\source\signal-desk-worktrees\app-004\app\mobile `
  -DeviceId emulator-5554
```

Live preflight:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\orchestrator\mobile-preview.ps1 `
  -Command doctor `
  -Mode live `
  -Target android `
  -AppPath E:\source\signal-desk-worktrees\app-004\app\mobile `
  -ApiBaseUrl http://127.0.0.1:8000 `
  -DeviceId emulator-5554
```

Live verification and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\orchestrator\mobile-preview.ps1 `
  -Command verify `
  -Mode live `
  -Target android `
  -AppPath E:\source\signal-desk-worktrees\app-004\app\mobile `
  -ApiBaseUrl http://127.0.0.1:8000 `
  -DeviceId emulator-5554

powershell -ExecutionPolicy Bypass -File .\scripts\orchestrator\mobile-preview.ps1 `
  -Command run `
  -Mode live `
  -Target android `
  -AppPath E:\source\signal-desk-worktrees\app-004\app\mobile `
  -ApiBaseUrl http://127.0.0.1:8000 `
  -DeviceId emulator-5554
```

## Target Rules
- `android` is the primary target for release-relevant smoke
- `chrome` is acceptable for fast layout review only if the mobile worktree already contains a `web/` folder
- `windows` is acceptable for layout review only if the mobile worktree already contains a `windows/` folder
- `run` must not generate missing platform folders; if `android/`, `web/`, or `windows/` is missing, treat that as a repo blocker and hand it back to the mobile owner
- `run` requires an explicit `-DeviceId` for `android` so emulator choice is deterministic across sessions

## Verification Checklist
Record each item as `pass` or `blocked`:
- mock `doctor`
- mock `verify`
- mock `run`
- live `doctor`
- live `verify`
- live `run`

When a run succeeds, also record:
- app worktree path
- mode (`mock` or `live`)
- target and device id
- whether dashboard, ranking, detail, watchlist, and alerts loaded as expected
- screenshots or a short screen-by-screen smoke summary

## Blocker Reporting Format
When a step blocks, copy the helper output and summarize blocker classes in the handoff:
- missing Flutter SDK
- missing target platform scaffold
- missing emulator or device
- missing explicit Android device selection
- unreachable live API

Use this structure:

```text
command: <exact command>
mode: <mock|live>
target: <android|chrome|windows>
result: blocked
blockers:
- <category>: <message>
- <category>: <message>
```

## Current Repo Blocker To Expect
The current `app/mobile` tree in this repo snapshot does not include generated Flutter platform folders. On a Flutter-capable machine:
- `doctor` should report `platform-scaffold` as a blocker immediately
- `verify` and `run` should remain blocked until the owned mobile worktree contains the required platform scaffold for the selected target
