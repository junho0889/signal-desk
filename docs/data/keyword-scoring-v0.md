# Keyword Scoring V0

## Scoring Objective
Rank keywords by present strength and near-term persistence using interpretable evidence.

## Score Dimensions
- mention_velocity: how quickly mentions are increasing
- trend_velocity: how quickly search interest is increasing
- market_reaction: how related stocks respond in price and volume
- event_weight: whether disclosures or concrete events support the move
- persistence: whether the signal survives beyond a short spike

## Initial Formula
`score = mention_velocity * 0.35 + trend_velocity * 0.20 + market_reaction * 0.25 + event_weight * 0.10 + persistence * 0.10`

## Guardrails
- Penalize keywords with high mention growth but weak market confirmation.
- Penalize one-source spikes unless supported by search or disclosure data.
- Prefer sector-wide confirmation over a single thinly traded stock move.

## Output Fields
- score
- confidence
- reason_tags
- related_stocks
- related_sectors
- risk_flags

## Known Gaps
- entity linking quality is not solved yet
- sentiment quality may be weak in early versions
- market reaction windows need empirical tuning
