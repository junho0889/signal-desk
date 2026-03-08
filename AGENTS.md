## Project
- Product name: `SignalDesk`
- Product type: personal Android app for investment keyword, theme, and sector intelligence
- Primary goal: surface explainable market signals from news, search trends, disclosures, and price reaction

## Team Model
- Treat each Codex session as a specialist worker inside one repo.
- Use the repo as the communication bus. Do not assume worker-to-worker memory.
- The orchestrator session owns sequencing, dispatch, supervision, and integration review.
- Read `coordination/working-agreement.md` before starting substantial work.
- Claim tasks in `coordination/tasks.yaml` before editing files.
- Read the task dispatch in `coordination/dispatches/` when it exists.
- Read `coordination/resume/<TASK-ID>.md` when resuming a task after interruption or context loss.
- Write handoff notes in `coordination/handoffs/` when pausing or finishing work.
- Record product or architecture decisions in `coordination/decision-log.md`.

## Roles
- `signal-desk-orchestrator`: breaks work down, assigns ownership, protects contracts, tracks dependencies, and reviews worker outputs
- `signal-desk-product`: maintains scope, PRD, priorities, and acceptance criteria
- `signal-desk-data`: owns ingestion, normalization, entity mapping, and scoring logic
- `signal-desk-collector`: owns Raspberry Pi collector topology, source adapters, spool queues, retry policy, and raw payload transfer
- `signal-desk-storage`: owns raw, normalized, feature, trust, and lineage storage design plus retention and access rules
- `signal-desk-backend`: owns API, database schema, auth, and notification triggers
- `signal-desk-model`: owns ranking features, model roadmap, evaluation strategy, and score publishing rules
- `signal-desk-trust`: owns source credibility, misinformation-risk heuristics, contradiction handling, and trust score policy
- `signal-desk-mobile`: owns Flutter app, local state, API integration, and push UX
- `signal-desk-design`: owns information hierarchy, screen flows, chart patterns, and the MZ-friendly visual system
- `signal-desk-ops`: owns deployment, secrets, monitoring, schedules, and release readiness
- `signal-desk-qa`: owns verification plans, defect reporting, regression checks, and release readiness review

## Source Of Truth
- Product intent: `docs/product/vision.md`
- MVP scope: `docs/product/mvp-scope.md`
- System design: `docs/architecture/system-overview.md`, `docs/architecture/intelligence-platform-topology.md`
- Data logic: `docs/data/source-catalog.md`, `docs/data/keyword-scoring-v0.md`
- API contract: `docs/backend/api-contract.md`
- DB model: `docs/backend/db-schema.md`, `docs/backend/storage-expansion-outline.md`
- DB security: `docs/backend/postgres-security.md`
- Model and trust: `docs/model/ranking-roadmap.md`, `docs/trust/trust-framework.md`
- UX rules: `docs/design/ui-principles.md`, `docs/design/screen-map.md`, `docs/design/analytics-visual-system.md`
- Operations: `docs/ops/deploy-runbook.md`, `docs/ops/service-model.md`, `docs/ops/local-docker-stack.md`, `docs/ops/quality-gates.md`, `docs/ops/git-worktree-flow.md`, `docs/ops/qa-strategy.md`, `docs/ops/app-preview.md`, `docs/ops/automation-supervisor.md`, `docs/ops/pi-collector-node.md`
- Coordination protocol: `coordination/dispatch-protocol.md`, `coordination/session-prompts.md`, `coordination/checkpoint-policy.md`, `coordination/resume-template.md`
- Setup and install history: `INSTALL-LOG.md`

## Working Rules
- Keep tasks small enough to finish or hand off within one session.
- Do not let multiple workers edit the same file without an explicit handoff.
- Freeze contracts before parallel implementation. Contracts include API shapes, DB schema, event names, and scoring inputs.
- Prefer additive changes and document assumptions in the handoff note.
- If a worker must change a shared contract, update the contract doc first and log the decision.
- Never commit secrets. Use `.env` files outside version control and keep examples in the repo.
- Database access must use least-privilege roles. Application code must never use the PostgreSQL superuser.
- A task is not done until verification commands are run or the blocker is written down explicitly.
- Every substantial source change, feature addition, or defect fix requires a checkpoint commit on the task branch.
- Every meaningful checkpoint must be pushed to the remote branch before the worker pauses, unless push is explicitly blocked and documented.
- Before stopping because of token or context limits, the worker must update the task resume note.
- Orchestrator reviews worker diffs and handoffs before signaling downstream work or completion.
- QA reviews any user-facing or contract-affecting change before final release sign-off.

## Startup Checklist
1. Read `coordination/working-agreement.md`.
2. Review open tasks in `coordination/tasks.yaml`.
3. Read the relevant skill under `.codex/skills/`.
4. Read the task dispatch in `coordination/dispatches/` when present.
5. Read the task resume note in `coordination/resume/` when present.
6. Read only the domain docs required for the assigned task.
7. Update task status and owner before editing.
8. Record verification commands in the handoff before marking done.
