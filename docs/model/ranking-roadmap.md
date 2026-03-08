# Ranking Roadmap

## Purpose
Define the ranking lane from explainable scoring-v0 to later learned ranking while keeping outputs auditable, reproducible, and app-ready.

## Scope and Phase Gate
- Phase 0 must remain explainable and directly compatible with DATA-001 and BE-001 contracts.
- Phase 1 and beyond are additive and must not break existing `score`, `delta_1d`, `confidence`, `reason_tags`, or `risk_flags` semantics.
- Storage fields for new model artifacts stay provisional until `BE-004` handoff freezes physical schema.

## Phase Plan

| phase | target state | model family | label strategy | explainability requirement | ship gate |
|---|---|---|---|---|---|
| P0 | production baseline | deterministic weighted scoring (DATA-001 v0) | none (rule model) | all five `dimension_*` values and `reason_tags` required | stable 30-minute runs, alert guardrails active |
| P1 | calibrated baseline | monotonic linear/logistic calibration on top of P0 features | weak labels from forward windows + alert outcomes | signed feature coefficients + per-feature contributions required | improves calibration and top-k precision without stability regression |
| P2 | supervised ranking | gradient-boosted tree ranker (pointwise/pairwise) | curated evaluation set + weak labels + QA-reviewed slices | SHAP-style top factors and fallback P0 dimensions required | ndcg/precision gains across KR and US cohorts |
| P3 | context-aware ranking | regime-aware ensemble (market-state segmented) | phased online labels and human audit queue | explanation bundle must include regime reason and confidence decomposition | online impact is positive for 2+ release cycles |
| P4 | advanced experiments | deeper sequence or multimodal models | only after P3 data maturity | must emit distilled explainable factors mapped to v1 reason taxonomy | isolated experimental lane only |

## Feature Groups
All features are computed per (`keyword_id`, `as_of_ts`) with lineage back to normalized inputs.

### Group A: Coverage and Freshness
- `source_coverage_ratio`
- `freshness_score`
- `source_staleness_max_minutes`
- `critical_source_missing_count`
- `cross_source_agreement`

### Group B: Attention and Narrative Velocity
- `mention_count_24h`, `mention_delta_24h`, `mention_accel_2h`
- `unique_source_count_24h`, `source_concentration_ratio`
- `trend_index_vs_30d`, `trend_slope_2h`

### Group C: Market Confirmation
- `abnormal_return_intraday`, `abnormal_return_1d`
- `abnormal_volume_ratio_20d`
- `market_confirmation_alignment` (mentions/trend/price direction agreement)
- `symbol_link_quality_weighted`

### Group D: Catalyst and Event Quality
- `event_count_weighted_48h`
- `disclosure_weighted_recency`
- `event_type_entropy` (single-event vs diversified catalyst profile)
- `high_credibility_event_share`

### Group E: Persistence and Regime Context
- `active_window_ratio_6`
- `delta_sign_consistency_6`
- `keyword_volatility_state`
- `sector_relative_strength`
- `market_regime_bucket` (calm, risk-on, risk-off)

### Group F: Trust and Contradiction (Post TRUST-001)
- `source_trust_score`
- `misinformation_risk_score`
- `contradiction_density`
- `provenance_completeness`

## Output Contracts
This section defines the model-lane contract for downstream storage, backend, design, and app planning.

### 1) `ranking_publish_v1` (shipping contract)
Must remain aligned with DATA-001/BE-001:
- `keyword_id`, `as_of_ts`, `score_total`, `score_delta_24h`, `confidence`, `rank_position`
- `dimension_mentions`, `dimension_trends`, `dimension_market`, `dimension_events`, `dimension_persistence`
- `reason_tags[]`, `risk_flags[]`, `is_alert_eligible`

### 2) `ranking_publish_v1_plus` (additive next fields)
Additive only, no rename/removal of existing fields:
- `run_id` (text, non-null): scoring run identifier
- `model_version` (text, non-null): e.g., `p0-v1`, `p1-v2`
- `ranking_phase` (text, non-null): `P0|P1|P2|P3|P4`
- `score_components` (jsonb, nullable): normalized component map used for explanation cards
- `confidence_components` (jsonb, nullable): coverage/link/freshness/agreement breakdown
- `freshness_minutes` (int, nullable): max source lag in publish window
- `evidence_counts` (jsonb, nullable): news/disclosure/market evidence counts

### 3) `explanation_artifact_v1` (detail and audit support)
Per (`keyword_id`, `run_id`) explanation object:
- `summary_reason` (text): one-line natural language reason
- `top_factors[]` (array): each item contains:
  - `feature_key`
  - `feature_value`
  - `contribution_signed`
  - `direction` (`up|down`)
  - `quality_note` (nullable)
- `fallback_reason_tags[]` (text[]): maintain compatibility with current UI chips
- `explanation_version` (text)

### 4) `ranking_run_manifest_v1` (reproducibility)
Per `run_id` metadata:
- `run_id`, `started_at`, `finished_at`, `status`
- `model_version`, `feature_spec_version`, `normalization_version`
- `data_window_start`, `data_window_end`, `source_watermark_ts`
- `train_set_ref` (nullable pre-P2), `eval_set_ref` (nullable pre-P2)
- `code_commit_sha`, `config_hash`, `seed`
- `row_count_keywords`, `row_count_features`, `publish_count`

### 5) `evaluation_snapshot_v1` (regression and promotion)
Per `run_id` and evaluation slice:
- `slice_key` (`all|kr|us|sector:*|risk:*`)
- `metric_name`, `metric_value`, `baseline_run_id`, `delta_vs_baseline`
- `pass_fail`
- `notes` (nullable)

## Evaluation Plan

### Offline Metrics by Phase
- P0:
  - rank stability: top-20 overlap and median rank shift
  - sanity correlation: score vs short-horizon forward move proxies
  - alert precision review on sampled high-severity alerts
- P1:
  - calibration error and brier score for alert-likelihood proxy
  - precision@10/20 and recall@20 vs P0 baseline
- P2:
  - ndcg@10/20, map@k, pairwise accuracy
  - slice robustness by market (`kr|us`) and volatility regime
- P3+:
  - uplift vs control by regime
  - drift and explanation-consistency checks

### Regression Gate (must pass before promotion)
- no degradation > 5% on primary ranking metric for `all`, `kr`, and `us` slices
- no increase > 10% in `data_freshness_degraded` or `mapping_unstable` flag rate
- top-20 churn within expected band unless a documented market regime break occurs
- explanation completeness:
  - 100% rows include either `dimension_*` outputs (P0/P1) or `top_factors` (P2+)
  - 0% null `model_version` or `run_id` in publish rows

### Reproducibility Rules
- every publish row must map to exactly one `run_id`
- re-running with same inputs and `config_hash` must reproduce rank order deterministically
- run manifests and evaluation snapshots are immutable append-only records

## Delivery Sequence for Downstream Lanes
1. Freeze `ranking_publish_v1_plus` field list with `BE-004` storage handoff.
2. Align trust-linked feature availability after `TRUST-001`.
3. Provide `explanation_artifact_v1` examples to DESIGN-002 for card/chart patterns.
4. Provide stable payload samples to APP-006 for integration planning.

## Dependencies and Open Blockers
- depends on canonical storage families from `BE-004` for run/evaluation persistence
- depends on trust outputs from `TRUST-001` for Group F features
- depends on collector lineage completeness from `COL-001` for provenance-sensitive metrics
