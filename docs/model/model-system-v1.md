# Model System V1

## Purpose
Freeze the first production-safe model system for SignalDesk with an explainable online ranking path and a separated offline research lane.

## Scope
- This document defines how normalized and trust-aware inputs become immutable publish runs.
- This is the contract for model-lane outputs consumed by storage, backend, app, and QA.
- Shipping ranking in v1 is explainable-first; deep learning remains offline research only.

## Core Guarantees
- Every published score is traceable to one immutable `publish_run_id`.
- Online ranking is deterministic for a fixed input window and config hash.
- Explanations are generated from model features and trust adjustments, not free-form text generation.
- Alert evaluation consumes only published artifacts, never in-progress run rows.

## Online Pipeline (Production)
`normalized_events + entity_links + trust_outputs -> feature_snapshot -> ranking_run -> publish_run`

### Stage Contract
| stage | required input | primary output | terminal states |
|---|---|---|---|
| `feature_build` | normalized entities/events, trust outputs, config | `feature_snapshot` rows + `feature_run_manifest` | `completed`, `failed` |
| `ranking` | completed feature run, scoring config | `ranking_score_record` rows + `ranking_run_manifest` + `explanation_artifact` | `completed`, `failed` |
| `publish_gate` | completed ranking run + manifests | `publish_run_manifest` + immutable published snapshot set | `published`, `published_degraded`, `blocked`, `failed` |
| `alert_eval` | `published`/`published_degraded` run only | alert candidates and notification-ready payload inputs | `completed`, `failed` |

## Online Explainability Contract (Required Per Published Keyword)
- `score_total`
- `confidence`
- `rank_position`
- `reason_tags[]` (canonical list from DATA-001)
- `risk_flags[]` (canonical list from DATA-001)
- `top_factor_groups[]` with signed contribution values
- `trust_adjustments[]` with adjustment reason and magnitude
- `evidence_counts` (news, disclosures, market confirmations)
- `freshness_minutes`
- `summary_reason`

If any required explainability field is missing, the run cannot be `published` and must become `blocked`.

## Required Artifacts
The following artifacts are mandatory for every production run window.

### 1) `feature_snapshot`
- key: (`feature_run_id`, `keyword_id`)
- required fields:
  - `as_of_ts`
  - `feature_values` (structured map)
  - `feature_quality_flags`
  - `source_watermark_ts`
- rule: immutable rows after run terminal state

### 2) `feature_run_manifest`
- key: `feature_run_id`
- required fields:
  - `window_start`, `window_end`
  - `feature_spec_version`
  - `config_hash`
  - `status`
  - `row_count`
  - `started_at`, `finished_at`

### 3) `ranking_score_record`
- key: (`ranking_run_id`, `keyword_id`)
- required fields:
  - `score_total`, `score_delta_24h`, `confidence`, `rank_position`
  - `dimension_mentions`, `dimension_trends`, `dimension_market`, `dimension_events`, `dimension_persistence`
  - `reason_tags[]`, `risk_flags[]`, `is_alert_eligible`

### 4) `ranking_run_manifest`
- key: `ranking_run_id`
- required fields:
  - `feature_run_id`
  - `model_version`
  - `ranking_phase` (`P0|P1|P2|P3|P4`)
  - `normalization_version`
  - `seed`
  - `config_hash`
  - `status`
  - `started_at`, `finished_at`

### 5) `explanation_artifact`
- key: (`ranking_run_id`, `keyword_id`)
- required fields:
  - `summary_reason`
  - `top_factor_groups[]`
  - `trust_adjustments[]`
  - `evidence_counts`
  - `freshness_minutes`
  - `explanation_version`

### 6) `evaluation_snapshot`
- key: (`evaluation_run_id`, `slice_key`, `metric_name`)
- required fields:
  - `model_version`
  - `baseline_run_id`
  - `metric_value`
  - `delta_vs_baseline`
  - `pass_fail`

