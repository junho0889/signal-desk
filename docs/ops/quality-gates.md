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
- use the concrete `COL-003` command surface under `infra/collector/`, never the main app stack project
- record exact boot, bootstrap, fixture-ingest, shipper, restart, and SQL inspection commands
- local collector smoke must be fixture-driven, not dependent on ambient live-source data
- the minimum acceptable evidence set is:
  - `docker compose ... config` for `infra/collector/docker-compose.yml`
  - `collector-db` startup status
  - one `collector-bootstrap` run
  - one fixture ingest run
  - one `collector-shipper` run when shipper simulation is part of the smoke
  - one re-run after restart
  - SQL proof from `infra/collector/queries/spool-evidence.sql`
  - SQL proof from `infra/collector/queries/spool-idempotency.sql`
- if implementation changes the required command surface, update the ops docs before QA review
- blocked collector verification is acceptable only when the exact missing asset or contract gap is recorded, such as:
  - missing `infra/collector/docker-compose.yml`
  - missing `collector-bootstrap`, `collector-runner`, or `collector-shipper` entrypoints
  - missing `spool-evidence.sql` or `spool-idempotency.sql`
  - runtime drift between the local smoke path and the Pi deployment path

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
