# Backend Implementation Notes (BE-003)

## Scope Delivered
BE-003 keeps the existing v1 endpoint surface intact and adds notification-delivery preparation for watchlist alerts.

Delivered backend behavior:
- `evaluate-alerts` still persists alert rows in `alerts`
- new internal notification payload contract for downstream push delivery
- configurable notification sink baseline:
  - `none`: prepare nothing for delivery
  - `stdout`: expose notification-ready payloads in command output for local verification

## Code Layout
- `services/jobs/signaldesk_jobs/alerts.py`: alert persistence and created-alert metadata
- `services/jobs/signaldesk_jobs/delivery.py`: notification payload builder and sink dispatcher
- `services/jobs/signaldesk_jobs/config.py`: notification sink configuration
- `services/jobs/signaldesk_jobs/main.py`: alert evaluation flow now includes delivery preparation

## Runtime Environment Variables
- `SIGNALDESK_APP_DATABASE_URL`
  - runtime role: `signaldesk_app`
- `SIGNALDESK_MIGRATOR_DATABASE_URL`
  - runtime role: `signaldesk_migrator`
- `SIGNALDESK_ALERT_DELTA_THRESHOLD`
  - optional, default `2.0`
- `SIGNALDESK_NOTIFICATION_SINK`
  - optional, one of `none|stdout`
  - default: `none`
- `SIGNALDESK_NOTIFICATION_TITLE_PREFIX`
  - optional title prefix for delivery payloads
  - default: `SignalDesk`

## Local Verification
Compile jobs package:
```powershell
python -m compileall services\jobs\signaldesk_jobs
```

Preview delivery payload formatting without external services:
```powershell
$env:SIGNALDESK_NOTIFICATION_SINK='stdout'
python -m services.jobs.signaldesk_jobs.main evaluate-alerts
```

## Internal Delivery Contract
- payload shape is documented in `docs/backend/api-contract.md` under `Internal Notification Payload`
- stock-linked alerts route to keyword detail when `keyword_id` is available
- unsupported sinks fail fast through config validation

## Known Gaps
- no FCM or external push provider integration yet
- no durable notification outbox table yet; stdout sink is the local verification baseline
- delivery retry, acknowledgement, and dead-letter handling remain future backend work
