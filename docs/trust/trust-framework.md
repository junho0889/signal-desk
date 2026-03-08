# Trust Framework (v2)

## Purpose
Define a frozen, explainable trust contract for SignalDesk that can be consumed by storage, model, and app lanes without guessing field semantics.

## Scope
- score trust dimensions per keyword window (`keyword_id`, `as_of_ts`)
- publish trust outputs and warning candidates for app and ranking use
- define when contradiction or misinformation states must escalate to manual review
- define review feedback signals for future labels and model evaluation

## Operating Principles
- trust is multi-dimensional, not a single yes/no verdict
- contradictory evidence remains visible and auditable
- low coverage, low reliability, and misinformation risk are separate signals
- trust artifacts are versioned; prior assessments are not silently overwritten

## Inputs
- raw payload history and source metadata
- normalized events, dedup clusters, and contradiction links
- entity mapping confidence and alias stability signals
- data-layer enums and health signals from `docs/data/source-catalog.md`

## Trust Dimensions (Scored `0-100`)
Higher is better for quality dimensions; higher is riskier for risk dimensions.

| dimension_id | class | meaning | interpretation bands |
|---|---|---|---|
| `source_reliability_score` | quality | quality and track record of contributing sources | strong `>= 80`, mixed `50-79`, weak `< 50` |
| `freshness_score` | quality | recency vs source cadence and window timing | fresh `>= 80`, aging `50-79`, stale `< 50` |
| `source_diversity_score` | quality | independent source mix and concentration | broad `>= 80`, moderate `50-79`, narrow `< 50` |
| `entity_mapping_confidence_score` | quality | confidence of keyword-to-entity mapping | stable `>= 80`, usable `60-79`, unstable `< 60` |
| `contradiction_risk_score` | risk | unresolved claim-level disagreement | low `< 30`, monitor `30-59`, active `>= 60` |
| `syndication_intensity_score` | risk | duplicate amplification and wire echo effects | low `< 30`, moderate `30-59`, high `>= 60` |

## Core Trust Output Contract (Frozen Logical Fields)
This field set is frozen for downstream implementation. Physical table names remain storage-lane owned.

| field | type | semantics |
|---|---|---|
| `trust_assessment_version` | string | start with `v2` for this contract |
| `keyword_id` | string | canonical keyword id |
| `as_of_ts` | timestamptz | UTC window timestamp |
| `trust_score` | number (`0-100`) | aggregate trust score for ranking modifiers and UI |
| `coverage_score` | number (`0-100`) | evidence sufficiency and source coverage score |
| `dimension_scores` | object | per-dimension score map |
| `dimension_reasons` | array<string> | inspectable machine reason codes |
| `contradiction_state` | enum | `none`, `emerging`, `active`, `resolved` |
| `misinformation_risk_score` | number (`0-100`) | aggregate misinformation-risk score |
| `misinformation_risk_level` | enum | `low`, `medium`, `high` |
| `quality_flags` | array<string> | includes `deduped`, `low_source_diversity`, `mapping_low_confidence`, `stale_source` |
| `risk_flags` | array<string> | includes `data_freshness_degraded`, `event_coverage_partial`, `mapping_unstable`, `thin_cohort` |
| `warning_candidates` | array<string> | warning ids from threshold table below |
| `misinformation_review_flag` | boolean | `true` when risk level is `medium` or `high` |
| `manual_review_state` | enum | `none`, `watch`, `required`, `block_publish` |
| `manual_review_reasons` | array<string> | escalation reason codes |
| `evidence_summary` | object | source counts, category mix, contradiction counts |

## Trust-To-Model Feature Contract (Frozen)
These are the trust features model and ranking lanes may treat as frozen inputs.

| model_feature_id | source field | type | transform rule | missing-value rule |
|---|---|---|---|---|
| `trust_score` | `trust_score` | float | pass-through `0-100` | use previous window value; else `50` and add `trust_missing_imputed` reason |
| `coverage_score` | `coverage_score` | float | pass-through `0-100` | use previous window; else `40` |
| `source_reliability_score` | `dimension_scores.source_reliability_score` | float | pass-through | `50` |
| `freshness_score` | `dimension_scores.freshness_score` | float | pass-through | `40` |
| `source_diversity_score` | `dimension_scores.source_diversity_score` | float | pass-through | `45` |
| `entity_mapping_confidence_score` | `dimension_scores.entity_mapping_confidence_score` | float | pass-through | `50` |
| `contradiction_risk_score` | `dimension_scores.contradiction_risk_score` | float | pass-through (risk orientation) | `50` |
| `syndication_intensity_score` | `dimension_scores.syndication_intensity_score` | float | pass-through (risk orientation) | `45` |
| `misinformation_risk_score` | `misinformation_risk_score` | float | pass-through (risk orientation) | `50` |
| `contradiction_state_code` | `contradiction_state` | int | `none=0`, `resolved=1`, `emerging=2`, `active=3` | `1` (`resolved`) |
| `misinformation_risk_level_code` | `misinformation_risk_level` | int | `low=0`, `medium=1`, `high=2` | `1` (`medium`) |
| `warning_high_count` | `warning_candidates` | int | count warnings with severity=`high` | `0` |
| `warning_medium_count` | `warning_candidates` | int | count warnings with severity=`medium` | `0` |
| `manual_review_state_code` | `manual_review_state` | int | `none=0`, `watch=1`, `required=2`, `block_publish=3` | `1` (`watch`) |

