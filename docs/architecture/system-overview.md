# System Overview

## Stack
- Mobile app: Flutter
- API: FastAPI container
- Collector node: Raspberry Pi 4B 8GB for always-on source collection and raw spool handling
- Jobs: Python scheduled worker container for normalization, trust scoring, ranking, and alert evaluation
- Storage: PostgreSQL
- Local orchestration: Docker Compose
- Alerts: Firebase Cloud Messaging

## Runtime Flow
1. Raspberry Pi collector adapters fetch source data continuously.
2. Raw payloads are written to local spool storage and forwarded to central storage.
3. Central jobs normalize entities, deduplicate records, and materialize evidence.
4. Trust jobs score source credibility, contradiction risk, and freshness quality.
5. Ranking jobs calculate trend strength, publish ranked snapshots, and evaluate alerts.
6. API exposes ranked views and detail payloads.
7. Mobile app renders dashboards and receives alert notifications.

## Boundary Rules
- Collector node does not own the central source of truth database.
- Collector node may buffer raw payloads locally, but central PostgreSQL remains authoritative.
- Jobs write normalized, trust, feature, and derived data to PostgreSQL.
- API reads stable derived data rather than recalculating everything on request.
- Mobile app consumes only documented API contracts.
- Notification rules are evaluated server-side.
- Application services use least-privilege database roles.

## Local Service Topology
- `postgres`: durable local database, private Docker network, localhost port binding only when needed
- `collector`: Raspberry Pi-hosted adapters and spool forwarder, running outside the central host when desired
- `api`: FastAPI service attached to the same Docker network
- `jobs`: scheduled normalization, trust, ranking, and alert service attached to the same Docker network
- optional reverse proxy: only if remote access is needed later

## Parallelization Rule
Parallel implementation starts only after:
- source inputs are documented
- scoring inputs are stable
- API payloads are frozen enough for UI work
- database security rules are documented
