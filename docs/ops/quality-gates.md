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
- use `scripts/orchestrator/mobile-preview.ps1` or equivalent explicit commands when verifying mobile preview sessions
- record whether the check was run in `mock` or `live` mode
- `live` mode verification must confirm API health before claiming preview success
- if preview smoke is blocked, record the exact blocker class: missing Flutter SDK, missing emulator or device, missing target platform scaffold in the mobile worktree, or unreachable live API
- blocked preview is acceptable only when the handoff and resume note show the exact command and blocker outcome

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
