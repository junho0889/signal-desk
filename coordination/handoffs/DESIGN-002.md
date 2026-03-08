## Task
- id: DESIGN-002
- owner: signal-desk-design
- status: in_progress

## What Changed In This Session
- tightened `docs/design/analytics-visual-system.md` into a strict implementation contract
- enforced non-negotiable alignment with:
  - `coordination/premium-mobile-brief.md`
  - `coordination/mobile-ui-quality-gate.md`
- froze spacing, typography, truncation, numeric formatting, state geometry, and action/button placement rules
- added explicit chart readability gate and blocked anti-pattern list
- rewrote `docs/design/screen-map.md` into per-screen mobile blueprints with:
  - fixed zone order and min-height guidance
  - primary/secondary action placement per screen
  - loading/empty/error/stale state layout behavior
  - Korean/English safety rules

## Freeze Scope (Publisher-Ready)
The following are now explicit and should be implemented without additional UI invention:
- spacing and geometry: fixed scale (`4,8,12,16,24,32`), global paddings, card paddings, row heights
- typography: frozen role set, font family stack, numeric/text formatting behavior
- button placement: one-primary-action rule and per-screen primary action location
- chart behavior: C1-C6 geometry and readability/title requirements
- state behavior: loading, empty, error, stale treatment and control placement

## Current State
- visual system is now strict enough for publisher/implementation lanes to follow directly
- task remains `in_progress` because MODEL/TRUST handoffs are still missing for final additive field-label reconciliation

## Verification
- commands:
  - `git -C E:\source\signal-desk-worktrees\design-002 diff --check`
  - `Select-String -Path docs/design/analytics-visual-system.md,docs/design/screen-map.md -Pattern "primary action|spacing scale|truncation|loading|empty|error|stale|Korean|contradiction|freshness" -CaseSensitive:$false`
  - `Select-String -Path docs/model/ranking-roadmap.md,docs/design/analytics-visual-system.md -Pattern "feature breakdown|contribution|dimension|explanation|stability|trust" -CaseSensitive:$false`
  - `Select-String -Path docs/trust/trust-framework.md,docs/design/analytics-visual-system.md -Pattern "trust score|coverage score|contradiction|stale|misinformation|low-confidence" -CaseSensitive:$false`
- result:
  - `git diff --check` passed (CRLF normalization warnings only)
  - premium-mobile and quality-gate concerns are represented as explicit, frozen rules
  - model/trust roadmap concepts remain mapped into card/chart and warning surfaces

## Blockers
- `coordination/handoffs/MODEL-001.md` not present
- `coordination/handoffs/TRUST-001.md` not present

## Next Step
- when MODEL/TRUST handoffs arrive, run one reconciliation pass to confirm trust/model field naming and warning copy
- hand off this freeze contract to APP-006/APP-007 as non-improvisation baseline

## Files Touched
- `docs/design/analytics-visual-system.md`
- `docs/design/screen-map.md`
- `coordination/handoffs/DESIGN-002.md`
- `coordination/resume/DESIGN-002.md`
