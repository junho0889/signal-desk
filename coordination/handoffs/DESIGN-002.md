## Task
- id: DESIGN-002
- owner: signal-desk-design
- status: done

## Completion Scope (Requested)
Design debug and polish pass is complete for key screens:
- Home
- Ranking
- Detail
- Watchlist
- Alerts
- shared Loading / Error / Stale / Trust states

## What Changed
- expanded `docs/design/analytics-visual-system.md` with:
  - `DESIGN DEFECT LIST` (screen-by-screen defects from current UI behavior)
  - `APP-READY FIX SPEC` (concrete spacing, hierarchy, button-placement, Korean text-fit, and chart-clarity fixes)
- expanded `docs/design/screen-map.md` from ranking/detail only to full key-screen map:
  - Home, Ranking, Detail, Watchlist, Alerts
  - breakpoint rules and text-fit rules
  - screen-level action placement and acceptance checks

## DESIGN DEFECT LIST
- `D-001` to `D-011` recorded in `docs/design/analytics-visual-system.md`.
- includes hierarchy, readability, spacing, button placement, Korean fit, and chart clarity risks across all key screens.

## APP-READY FIX SPEC
- implementation-ready fix groups `F1` through `F6`:
  - hierarchy/readability slot model
  - spacing standardization
  - primary/secondary action placement
  - Korean text-fit constraints
  - chart clarity requirements (`CE1`, `CE2`)
  - trust/risk visibility rules
- mobile acceptance gates now explicitly test:
  - primary action discoverability
  - fixed score/delta/trust slot positions
  - Korean/English overflow safety at compact/standard/wide breakpoints
  - chart readability and stale/error state behavior

## Verification
- commands:
  - `git -C E:\source\signal-desk-worktrees\design-002 diff --check`
  - `Select-String -Path E:\source\signal-desk-worktrees\design-002\docs\design\analytics-visual-system.md,E:\source\signal-desk-worktrees\design-002\docs\design\screen-map.md -Pattern 'DESIGN DEFECT LIST','APP-READY FIX SPEC','Home','Ranking','Detail','Watchlist','Alerts','Korean','chart','breakpoint','acceptance' -CaseSensitive:$false`
  - `Select-String -Path E:\source\signal-desk-worktrees\design-002\docs\model\ranking-roadmap.md,E:\source\signal-desk-worktrees\design-002\docs\trust\trust-framework.md,E:\source\signal-desk-worktrees\design-002\docs\design\analytics-visual-system.md,E:\source\signal-desk-worktrees\design-002\docs\design\screen-map.md -Pattern 'trust|contradiction|freshness|confidence|evaluation|risk_flags|warning' -CaseSensitive:$false`
- result:
  - `git diff --check` passed (CRLF warnings only)
  - key-screen defect list and app-ready fix spec sections are explicit in docs
  - model/trust consistency cues (trust, contradiction, freshness, confidence, risk) remain mapped in design rules

## Blockers
- none for requested design polish scope
- this branch predates newer coordination files from `main`; required premium brief and quality gate were reviewed from `E:\source\signal-desk\coordination\`

## Files Touched
- `docs/design/analytics-visual-system.md`
- `docs/design/screen-map.md`
- `coordination/handoffs/DESIGN-002.md`
- `coordination/resume/DESIGN-002.md`
