## Task
- id: DESIGN-002
- owner: signal-desk-design
- status: in_progress

## What Changed
- expanded `docs/design/analytics-visual-system.md` from a starter stub into an implementation-ready visual specification
- defined semantic token groups (momentum/trust/freshness/risk), mobile type and spacing guidance, and accessibility constraints
- defined chart block library `C1` through `C6` for ranking, detail, and evidence surfaces
- defined stat card library `S1` through `S4` with v1 field mapping and trust/model-ready additive mapping
- added explicit trust ladder, freshness band, and contradiction escalation behavior
- rewrote `docs/design/screen-map.md` with screen-zone model (`Z0` through `Z5`) and per-screen analytics placement guidance
- claimed `DESIGN-002` in `coordination/tasks.yaml` (`pending` -> `in_progress`)

## Current State
- premium analytics visual direction is now concrete enough for mobile implementation planning
- chart/stat patterns are aligned to current v1 API payloads and intentionally additive for future trust/model fields
- model and trust handoff docs are still absent; this checkpoint uses roadmap/framework assumptions already documented in repo

## Freeze Guidance For APP-006
- token groups to freeze:
  - momentum/trust/freshness/risk semantic channels
  - trust ladder labels (`strong|watch|fragile`)
  - freshness bands (`live|recent|aging|stale`)
  - contradiction severity levels (low/medium/high)
- chart blocks to freeze:
  - `C1` Rank Momentum Sparkline
  - `C2` Score and Confidence Twin-Line
  - `C3` Dimension Contribution Bar Stack
  - `C4` Source Mix Ribbon
  - `C5` Event Timeline Ladder
  - `C6` Relationship Pulse Matrix
- screen zones to freeze:
  - ranking row order (`Z1` to `Z4` fixed)
  - detail top-fold stack (`S1`, `S2/S3`, conditional `S4`, `C2`)
  - evidence pairing (`C4` + `C5` in `Z3`/`Z4`)

## Verification
- commands:
  - `git -C E:\source\signal-desk-worktrees\design-002 diff --check`
  - `Select-String -Path docs/design/analytics-visual-system.md -Pattern "trust score|coverage score|contradiction|stale|low-confidence|misinformation|source diversity|freshness" -CaseSensitive:$false`
  - `Select-String -Path docs/model/ranking-roadmap.md,docs/design/analytics-visual-system.md -Pattern "feature breakdown|contribution|dimension|explanation|stability|trust" -CaseSensitive:$false`
- result:
  - `git diff --check` reported no whitespace errors (only CRLF normalization warnings)
  - trust-framework outputs and contradiction/freshness concepts are represented in the design spec
  - ranking-roadmap outputs (feature breakdown/contribution explainability) are represented in chart and card patterns

## Blockers
- `coordination/handoffs/MODEL-001.md` and `coordination/handoffs/TRUST-001.md` are not present yet; final field-level mapping review is pending those handoffs

## Next Step
- after MODEL/TRUST handoffs arrive, run a focused reconciliation pass and confirm whether any additive field labels or warning copy need adjustment
- handoff this freeze set to mobile planning (`APP-006`) as baseline UI primitives

## Files Touched
- `docs/design/analytics-visual-system.md`
- `docs/design/screen-map.md`
- `coordination/tasks.yaml`
- `coordination/handoffs/DESIGN-002.md`
- `coordination/resume/DESIGN-002.md`
