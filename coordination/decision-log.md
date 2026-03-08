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

### DEC-014
- Decision: run Korean language toggle work as `APP-005` in a fresh `codex/app-005` worktree instead of reusing the currently dirty `codex/app-004` worktree
- Reason: the feature is a new mobile scope item, and a clean worktree keeps orchestration, handoff ownership, and verification boundaries clearer for the worker

### DEC-015
- Decision: do not merge or advance release work until `APP-005` has both a worker handoff and explicit QA evidence on `main`
- Reason: the language-toggle wave is now part of the supervised mobile release surface, so release decisions need both implementation evidence and a QA verdict in the repo

### DEC-016
- Decision: separate the next architecture wave into collector, storage, model, trust, design, and app-integration lanes
- Reason: SignalDesk is moving from MVP scaffolding toward a real information platform, and these domains now need distinct ownership with clean contracts

### DEC-017
- Decision: use Raspberry Pi 4B 8GB as a collector-only node with local spool plus central transfer, while keeping canonical storage and ranking on the central host
- Reason: collection needs 24/7 uptime and retry resilience, but the Pi should not become the primary database or heavy-compute node

### DEC-018
- Decision: lock user-facing worker names in `coordination/thread-registry.md` and reuse those exact labels in orchestration updates
- Reason: the user is coordinating multiple long-lived threads manually, so inconsistent naming creates avoidable confusion

### DEC-019
- Decision: do not use RabbitMQ in collector v1; use a local PostgreSQL spool with explicit delivery state instead
- Reason: the immediate requirement is durable offline buffering, replayability, and clear delivery auditing while the main server can be offline for long periods

### DEC-020
- Decision: build the collector stack first on the current PC as a separate Docker Compose group, then package the same runtime later for Ubuntu on Raspberry Pi 4B 8GB
- Reason: this shortens feedback loops during development while keeping the eventual deployment target unchanged

### DEC-021
- Decision: assume central host IP `192.168.0.200` and support collector-side retention for up to 30 days
- Reason: the main server is not guaranteed to run continuously, so collector buffering and delayed shipping must be part of the baseline architecture

### DEC-018
- Decision: treat `APP-005` and `QA-004` branch outputs as supervision input only until their evidence is accepted on `main`, and keep `APP-006` parked until its upstream handoffs exist
- Reason: branch-resident artifacts do not satisfy the release gate by themselves, and starting `APP-006` early creates avoidable overlap in the mobile lane

### DEC-022
- Decision: use Flutter Material 3 with SignalDesk-owned design tokens and component rules as the primary mobile UI foundation, with `fl_chart` for chart rendering and `flex_color_scheme` for theme shaping, rather than treating a third-party UI kit as the app shell
- Reason: the product needs a deliberate, stable visual system for ranking, trust, evidence, and multilingual surfaces, and mixing generic kit patterns would make the app look inconsistent and amateur

### DEC-023
- Decision: run premium mobile polish as an ordered design wave of `DESIGN-002` -> `APP-006` -> `APP-007` -> `QA-005`
- Reason: design rules, publishing constraints, implementation, and UI review must be frozen in sequence so the ranking surfaces stay consistent and explainable

### DEC-024
- Decision: make the first production model system explainable-first and split it into an online publish pipeline plus a separate offline research lane
- Reason: SignalDesk needs reproducible ranking, trust-aware alerts, and UI-ready explanations before it needs deep learning; coupling production ranking directly to experimental models would make failures harder to debug and trust

### DEC-025
- Decision: treat model output as a publish bundle of feature snapshots, ranking scores, explanation artifacts, evaluation snapshots, and immutable publish runs instead of a single opaque score row
- Reason: the app, QA, and future model training all need lineage and per-run evidence, not just one final number

### DEC-026
- Decision: make collector implementation metadata-first and quality-gated before introducing any AI-based filtering
- Reason: SignalDesk needs durable, inspectable, high-quality raw evidence more urgently than model-assisted filtering, and metadata completeness, source identity, timestamps, and dedup state are enough to reject a large class of bad payloads

### DEC-027
- Decision: require a local collector test database and fixture-backed ingest smoke before calling the collector runtime ready
- Reason: collection reliability is a core project risk, so the first implementation wave must prove that payloads and metadata actually land in a replayable spool store with exact query evidence

