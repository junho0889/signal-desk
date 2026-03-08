# Keyword Scoring v0

## Objective
Produce an explainable, auditable score per keyword that supports four MVP actions:
- rank keywords on Home/Ranking
- explain movement on Keyword Detail
- filter watchlist priority
- trigger server-side alert rules

## Scoring Output Contract (for BE-001)
Score job publishes one snapshot per keyword per scoring run.

| field | type | description |
|---|---|---|
| `keyword_id` | text | canonical keyword identifier |
| `as_of_ts` | timestamptz | scoring snapshot timestamp |
| `score_total` | numeric(5,2) | final 0-100 rank score |
| `score_delta_24h` | numeric(5,2) | change vs 24h prior snapshot |
| `confidence` | numeric(4,3) | 0.000-1.000 confidence index |
| `rank_position` | int | ordinal rank among active keywords |
| `dimension_mentions` | numeric(5,2) | normalized mention velocity component |
| `dimension_trends` | numeric(5,2) | normalized search trend component |
| `dimension_market` | numeric(5,2) | normalized market reaction component |
| `dimension_events` | numeric(5,2) | normalized event credibility component |
| `dimension_persistence` | numeric(5,2) | normalized persistence component |
| `reason_tags` | text[] | short explainability tags for UI |
| `risk_flags` | text[] | quality/noise/freshness warnings |
| `is_alert_eligible` | boolean | true only when freshness/confidence gates pass |

## Canonical `risk_flags` Allowed Values
This is the authoritative allowed-value list for scoring output `risk_flags`.

- `data_freshness_degraded`: critical source freshness threshold exceeded.
- `event_coverage_partial`: event/disclosure coverage is partial for the window.
- `mapping_unstable`: keyword-to-entity mapping quality is below threshold.
- `thin_cohort`: active keyword cohort size is below the publish minimum.

No additional literals are allowed in `risk_flags` unless this section and backend contract docs are updated together.

## Dimension Definitions
All dimensions are normalized to `0-100` before weighting.

### 1) Mention Velocity (`dimension_mentions`)
Signal of recent narrative acceleration.
- raw input:
  - `mention_count_24h`
  - `mention_delta_24h` vs previous 24h window
  - unique source count in window
- raw formula (before normalization):
  - `mv_raw = ln(1 + mention_count_24h) * 0.6 + pct_change(mention_count_24h, prev_24h) * 0.4`
- suppression:
  - if unique sources < 2, multiply by `0.7`

### 2) Trend Velocity (`dimension_trends`)
Independent confirmation from search attention.
- raw input:
  - current trend index
  - 7d baseline median
  - first derivative over last 2 windows
- raw formula:
  - `tv_raw = zscore(trend_index_vs_30d) * 0.7 + zscore(trend_slope_2h) * 0.3`

### 3) Market Reaction (`dimension_market`)
Price/volume confirmation from mapped symbols.
- raw input per primary related symbol:
  - abnormal return (intraday and 1d)
  - abnormal volume ratio vs 20d baseline
- aggregation:
  - weighted median across related symbols using `link_confidence`
- raw formula:
  - `mr_raw = zscore(abnormal_return) * 0.55 + zscore(abnormal_volume_ratio) * 0.45`

### 4) Event Credibility (`dimension_events`)
Catalyst quality signal from disclosures and high-signal events.
- raw inputs:
  - count and recency of disclosure events
  - filing/event type weight map
- type weights (v0):
  - earnings/preliminary earnings: `1.00`
  - contract/order disclosure: `0.85`
  - governance/capital action: `0.65`
  - generic PR/news-only event: `0.35`
- raw formula:
  - `ev_raw = sum(type_weight * recency_decay_hours)` where `recency_decay_hours = exp(-hours_since_event / 48)`

### 5) Persistence (`dimension_persistence`)
Distinguishes durable rotations from one-window spikes.
- raw inputs:
  - share of last 6 scoring windows with score above cohort median
  - sign consistency of 24h deltas
