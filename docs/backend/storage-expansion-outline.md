# Storage Expansion Outline

## Purpose
Describe the next schema expansion beyond the current MVP read-model baseline.

## Layer Model
1. raw ingestion layer
- captures transport metadata and unmodified source payloads from collector or direct intake
- preserves idempotency keys and hashes so any run can be replayed deterministically

2. normalized layer
- extracts canonical events and entities from raw records
- tracks deduplication and alias resolution without losing raw-level provenance

3. trust layer
- stores source reliability, contradiction, stale-source, and misinformation-risk outputs
- versions assessments by run id; no silent overwrite of prior trust outputs

4. model layer
- stores feature snapshots, model run metadata, and score outputs
- preserves exact model/config lineage for reproducibility and audit

5. published ranking layer
- stores immutable published ranking outputs and evidence bundles
- projects stable app-facing rows to the existing API read model

## Required Table Families By Layer
| layer | table families | lineage anchor |
|---|---|---|
| raw | `ingestion_sources`, `collector_nodes`, `ingestion_runs`, `raw_payload_batches`, `raw_source_items` | `raw_source_items.id` |
| normalized | `normalization_runs`, `normalized_events`, `normalized_event_raw_links`, `entity_aliases`, `entity_resolution_links`, `dedup_clusters`, `contradiction_links` | `normalized_events.id` |
| trust | `trust_runs`, `source_reliability_snapshots`, `event_trust_assessments`, `keyword_trust_snapshots` | `event_trust_assessments.id` |
| model | `feature_runs`, `keyword_feature_snapshots`, `model_registry`, `model_runs`, `model_keyword_scores`, `model_run_metrics` | `model_keyword_scores.id` |
| published | `publish_runs`, `published_keyword_rankings`, `published_ranking_evidence`, `keyword_snapshots` projection lineage columns | `published_keyword_rankings.id` |

## Lineage Contract
- each processing boundary must have a run table with immutable metadata (`started_at`, `completed_at`, `status`, `code_version`, `config_version`, `input_window`)
- each derived table must store the upstream run id(s) and upstream row ids needed to replay that exact result
- required cross-layer keys:
  - raw -> normalized: `normalized_event_raw_links.raw_item_id`
  - normalized -> trust: `event_trust_assessments.normalized_event_id`
  - trust/normalized -> features: `feature_runs.trust_run_id`, `feature_runs.normalization_run_id`
  - features -> model: `model_runs.feature_run_id`, `model_keyword_scores.model_run_id`
  - model/trust -> published: `publish_runs.model_run_id`, `publish_runs.trust_run_id`
  - published -> API read model: `keyword_snapshots.publish_run_id`, `keyword_snapshots.published_ranking_id`

## Retention Baseline
| layer | hot retention (postgres) | archive expectation | delete policy |
|---|---|---|---|
| raw payload body | 180 days | object store export with hash manifest | prune after archive checksum verified |
| raw transport metadata | 400 days | optional cold table/partition | partition drop by month |
| normalized events and mappings | 730 days | optional yearly archive | keep ids stable; no key reuse |
| trust outputs | 400 days | keep run summaries for 2 years | per-run deletion only |
| model features and scores | 400 days | retain model registry and metrics for 2 years | per-run deletion only |
| published rankings and app snapshots | 730 days | optional long-term export for analytics | delete oldest partitions after retention review |

## Privilege Boundary Baseline
- `signaldesk_migrator` owns all schemas/tables and controls default privileges.
- runtime writes are separated by job boundary, even when initially executed through one service:
  - intake runtime: insert/update only raw layer tables.
  - normalization runtime: read raw; write normalized.
  - trust runtime: read normalized; write trust.
  - model runtime: read normalized/trust; write model.
  - publish runtime: read trust/model; write published and `keyword_snapshots` projection fields.
- API runtime gets read-only access to published/read-model tables plus existing watchlist/alert tables.
- `signaldesk_readonly` gets select access across layers, except raw payload text columns can be masked in downstream replicas.

## Freeze Targets For Downstream Lanes
- storage freezes lineage key names (`*_run_id`, `published_ranking_id`, `raw_item_id`) for TRUST-001 and MODEL-001.
- model lane defines feature semantics and score formulas, but must publish through `model_keyword_scores` and `published_keyword_rankings`.
- trust lane defines scoring heuristics, but must output into `event_trust_assessments` and `keyword_trust_snapshots`.
- app lane continues consuming existing API contracts; new lineage columns are internal and additive.

## Ownership Boundary
- collector lane defines the intake and spool contract.
- storage lane defines canonical schema, retention, and privilege model.
- model and trust lanes define score outputs that storage must persist.
- backend lane keeps API contract stable while adopting published-layer projections.
