# Handoff DESIGN-003

## Scope Completed
- froze evidence UI placement for Home (`EV1`) and Keyword Detail (`EV2`) with fixed zone rules and concrete screen-zone examples
- froze source-link affordance (`EV3`) including primary/secondary action order and failure behavior
- froze degraded evidence states: metadata-incomplete, summary-missing, stale, empty, and load-error
- aligned evidence slot mapping to API v1 fallback fields and additive `WAVE-EVIDENCE-001` targets without introducing new contract fields

## Files Updated
- `docs/design/analytics-visual-system.md`
- `docs/design/screen-map.md`
- `coordination/tasks.yaml` (claim + task registration for `DESIGN-003`)

## Verification
- `git diff -- docs/design/analytics-visual-system.md docs/design/screen-map.md coordination/tasks.yaml`
- `git diff --check`
- consistency review against:
  - `coordination/dispatches/WAVE-EVIDENCE-001.md`
  - `coordination/mobile-ui-quality-gate.md`
  - `docs/backend/api-contract.md`

## Blockers / Contract Gaps
- `coordination/handoffs/COL-008.md` was not available in this branch or remote at execution time.
- freeze uses explicit fallback mapping from `related_news[]` until collector/backend evidence handoff is published.
- follow-up needed after `COL-008` handoff: confirm no field-name mismatch for `publisher_domain`, `canonical_url`, and `outbound_links[]` payload shape.

## APP-008 Implementation Notes
- implement `EV1` on Home hero evidence slot and ranking compact evidence slot
- implement `EV2` list rows on Detail `Z4`, newest first
- keep `Open source` always visible when URL exists; disabled `Source unavailable` when URL missing
- keep stale/evidence warnings inline in the evidence time row, not in a separate modal/tab
