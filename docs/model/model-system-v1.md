# Model System V1

## Purpose
Define the first production-safe model system for SignalDesk from central raw storage through explainable publish outputs.

## Recommended Direction
- Do not start with deep learning in the production ranking path.
- Ship an explainable, reproducible online ranking pipeline first.
- Keep experimental or learned models in a separate offline research lane until labels, evaluation, and rollback behavior are stable.

## Why This Is The Right Fit
- SignalDesk is an intelligence product, so every top-ranked item needs an explanation, not just a score.
- Collector freshness, trust, and contradiction handling are core product behavior, so failures must be auditable per run.
- The current app and alert flows already depend on stable ranking snapshots and reason tags, which are easier to preserve with an explainable-first system.

## Recommended Production Pipeline
1. raw ingest lands in central storage through the collector intake contract
2. normalization jobs extract canonical events, entity links, and dedup clusters
3. trust jobs produce trust dimensions, warning candidates, contradiction state, and misinformation-review flags
4. feature jobs build keyword-level feature snapshots on a fixed cadence
5. ranking jobs produce a scored artifact per keyword plus explanation-ready score components
6. publish jobs freeze an immutable ranking snapshot and evidence links for API serving
7. alert-evaluation jobs consume only published ranking artifacts, not half-finished intermediate rows

## Online Production Model Scope
The first shipping model should own five outputs per keyword:
- `importance_score`
- `confidence_score`
- `freshness_minutes`
- `warning_candidates`
- `explanation_artifact`

The shipping ranking should remain a structured ensemble:
- weighted feature scoring for rank
- calibrated confidence calculation
- trust-based penalties or suppressions
- publish-time explanation extraction from score components and evidence counts

## What AI Or ML Should Actually Do In V1
- event type classification support for normalized events
- contradiction and duplication heuristics that feed trust outputs
- confidence calibration from historical outcome distributions
- ranking score computation from feature groups

## What Should Stay Out Of The Production Path For Now
- end-to-end black-box ranking from raw text only
- LLM-written user explanations as the primary explanation source
- learned models with no run-level reproducibility or rollback path
- training that depends on user behavior data we do not have yet

## Feature Groups For The Shipping Path
- freshness and recency
- attention acceleration
- market confirmation
- disclosure and catalyst quality
- persistence and regime stability
- trust and contradiction modifiers

## Explainability Contract
Every published keyword ranking should be explainable with:
- top contributing feature groups
- trust adjustments applied
- evidence counts and source diversity summary
- freshness summary
- contradiction or misinformation-review state

## Online Versus Offline Boundary

### Online Path
- cadence target: every 30 minutes
- deterministic inputs only
- versioned feature builder and ranking config
- no manual intervention required for a normal publish run

### Offline Research Path
- backtests and replay from raw plus normalized history
- label generation and quality review
- calibration experiments
- learned ranking experiments after enough labels exist

## Label Strategy
Use layered labels rather than one vague success target.

### Immediate Labels
- whether an alert-worthy publish was later confirmed by follow-up evidence
- whether post-publish market reaction supported the signal
- whether contradiction or misinformation warnings later escalated

### Later Labels
- user save, revisit, and alert-engagement data
- manual analyst review outcomes
- long-horizon thematic persistence

## Required Model Artifacts
- `feature_snapshot`
- `ranking_score_record`
- `explanation_artifact`
- `ranking_run_manifest`
- `evaluation_snapshot`
- `publish_manifest`

## Publish Safety Rules
- never publish a ranking run without a matching run manifest
- never overwrite prior published runs in place
- publish only after feature, trust, and ranking steps all complete for the same run window
- keep alert evaluation downstream of publish so alerts reflect what the app can actually explain

## Failure Handling
- if normalization is incomplete, do not publish partial ranking as final
- if trust inputs are stale or missing beyond threshold, publish only if the publish run is explicitly marked degraded
- if ranking finishes but publish fails, keep the run resumable without recomputing raw ingest

## Recommended Next Implementation Order
1. freeze storage contract for feature, trust, model, and publish artifacts
2. freeze trust-to-model feature inputs and review escalation
3. freeze backend job order and additive publish-read-model contract
4. implement explainable feature builder and ranking publisher
5. add evaluation and replay tooling before learned models
