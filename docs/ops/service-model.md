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

## Central Processing Job Order (BE-007 Freeze)
The central processing lane must execute in this order for each processing window:
1. normalization
2. trust
3. feature snapshot build
4. ranking
5. publish
6. alert evaluation

Order guarantees:
- each stage consumes only committed outputs from the immediately previous stage
- publish is the boundary between internal artifacts and API-visible snapshots
- alert evaluation consumes published artifacts only, never in-flight ranking rows

## Stage Failure Behavior
- normalization failure:
  - stop downstream stages for that window
  - keep raw ingest data for later replay
- trust failure:
  - stop feature/ranking/publish for that window unless the run is explicitly marked degraded by policy
- feature failure:
  - stop ranking/publish/alert evaluation for that window
- ranking failure:
  - do not publish partial ranking
  - keep prior successful publish active for API serving
- publish failure:
  - do not advance "latest published" pointer
  - allow publish retry without re-running raw ingest or normalization
- alert-evaluation failure:
  - does not invalidate completed publish
  - retry alert evaluation against the same published snapshot

## Publish Idempotency And Reprocessing
Publish idempotency key assumptions:
- `window_start`
- `window_end`
- `market_scope`
- `feature_version`
- `trust_version`
- `ranking_version`

Idempotency rules:
- retrying publish with the same key must not create duplicate API-visible snapshots
- if a publish artifact already exists for the same key, rerun returns existing artifact identity or no-op

Reprocessing rules (no raw reingest required):
- publish-only replay:
  - rebuild API read model and evidence links from existing ranking artifact
- ranking-plus-publish replay:
  - rerun ranking from existing feature/trust artifacts, then republish
- full upstream replay:
  - reserved for cases where normalization/trust/feature artifacts are missing or invalid

## API Publish Read-Model Assumptions
- API serves only the latest successful published snapshot per scope
- half-finished internal artifacts must never be exposed as required public API fields
- if latest window publish fails, API continues serving last successful snapshot and reports freshness degradation through existing risk signaling

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
