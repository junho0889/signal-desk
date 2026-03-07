# System Overview

## Stack
- Mobile app: Flutter
- API: FastAPI container
- Jobs: Python scheduled worker container
- Storage: PostgreSQL
- Local orchestration: Docker Compose
- Alerts: Firebase Cloud Messaging

## Runtime Flow
1. Scheduled jobs ingest source data.
2. Data is normalized into keyword and event records.
3. Scoring jobs calculate trend strength and supporting metrics.
4. API exposes ranked views and detail payloads.
5. Mobile app renders dashboards and receives alert notifications.

## Boundary Rules
- Jobs write derived data to PostgreSQL.
- API reads stable derived data rather than recalculating everything on request.
- Mobile app consumes only documented API contracts.
- Notification rules are evaluated server-side.
- Application services use least-privilege database roles.

## Local Service Topology
- `postgres`: durable local database, private Docker network, localhost port binding only when needed
- `api`: FastAPI service attached to the same Docker network
- `jobs`: scheduled ingestion and scoring service attached to the same Docker network
- optional reverse proxy: only if remote access is needed later

## Parallelization Rule
Parallel implementation starts only after:
- source inputs are documented
- scoring inputs are stable
- API payloads are frozen enough for UI work
- database security rules are documented
