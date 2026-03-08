## Task
- id: DESIGN-002
- owner: signal-desk-design
- status: in_progress

## Completion Scope (Requested)
Design freeze is complete for visible mobile surfaces only:
- Ranking
- Keyword Detail
- Chart entry points
- Loading / Error / Stale / Trust states

## What Changed
- tightened `docs/design/analytics-visual-system.md` to concise APP build rules for ranking/detail/chart-entry/state surfaces only
- tightened `docs/design/screen-map.md` to ranking/detail/state blueprint only
- removed non-essential surface guidance from this freeze pass

## Freeze Outputs APP Can Implement Directly
- fixed spacing/shape/type/format tokens
- fixed ranking row order and geometry (`104dp` collapsed)
- fixed detail top-fold order and watchlist action placement
- frozen chart entry points (`CE1`, `CE2`, `CE3`) and minimum readability requirements
- frozen loading/error/stale behavior and trust visibility rules

## Verification
- commands:
  - `git -C E:\source\signal-desk-worktrees\design-002 diff --check`
  - `Select-String -Path docs/design/analytics-visual-system.md,docs/design/screen-map.md -Pattern "Ranking|Detail|Loading|Error|Stale|Trust|Chart|contradiction" -CaseSensitive:$false`
  - `Select-String -Path E:\source\signal-desk\coordination\premium-mobile-brief.md,E:\source\signal-desk\coordination\mobile-ui-quality-gate.md,docs/design/analytics-visual-system.md,docs/design/screen-map.md -Pattern "spacing scale|primary action|row layout|legend|overflow|Korean|loading|error|stale|trust|chart" -CaseSensitive:$false`
  - `Select-String -Path docs/model/ranking-roadmap.md,docs/trust/trust-framework.md,docs/design/analytics-visual-system.md -Pattern "contribution|dimension|trust|contradiction|stale|confidence" -CaseSensitive:$false`
- result:
  - `git diff --check` passed (CRLF warnings only)
  - visible-surface scope coverage is explicit in both design docs
  - premium brief and quality gate constraints are represented in frozen rules
  - model/trust concepts used by visible surfaces remain mapped

## Blockers
- none for APP implementation of requested visible-surface freeze
- MODEL/TRUST handoffs remain future additive refinement input only

## Files Touched
- `docs/design/analytics-visual-system.md`
- `docs/design/screen-map.md`
- `coordination/handoffs/DESIGN-002.md`
- `coordination/resume/DESIGN-002.md`
