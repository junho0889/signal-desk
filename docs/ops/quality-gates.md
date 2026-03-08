# Quality Gates

## Worker Requirements
- every task must list required verification before work starts
- every task handoff must include exact commands and outcomes
- if a check cannot run, the blocker must be explicit
- fixes are not complete until the relevant failing case is re-checked

## Minimum Verification Types
- docs-only work: consistency review against dependent docs
- backend code: lint, unit tests, integration tests where feasible
- mobile code: analyzer, widget tests, manual smoke flow where feasible
- infra changes: configuration review and service startup check where feasible
- QA review: defect-focused recheck on integrated or reviewable work

## Collector Test-DB Gate
- use a separate collector project such as `signaldesk-collector-test`, never the main app stack project
- record exact boot, reset, fixture-ingest, restart, and SQL inspection commands
- local collector smoke must be fixture-driven, not dependent on ambient live-source data
- the minimum acceptable evidence set is:
  - config validation for `infra/collector/docker-compose.yml`
  - `collector-db` startup status
  - one fixture ingest run
  - one re-run after restart
  - SQL proof for spool rows
  - SQL proof for metadata completeness and quality states
- if implementation changes the required command surface, update the ops docs before QA review
- blocked collector verification is acceptable only when the exact missing asset or contract gap is recorded, such as:
  - missing `infra/collector/docker-compose.yml`
  - missing `collector-runner` fixture entrypoint
  - missing test-db tables or compatibility views
  - missing frozen backend/storage handoff for a required query surface

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
