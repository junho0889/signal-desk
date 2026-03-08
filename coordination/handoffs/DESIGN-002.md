## Task
- id: DESIGN-002
- owner: signal-desk-design
- status: in_progress

## What Changed In This Session
- reduced DESIGN-002 output to APP-critical scope only
- rewrote `docs/design/analytics-visual-system.md` as a concise implementation spec for:
  - ranking surface
  - detail surface
  - chart blocks (ranking/detail/evidence)
  - shared loading/empty/error/stale states
- rewrote `docs/design/screen-map.md` to only include:
  - Keyword Ranking
  - Keyword Detail
  - Keyword Detail Evidence View
  - shared state blueprints

## Freeze Scope For APP Build
- fixed spacing/shape/typography/numeric rules needed for implementation
- fixed ranking row order and geometry (`104dp` collapsed rows)
- fixed detail top-fold order and watchlist action placement
- fixed chart contracts (C1-C5) and readability expectations
- fixed state surface behavior for loading/empty/error/stale

## Verification
- commands:
  - `git -C E:\source\signal-desk-worktrees\design-002 diff --check`
  - `Select-String -Path docs/design/screen-map.md -Pattern "Home|Watchlist|Alerts" -CaseSensitive:$false`
  - `Select-String -Path docs/design/analytics-visual-system.md,docs/design/screen-map.md -Pattern "Ranking|Detail|State|Chart|trust|freshness|contradiction" -CaseSensitive:$false`
- result:
  - `git diff --check` passed (CRLF warnings only)
  - no Home/Alerts guidance remains in screen map; only detail-linked watchlist action references remain
  - ranking/detail/chart/state coverage remains explicit and implementation-ready

## Blockers
- `coordination/handoffs/MODEL-001.md` and `coordination/handoffs/TRUST-001.md` are still missing

## Next Step
- reconcile trust/model naming only when MODEL/TRUST handoffs arrive
- hand this concise freeze set to APP planning/implementation lanes

## Files Touched
- `docs/design/analytics-visual-system.md`
- `docs/design/screen-map.md`
- `coordination/handoffs/DESIGN-002.md`
- `coordination/resume/DESIGN-002.md`
