# Wave Dispatch WAVE-EVIDENCE-001

## Goal
Deliver an end-to-end evidence-rich flow:
- collector captures richer metadata, references, and source links
- backend persists and serves additive evidence fields
- mobile app presents evidence clearly with reliable link behavior

## Fixed Contract Inputs
- collector quality baseline: `docs/data/collector-metadata-quality-v1.md`
- intake behavior baseline: `docs/backend/collector-intake-contract.md`
- API contract baseline: `docs/backend/api-contract.md`
- visual hierarchy baseline: `docs/design/screen-map.md`, `docs/design/analytics-visual-system.md`

## Evidence Metadata Minimum Set
Each accepted collector payload should carry, when available:
- source identity: `source_id`, `publisher_name`, `publisher_domain`
- canonical origin: `canonical_url`, `external_id`
- explainability text: `title`, `summary_text`, `excerpt_text`
- timing: `collected_at`, `upstream_event_at`, `published_at`
- context: `language`, `region`, `market_scope`, `symbol_candidates`, `keyword_candidates`
- references: `outbound_links[]` with URL, domain, label/type, and extraction confidence

## API Additive Output Target
Without breaking existing `v1` fields:
- dashboard top-keyword cards can include a compact latest-evidence block
- keyword detail should include evidence rows with source/publisher/timestamp/link/summary
- intake responses should preserve item-level reasons for missing or weak evidence metadata

## Delivery Sequence
1. `COL-008` freezes and implements evidence metadata capture in collector runtime.
2. `BE-010` freezes storage mapping for evidence metadata and lineage.
3. `BE-011` implements additive API/intake behavior using frozen storage fields.
4. `DESIGN-003` defines exact placement and interaction rules for evidence UI.
5. `APP-008` implements Flutter surfaces and link behavior.
6. `QA-008` verifies collector -> API -> app evidence integrity.

## Non-Negotiables
- no silent contract drift across lanes
- no replacement of existing `v1` fields; additive only
- every lane writes exact verification commands and outcomes in handoff
