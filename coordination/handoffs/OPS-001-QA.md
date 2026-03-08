## Task
- id: OPS-001
- owner: signal-desk-qa
- status: pass-with-notes

## QA Scope Reviewed
- branch: `worker/ops-001` (remote and local refs at `927a1c2`)
- commits reviewed:
  - `927a1c2` OPS-001 docs: define deployment and service baseline
- files reviewed:
  - `docs/ops/deploy-runbook.md`
  - `docs/ops/service-model.md`
  - `coordination/handoffs/OPS-001.md`
  - `coordination/resume/OPS-001.md`

## Findings
1. Operational baseline now covers required runbook components.
- startup order, checks, backup/restore, release and rollback paths are documented.

2. Security and least-privilege consistency is preserved.
- role model and localhost/network exposure rules align with postgres security baseline.

3. Docs correctly distinguish current vs target runtime topology.
- current compose state (`postgres` only) is explicit.
- planned `api/jobs` onboarding is documented without contradicting existing infra files.

## Notes (Non-blocking)
- `pass-with-notes` is used because API/jobs runtime checks are documented as target-state checks and cannot yet be executed against current compose.

## QA Commands Run
- `git fetch --all --prune`
- `git log --oneline --decorate worker/ops-001 -5`
- `git show worker/ops-001:docs/ops/deploy-runbook.md`
- `git show worker/ops-001:docs/ops/service-model.md`
- `git show worker/ops-001:coordination/handoffs/OPS-001.md`
- `git show worker/ops-001:coordination/resume/OPS-001.md`
- `git show worker/ops-001:infra/local/docker-compose.yml`
- `git show worker/ops-001:docs/backend/postgres-security.md`

## Verdict
- `pass-with-notes`

## Next Step
- Orchestrator accepts OPS-001 and tracks API/jobs compose onboarding as a follow-up implementation task.
