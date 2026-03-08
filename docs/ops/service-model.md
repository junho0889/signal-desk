# Service Model

## Operating Assumption
SignalDesk is personal-use first.
Prioritize deterministic operations, explainable failures, and low maintenance overhead.

## Runtime Topology
Phase 0 (current):
- `postgres` only in `infra/local/docker-compose.yml`
- private Docker network: `signaldesk-internal`
- host exposure: PostgreSQL bound to `127.0.0.1:${POSTGRES_PORT}` only

Phase 1 (target baseline for MVP runtime):
- `postgres`: durable storage + bootstrap init
- `api`: read-only contract serving over `/v1`
- `jobs`: ingestion + normalization + scoring + alert evaluation
- optional reverse proxy only when remote access is explicitly required

## Service Responsibilities
- `postgres`: persistence, schema constraints, role-based access control
- `api`: serve frozen BE v1 payloads for Home/Ranking/Detail/Watchlist/Alerts
- `jobs`: maintain data freshness and derived snapshots (`as_of_ts` cadence)

## Scheduling Baseline
- scoring/feature build cadence target: every 30 minutes
- alert rule evaluation: server-side after each scoring publish
- daily health summary: at least once per day including freshness and failure counts

## Reliability Targets (MVP)
- API availability during review windows: best effort on single host
- data freshness target: latest snapshot <= 30 minutes old
- alert lag target: within one scoring cycle

## Monitoring Baseline
- container health: `postgres`, `api`, `jobs`
- job outcomes: success/failure count per cycle
- data freshness: latest `keyword_snapshots.as_of_ts`
- API errors: 4xx/5xx rate and top error codes
- push alert delivery failures (when notification service is active)

## Failure Handling
- DB unavailable: stop API/jobs, recover DB first, then resume dependents
- job failure streak >= 2: mark ranking trust degraded and pause release activities
- API contract mismatch: block mobile release until docs and payloads are reconciled

## Security And Access Model
- role separation must remain:
  - `postgres` bootstrap/admin only
  - `signaldesk_migrator` schema ownership/migrations
  - `signaldesk_app` runtime DML
  - `signaldesk_readonly` diagnostics
- API and jobs must never run with superuser credentials
- secrets live in local `.env` only and are not committed

## Capacity And Data Growth Notes
- monitor Docker volume growth for `postgres-data`
- keep logical backups and periodic restore drills as operational gate
- enforce additive contract changes unless version bump is planned

## Release Readiness Gate
A local release candidate is ready only if:
- compose config validates
- DB health and role checks pass
- latest snapshot freshness is inside target window
- API contract docs and schema docs remain synchronized
- smoke checks for all five core screens pass
