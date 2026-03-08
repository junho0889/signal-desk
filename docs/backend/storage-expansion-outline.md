# Storage Expansion Outline

## Purpose
Describe the next schema expansion beyond the current MVP read-model baseline.

## Layer Contract (Frozen For BE-006)
1. raw ingestion
- tables: `ingestion_sources`, `ingestion_runs`, `raw_source_items`
- contract: raw records are immutable and keyed by source scope + idempotency key

2. normalized
- tables: `normalization_runs`, `normalized_events`, `normalized_event_raw_links`, `keyword_event_links`
- contract: every normalized event traces to one or more raw records

3. trust outputs
- tables: `trust_runs`, `event_trust_scores`, `keyword_trust_snapshots`, `trust_review_queue`
- contract: trust is run-versioned, with no in-place overwrite

4. features
- tables: `feature_runs`, `keyword_feature_snapshots`, `feature_group_contributions`
- contract: feature vectors are run-scoped and reference trust/normalization run ids

5. model and labels
- tables: `model_registry`, `model_runs`, `model_keyword_scores`, `label_sets`, `keyword_labels`
- contract: model outputs and labels stay separately versioned; labels never overwrite historical observations

6. evaluation
- tables: `evaluation_runs`, `evaluation_metric_snapshots`, `evaluation_keyword_outcomes`
- contract: evaluation snapshots are tied to model run + label set + evaluation window

7. published ranking
- tables: `publish_runs`, `published_keyword_rankings`, `published_ranking_evidence`, `publish_manifests`
- contract: publish output is immutable and lineage-complete for API replay

## Frozen Lineage Keys
- `raw_source_items.id` -> `normalized_event_raw_links.raw_item_id`
- `normalization_runs.id` -> `trust_runs.normalization_run_id`
- `trust_runs.id` -> `feature_runs.trust_run_id`
- `feature_runs.id` -> `model_runs.feature_run_id`
- `model_runs.id` + `trust_runs.id` -> `publish_runs`
- `publish_runs.id` -> `published_keyword_rankings.publish_run_id`
- `published_keyword_rankings.id` -> `keyword_snapshots.published_ranking_id`

## Published Read-Model Lineage Contract
- `keyword_snapshots` remains the app-facing ranking source.
- add internal lineage fields:
  - `publish_run_id`
  - `published_ranking_id`
  - `model_run_id`
  - `trust_run_id`
- API payload shape remains unchanged; lineage columns are internal and additive.

## Labels And Evaluation Freeze
- labels:
  - `label_sets` defines label policy/version and target horizon.
  - `keyword_labels` stores per-keyword observations with `label_observed_at` and source provenance.
- evaluation:
  - `evaluation_runs` binds one model run to one label set and one evaluation window.
  - `evaluation_metric_snapshots` stores aggregate metrics.
  - `evaluation_keyword_outcomes` stores per-keyword diagnostics for replay and error analysis.

## Retention Baseline
- raw payload body: 180 days hot, then archive with hash manifest
- normalized and trust outputs: 730 days
- feature/model artifacts: 730 days
- labels and evaluation snapshots: 1095 days minimum
- publish manifests and published rankings: 730 days minimum

## Least-Privilege Execution Boundaries
- `signaldesk_ingest_job`: write raw layer only
- `signaldesk_normalize_job`: read raw, write normalized
- `signaldesk_trust_job`: read normalized, write trust
- `signaldesk_model_job`: read normalized/trust/features, write model and evaluation
- `signaldesk_publish_job`: read trust/model, write publish and serving projection lineage fields
- `signaldesk_api`: read published/read-model tables; no writes to pipeline layers
- `signaldesk_readonly`: select-only across layers for diagnostics

## Storage Principles
- raw payloads remain replayable
- normalized, trust, feature, and model artifacts remain traceable by run id
- labels and evaluation snapshots are versioned and immutable
- published ranking outputs are reproducible for a given publish run id

## Ownership Boundary
- collector lane defines intake envelope and retry semantics
- storage lane defines canonical schema, retention, and privilege model
- model lane defines feature and score semantics within frozen storage tables
- trust lane defines trust dimension values within frozen trust tables
- backend lane consumes frozen lineage contract for BE-007 implementation
