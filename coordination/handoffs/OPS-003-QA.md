## Task
- id: OPS-003
- owner: signal-desk-qa
- status: pass

## QA Scope Reviewed
- branch: `main` at `97599fb`
- files reviewed:
  - `infra/local/docker-compose.yml`
  - `docs/ops/deploy-runbook.md`
  - `docs/ops/operations-checklist.md`
  - `coordination/handoffs/OPS-003.md`

## Findings
1. OPS-003 acceptance criteria are satisfied.
- one-time bootstrap is separated into `jobs-bootstrap`.
- recurring `jobs` now runs `evaluate-alerts` only.
- runbook and checklist now document `ps -a jobs-bootstrap` for exit-code verification.

## QA Commands Run
- `docker compose -f .\infra\local\docker-compose.yml --env-file .\infra\local\.env config`
- `docker compose -f .\infra\local\docker-compose.yml --env-file .\infra\local\.env down`
- `docker compose -f .\infra\local\docker-compose.yml --env-file .\infra\local\.env up -d --build`
- `docker compose -f .\infra\local\docker-compose.yml --env-file .\infra\local\.env ps -a jobs-bootstrap`
- `docker compose -f .\infra\local\docker-compose.yml --env-file .\infra\local\.env logs jobs-bootstrap --tail 80`
- `docker compose -f .\infra\local\docker-compose.yml --env-file .\infra\local\.env logs jobs --tail 80`
- `docker compose -f .\infra\local\docker-compose.yml --env-file .\infra\local\.env ps`
- `Invoke-RestMethod "http://127.0.0.1:8000/healthz"`
- `Invoke-RestMethod "http://127.0.0.1:8000/v1/dashboard" | ConvertTo-Json -Depth 4`

## Verdict
- `pass`

## Next Step
- keep this runtime change in the combined `QA-002` release note
