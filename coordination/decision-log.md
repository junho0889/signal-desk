# Decision Log

## 2026-03-08

### DEC-001
- Decision: start the project in `E:\source\signal-desk`
- Reason: clean repo boundary, easy session onboarding, clear separation from unrelated work

### DEC-002
- Decision: use a file-based coordination model instead of relying on direct worker chat
- Reason: Codex sessions do not share durable memory, so repo documents are the stable communication layer

### DEC-003
- Decision: use `SignalDesk` as the working product name
- Reason: neutral, reusable, and aligned with a dashboard that explains signals rather than promising returns

### DEC-004
- Decision: run backend services with a local Docker stack and PostgreSQL
- Reason: low operational overhead, repeatable local deployment, and clear service boundaries during early development

### DEC-005
- Decision: use least-privilege PostgreSQL roles for app, migration, and readonly access
- Reason: application code should never rely on superuser access and security assumptions must be visible to every worker

### DEC-006
- Decision: use one orchestrator session plus up to three worker sessions for true parallel work
- Reason: this keeps coordination overhead manageable while still allowing real concurrency

### DEC-007
- Decision: use git worktrees instead of separate full clones for local multi-worker execution
- Reason: worktrees reduce disk usage, keep object history shared, and isolate each worker branch safely

### DEC-008
- Decision: require explicit QA review before project completion or release sign-off
- Reason: defects and integration drift should be caught by a dedicated worker rather than assumed away

### DEC-009
- Decision: run the next task wave in the order `REL-001` -> (`OPS-003` and `APP-003`) -> `QA-002`
- Reason: the repo has a complete v1 baseline through `OPS-002`, but release smoke must be recorded first and the known jobs-loop issue should be fixed before broader release confidence work

### DEC-010
- Decision: split one-time runtime bootstrap into `jobs-bootstrap` and keep recurring `jobs` limited to alert evaluation
- Reason: the previous loop reran migration and demo seed during steady-state operation, which blurred restart semantics and reduced confidence for production-like runtime behavior

### DEC-011
- Decision: run the next parallel wave as BE-003, APP-004, and OPS-004, then gate it with QA-003 and REL-002`r
- Reason: notification delivery, mobile pagination/stale-data behavior, and Flutter-capable verification readiness are the highest-value remaining gaps with clean file boundaries for parallel work


### DEC-012
- Decision: represent watchlist alert delivery as an internal notification payload contract with 
one|stdout sink baseline
- Reason: this preserves current alert persistence behavior while creating a stable bridge to future push delivery without prematurely binding the runtime to a specific provider

### DEC-013
- Decision: block `REL-002` until `APP-004` either passes Flutter-capable verification or the orchestrator explicitly accepts that blocker in this log
- Reason: mobile pagination and stale-data changes affect user-facing release confidence, and an undocumented runtime gap is not enough to treat the wave as release-ready

