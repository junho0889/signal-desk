# Ranking Roadmap

## Purpose
Define phased progression from explainable scoring to learned ranking while preserving immutable publish runs and app-ready explanations.

## Roadmap Principles
- Production path is explainable-first and deterministic.
- Learned models are promoted only through offline evaluation and online publish-safety gates.
- Existing v1 score semantics (`score`, `delta_1d`, `confidence`, `reason_tags`, `risk_flags`) remain stable.

## Phase Plan
| phase | primary objective | model class | online/offline boundary | promotion gate |
|---|---|---|---|---|
| `P0` | ship robust explainable baseline | deterministic weighted scoring | online production | stable publish runs + explainability completeness |
| `P1` | improve confidence calibration and ranking consistency | monotonic linear/logistic calibration over P0 features | online production | calibration gain without regression in stability |
| `P2` | supervised ranking using curated labels | tree-based pointwise/pairwise ranker | offline-first, gated online rollout | ndcg/precision improvement across KR and US slices |
| `P3` | regime-aware ranking behavior | segmented/ensemble ranker | offline-first, staged online | sustained uplift over two release cycles |
| `P4` | advanced experimentation | deeper sequence/multimodal candidates | offline research only until explicit promotion | reproducibility + explainability distillation pass |

## Feature Groups (Frozen For Explainable Shipping Path)
- freshness and source coverage
- attention and narrative velocity
- market confirmation and linkage quality
- disclosure/catalyst quality
- persistence and regime context
- trust and contradiction modifiers

## Required Artifacts By Phase
- `P0-P1` required:
  - `feature_snapshot`
  - `ranking_score_record`
  - `explanation_artifact`
  - `ranking_run_manifest`
  - `publish_run_manifest`
- `P2+` additional:
  - `evaluation_snapshot` by slice
  - label-set references and replay manifests

## Evaluation and Regression Baseline
- P0:
  - rank stability, top-k churn checks, alert precision sampling
- P1:
  - calibration error and brier score improvements
- P2+:
  - ndcg@k, map@k, pairwise accuracy, slice robustness checks

Regression gates for online promotion:
- no >5% degradation on primary ranking metric vs baseline
- no >10% rise in hard-risk flag rates
- explanation coverage ratio of 1.00 for published rows

## Publish-Safety Alignment
Roadmap phases must comply with `docs/model/model-system-v1.md` publish states:
- `published`
- `published_degraded`
- `blocked`

No phase can bypass the publish gate or expose non-terminal runs to API consumers.

## Dependencies
- `BE-004` storage schema freeze for model artifacts
- `TRUST-001` trust output contract freeze
- `COL-002` collector freshness and watermark reliability