## Contradiction Policy
### Detection
- group claims by (`entity`, `claim_topic`, `time_bucket`) and detect opposing polarity from independent sources
- treat same-parent syndication as one source family for contradiction independence checks

### State Rules
- `none`: no contradiction evidence
- `emerging`: first material opposing evidence with insufficient independent confirmation
- `active`: opposing claims confirmed by independent sources or contradiction risk threshold breach
- `resolved`: previously contradictory state converged by later high-reliability evidence

## Warning Thresholds (Frozen)
These thresholds are frozen for app warning behavior and model feature consistency.

| warning_id | severity | trigger |
|---|---|---|
| `warning_active_contradiction` | high | `contradiction_state=active` OR `contradiction_risk_score >= 60` |
| `warning_misinfo_high_risk` | high | `misinformation_risk_level=high` OR `misinformation_risk_score >= 75` |
| `warning_stale_source_data` | medium | `freshness_score < 50` OR `risk_flags` has `data_freshness_degraded` |
| `warning_low_source_diversity` | medium | `source_diversity_score < 50` |
| `warning_mapping_low_confidence` | medium | `entity_mapping_confidence_score < 60` OR `risk_flags` has `mapping_unstable` |
| `warning_event_coverage_partial` | medium | `risk_flags` has `event_coverage_partial` |
| `warning_syndication_spike` | low | `syndication_intensity_score >= 60` |

## Manual-Review Escalation Policy (Frozen)
Escalation prevents silent propagation of high-risk states into ranking and alerts.

| manual_review_state | trigger logic | ranking/publish behavior | alert behavior |
|---|---|---|---|
| `none` | no high-severity warning and `misinformation_risk_score < 45` and `contradiction_risk_score < 45` | normal ranking flow | normal alert eligibility |
| `watch` | exactly one medium warning OR risk score in `[45, 59]` | publish with warning metadata | alerts allowed with caution text |
| `required` | any high warning OR `misinformation_risk_score` in `[60, 84]` OR `contradiction_state=active` | publish allowed but force `confidence_score` cap at `70` and tag degraded trust | suppress push alerts claiming high confidence |
| `block_publish` | (`misinformation_risk_score >= 85` AND `source_reliability_score < 40`) OR (`contradiction_state=active` AND `coverage_score < 35`) | hold publish artifact for window until reviewer resolution or next run clears threshold | no new alerts from blocked publish |

### Escalation Reason Codes
- `review_contradiction_active`
- `review_misinfo_high`
- `review_low_reliability_high_misinfo`
- `review_low_coverage_active_contradiction`
- `review_warning_stack_high`

## Feedback Loop For Labels And Evaluation
Manual-review outcomes must flow back into model evaluation and future training labels.

### Review Output Fields
- `review_case_id`
- `manual_review_state_at_publish`
- `review_outcome` enum: `confirmed_signal`, `mixed_evidence`, `misinformation_likely`, `insufficient_evidence`
- `review_resolution_ts`
- `review_confidence` (`0-100`)
- `review_notes_code[]` (structured note tags)

### Evaluation Guidance
- track false-positive and false-negative rates by `manual_review_state`
- track calibration drift by `misinformation_risk_level` and `contradiction_state`
- treat `review_outcome=misinformation_likely` as a hard negative training label candidate
- treat `review_outcome=confirmed_signal` after `required` review as a difficult-positive cohort for future calibration

## Storage And Lineage Expectations
- persist trust outputs as versioned assessments keyed by (`keyword_id`, `as_of_ts`, `trust_assessment_version`)
- persist dimension reasons, warning candidates, and escalation state as structured fields
- persist review cases and outcomes linked to trust assessment and publish run ids
- preserve lineage: `raw_payload_hash -> normalized evidence -> trust assessment -> feature snapshot -> ranking run -> publish artifact`

## Frozen Inputs For Downstream Lanes
- model lane:
  - `Trust-To-Model Feature Contract (Frozen)` fields and encodings
  - `manual_review_state` semantics and `manual_review_state_code`
- backend/storage lane:
  - `Core Trust Output Contract` field names and enums
  - `Warning Thresholds` and `Manual-Review Escalation Policy` trigger semantics
- app/design lane:
  - warning ids and severities in `Warning Thresholds`
  - escalation-driven behavior: caution, confidence-cap messaging, publish-block notice

## Open Dependency Note
- `TRUST-001`, `MODEL-002`, and `BE-006` handoffs were not yet available during this freeze pass; this document serves as the frozen trust-lane proposal for those lanes to align against.
