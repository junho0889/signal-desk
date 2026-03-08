## Task
- id: APP-005
- reviewer: signal-desk-backend (integration-only)
- scope: contract and route implications only

## Integration Impact Summary
- No backend API contract change is implied by APP-005 dispatch.
- APP-005 dispatch explicitly says to preserve existing routes and avoid backend contract edits.

## Route Implication To Track
- `docs/mobile/implementation-notes.md` lists APP-005 as including push notification deep-link handling.
- BE-003 internal notification payload currently emits:
  - `route.name = keyword_detail|alerts`
- Current mobile route identifiers are:
  - `AppRoutes.detail = /detail`
  - `AppRoutes.alerts = /alerts`

## Safe Integration Guidance
- Keep BE contracts unchanged.
- In APP-005 push/deeplink handler, apply explicit mapping:
  - `keyword_detail` -> `AppRoutes.detail` (`/detail`)
  - `alerts` -> `AppRoutes.alerts` (`/alerts`)
- Treat unknown `route.name` values as a safe fallback to Alerts or ignore with telemetry.
