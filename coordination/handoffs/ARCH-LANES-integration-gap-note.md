## Scope
- integration review only from `codex/be-003`
- no backend feature implementation
- no shared contract edits

## Contract Gaps Identified From New Lanes
1. API trust-surface gap
- New trust lane outputs (`trust score`, `coverage score`, `contradiction/stale/mapping/misinformation flags`) are not yet represented in current public v1 payload fields.
- Impact: APP-006 and DESIGN-002 cannot cleanly render trust surfaces using only existing API contract.

2. API reproducibility/evidence lineage gap
- New model and storage lanes require run metadata and reproducible lineage from raw/normalized data to published rankings.
- Current v1 responses do not expose run identifiers or evidence lineage IDs; detail evidence is user-readable but not run-traceable.
- Impact: audit-style explainability and model-run comparison in app surfaces remain contract-open.

3. Notification trust-context gap
- BE-003 internal notification payload supports severity/message/route/meta but has no trust or evidence-confidence context fields.
- Impact: future trust-aware notification UX would require additional payload metadata or an app-side fetch-on-open pattern.

## Recommendation
- Keep current contracts frozen for now.
- Open a dedicated contract-alignment task before APP-006 implementation to define:
  - additive trust fields for ranking/detail/alerts
  - run metadata and evidence lineage exposure strategy
  - notification trust-context policy (payload extension vs deferred fetch)
