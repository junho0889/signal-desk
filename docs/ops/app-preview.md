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
- `doctor`: validate prerequisites and report explicit blockers
- `verify`: run `flutter pub get`, `flutter analyze`, and `flutter test`
- `run`: perform `verify` and then launch `flutter run` with the correct SignalDesk defines

The helper supports two runtime modes:
- `mock`: forces `SIGNALDESK_USE_MOCK=true`
- `live`: forces `SIGNALDESK_USE_MOCK=false` and checks `GET /healthz` on the configured API base URL before launch

## Recommended Flow
1. point the helper at the active mobile worktree, not an old preview branch copy
2. run `doctor` in `mock` mode to confirm Flutter and device visibility
3. run `verify` in `mock` mode
4. run `run` in `mock` mode on an Android emulator or device for first UI smoke
5. start the local Docker stack from `docs/ops/deploy-runbook.md`
6. rerun `doctor` and `verify` in `live` mode
7. run `run` in `live` mode against the same target and capture the outcome in the handoff

## Example Commands
Mock verification from the current mobile task worktree:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\orchestrator\mobile-preview.ps1 `
  -Command doctor `
  -Mode mock `
  -AppPath E:\source\signal-desk-worktrees\app-004\app\mobile

powershell -ExecutionPolicy Bypass -File .\scripts\orchestrator\mobile-preview.ps1 `
  -Command verify `
  -Mode mock `
  -AppPath E:\source\signal-desk-worktrees\app-004\app\mobile
```

Mock Android preview on a known emulator:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\orchestrator\mobile-preview.ps1 `
  -Command run `
  -Mode mock `
  -AppPath E:\source\signal-desk-worktrees\app-004\app\mobile `
  -Target android `
  -DeviceId emulator-5554
```

Live verification against the local API:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\orchestrator\mobile-preview.ps1 `
  -Command verify `
  -Mode live `
  -AppPath E:\source\signal-desk-worktrees\app-004\app\mobile `
  -ApiBaseUrl http://127.0.0.1:8000

powershell -ExecutionPolicy Bypass -File .\scripts\orchestrator\mobile-preview.ps1 `
  -Command run `
  -Mode live `
  -AppPath E:\source\signal-desk-worktrees\app-004\app\mobile `
  -ApiBaseUrl http://127.0.0.1:8000 `
  -Target android `
  -DeviceId emulator-5554
```

## Target Rules
- `android` is the primary target for release-relevant smoke
- `chrome` is acceptable for fast layout review only if the mobile worktree already contains a `web/` folder
- `windows` is acceptable for layout review only if the mobile worktree already contains a `windows/` folder
- `run` must not generate missing platform folders; if `android/`, `web/`, or `windows/` is missing, treat that as a repo blocker and hand it back to the mobile owner
- `run` requires an explicit `-DeviceId` for `android` so emulator choice is deterministic across sessions

## Current Repo Blocker To Expect
The current `app/mobile` tree in this repo snapshot does not include generated Flutter platform folders. On a Flutter-capable machine:
- `verify` can still run because it only needs the Dart and Flutter toolchain
- `run` should fail fast with an explicit blocker until the owned mobile worktree contains the required platform scaffold for the selected target

## Evidence And Handoff Requirements
Record the exact helper commands used and whether they passed or blocked.

When a run is blocked, state which class of blocker occurred:
- Flutter SDK not installed or not on PATH
- no emulator or device available for the requested target
- target platform scaffold missing from the mobile worktree
- live API health check failed

When a run succeeds, include:
- app worktree path
- mode (`mock` or `live`)
- target and device id
- screenshots or a short screen-by-screen smoke summary