- raw formula:
  - `ps_raw = active_window_ratio * 0.7 + delta_sign_consistency * 0.3`

## Normalization Policy
- Cohort: normalize within each scoring run across active keywords.
- Method:
  1. winsorize each raw dimension at p5/p95
  2. min-max scale to `0-100`
  3. fill missing with cohort median and attach risk flag
- Minimum cohort size to publish rank: `>= 30` keywords; otherwise publish with `risk_flag=thin_cohort`.

## Final Score Formula (v0)
`score_total = 0.30*dimension_mentions + 0.20*dimension_trends + 0.25*dimension_market + 0.15*dimension_events + 0.10*dimension_persistence`

### Weight Rationale
- Mentions + market reaction dominate because MVP value is "what is moving now" with confirmation.
- Trends provide independent attention confirmation without overpowering price/evidence.
- Events improve credibility but remain secondary due to potential reporting lag.
- Persistence prevents noisy bursts from dominating top ranks.

## Confidence Model
`confidence` is separate from `score_total` and drives alert eligibility.

`confidence = 0.40*source_coverage_ratio + 0.30*entity_link_quality + 0.20*freshness_score + 0.10*cross_source_agreement`

Where:
- `source_coverage_ratio`: fraction of expected source categories present in window (0-1)
- `entity_link_quality`: mean link confidence for primary symbol mappings (0-1)
- `freshness_score`: decays when source lag increases (0-1)
- `cross_source_agreement`: agreement between mentions/trends/market direction (0-1)

Alert eligibility gate:
- `is_alert_eligible = true` only if:
  - `confidence >= 0.55`
  - no hard risk flags (`data_freshness_degraded`, `mapping_unstable`)
  - `score_delta_24h >= configured_threshold`

## Anti-Noise Guardrails
- Single-source spike penalty:
  - if one source contributes >70% of mentions, reduce `dimension_mentions` by 20%.
- No-confirmation penalty:
  - if mentions spike but both trends and market are below cohort median, apply `score_total *= 0.85`.
- Illiquid symbol filter:
  - exclude symbols below liquidity floor from market reaction aggregation.
- Stale-data suppression:
  - if any critical source freshness >6h, set `is_alert_eligible=false`.

## Reason Tags (UI Explainability)
Set at scoring time; BE-001 can expose directly.

- `mentions_accelerating`
- `search_confirmation`
- `price_volume_confirmation`
- `disclosure_backed`
- `persistent_multi_window`
- `low_source_diversity`
- `stale_input_risk`
- `weak_market_confirmation`

## Runtime Cadence
- Feature build cadence: every 30 minutes.
- Score publish cadence: every 30 minutes.
- End-of-day recompute: once after market close to stabilize daily comparison baseline.

## Stable Threshold Parameters (for BE-001 config)
- `confidence_min_for_alert = 0.55`
- `max_source_staleness_minutes = 360`
- `single_source_share_penalty_trigger = 0.70`
- `single_source_share_penalty_factor = 0.80`
- `no_confirmation_penalty_factor = 0.85`
- `entity_link_confidence_min = 0.60`

## Contract Notes For Backend
- `reason_tags` and `risk_flags` should be stored as arrays backed by documented allowed values.
- `risk_flags` values must be constrained to the canonical list in this document.
- `score_total` and each `dimension_*` field should be clamped to `0-100` after penalties.
- Keep one row per (`keyword_id`, `as_of_ts`) via unique constraint to guarantee idempotent score publishes.

## Known Risks And v1 Follow-Ups
- Broad thematic keywords still vulnerable to mapping ambiguity.
- Relative trend indices can distort cross-keyword comparisons in low-volume terms.
- Market confirmation may lag for disclosures filed outside trading hours.
- v1 candidate: sector-relative and regime-aware weighting by market volatility state.

