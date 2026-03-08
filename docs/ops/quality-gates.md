# Quality Gates

## Worker Requirements
- every task must list required verification before work starts
- every task handoff must include exact commands and outcomes
- if a check cannot run, the blocker must be explicit
- fixes are not complete until the relevant failing case is re-checked

## Minimum Verification Types
- docs-only work: consistency review against dependent docs
- backend code: lint, unit tests, integration tests where feasible
- mobile code: `flutter pub get`, `flutter analyze`, `flutter test`, and preview smoke where feasible
- infra changes: configuration review and service startup check where feasible
- QA review: defect-focused recheck on integrated or reviewable work

## Flutter Preview Gate
- use `scripts/orchestrator/mobile-preview.ps1` when verifying mobile preview sessions
- invoke the helper with `powershell -ExecutionPolicy Bypass -File ...`; do not change Windows execution policy globally from repo workflow
- run `doctor` before `verify` or `run`
- record whether the check was run in `mock` or `live` mode
- for Android preview, record the exact `-DeviceId` used
- `live` mode verification must confirm API health before claiming preview success
- record each stage separately: `mock doctor`, `mock verify`, `mock run`, `live doctor`, `live verify`, `live run`
- if preview smoke is blocked, record every blocker category the helper reported, not just the first failure
- blocked preview is acceptable only when the handoff and resume note show the exact command, target, mode, and blocker output

## Blocker Classes
- missing Flutter SDK
- missing target platform scaffold in the mobile worktree
- missing emulator or device
- missing explicit Android device selection
- unreachable live API

## Debugging Rules
- reproduce before changing behavior when possible
- record the failing command, symptom, and scope in the handoff
- after a fix, rerun the failing check first, then the broader safety checks
- do not mark a task done based only on code inspection when execution is practical

## Integration Rules
- if a task changes a contract, alert all dependent tasks in the handoff
- orchestrator reviews integration risks before releasing the next dependent task
- unresolved integration risks remain open tasks, not hidden assumptions
- QA can reopen a task if verification is insufficient or a regression is found