### 7) `publish_run_manifest`
- key: `publish_run_id`
- required fields:
  - `ranking_run_id`
  - `publish_state`
  - `publish_safety_result`
  - `degraded_reasons[]`
  - `published_at`
  - `published_row_count`

## Publish-Safety Rules

### Hard Blocks (must result in `blocked`)
- missing `feature_run_manifest` or `ranking_run_manifest`
- mismatch between run windows across feature, ranking, and publish steps
- missing required explainability fields for any published keyword row
- invalid `risk_flags` literal outside canonical DATA-001 list
- source staleness exceeds hard limit for critical feeds

### Degraded Publish (allowed with explicit state)
`publish_state = published_degraded` is allowed only when:
- trust coverage is below full threshold but above block threshold
- cohort size is below ideal but still above minimum publish size
- non-critical source windows are stale while critical sources are within limit

Degraded publish requires:
- `degraded_reasons[]` in `publish_run_manifest`
- `risk_flags[]` set per affected keyword
- QA-visible degraded marker in publish metadata

### Publish Threshold Registry (v1 defaults)
- `min_active_keywords_for_publish = 30`
- `confidence_min_for_alert = 0.55`
- `max_source_staleness_minutes_critical = 360`
- `max_missing_trust_ratio_for_full_publish = 0.10`
- `max_missing_trust_ratio_for_degraded_publish = 0.35`
- `explanation_coverage_min_ratio = 1.00`

## Run-State Machine (Contract For BE-006/BE-007)
- `feature_run`: `scheduled -> running -> completed|failed`
- `ranking_run`: `pending_feature_run -> running -> completed|failed`
- `publish_run`: `pending_gate -> published|published_degraded|blocked|failed`
- terminal states are immutable
- reruns must create new run IDs; no in-place overwrite of prior terminal runs

## Offline Research Boundary
Offline research owns:
- replay/backtest datasets
- label generation and quality review
- calibration and hyperparameter search
- supervised ranking experiments and model comparison

Offline research must not:
- write directly to production `publish_run` artifacts
- bypass online publish-safety gates
- replace explanation fields with non-deterministic generated text

Promotion from offline to online requires:
- versioned `model_version` and `feature_spec_version`
- replay pass on historical windows
- evaluation snapshot pass against promotion thresholds
- explicit rollback target version

## Label Strategy
### Immediate labels (v1)
- follow-up evidence confirmation within short horizon
- post-publish market confirmation consistency
- contradiction escalation after publish

### Later labels (v2+)
- user watch/save/revisit outcomes
- analyst review outcomes
- longer-horizon thematic persistence

## Evaluation and Regression Requirements
- compute evaluation snapshots per run and per slice (`all`, `kr`, `us`, regime, risk buckets)
- require no primary metric degradation > 5% against current baseline for promotion
- require no > 10% increase in hard-risk flag rates (`data_freshness_degraded`, `mapping_unstable`)
- require explanation coverage ratio = `1.00` for publishable rows

## BE-006, BE-007, QA-006 Assumptions

### For `BE-006` (storage/job implementation)
- implement artifact families exactly as listed above
- implement run-state transitions and immutability rules
- persist publish thresholds as versioned config, not hardcoded literals

### For `BE-007` (API/read-model expansion)
- expose only terminal publish runs (`published` or `published_degraded`)
- include publish metadata needed for degraded-context UI (`publish_state`, `degraded_reasons`)
- keep existing v1 aliases (`score`, `delta_1d`) stable

### For `QA-006` (verification lane)
- validate run-state transitions and no partial publish visibility
- validate explainability completeness and canonical flag literals
- validate degraded publish behavior and alert eligibility gates

## Dependencies
- `BE-004`: final physical schema for artifact persistence
- `TRUST-001`: finalized trust outputs used in trust adjustments and degraded gates
- `COL-002` / intake contract: source freshness and watermark reliability
