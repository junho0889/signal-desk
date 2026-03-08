## Task
- id: BE-003
- type: integration-risk follow-up
- status: note-only (no contract change)

## Route Naming Gap
- BE-003 internal notification payload uses `route.name = keyword_detail|alerts`.
- Current mobile navigation uses `AppRoutes.detail = '/detail'` and `AppRoutes.alerts = '/alerts'` via `Navigator.pushNamed(...)`.
- `alerts` is semantically aligned, but `keyword_detail` does not match the current mobile route identifier (`/detail`).

## Integration Risk
- Without an explicit mapping layer in the future push/deeplink handler, keyword-target notifications may fail to navigate to detail.

## Safe Recommendation
- Keep BE-003 contract unchanged for now.
- In push integration work, add an explicit route map:
  - `keyword_detail` -> `AppRoutes.detail` (`/detail`)
  - `alerts` -> `AppRoutes.alerts` (`/alerts`)
