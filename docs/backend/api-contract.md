# API Contract

## Endpoints

### `GET /v1/dashboard`
Return the home payload.

Fields:
- generated_at
- top_keywords
- hot_sectors
- risk_alerts

### `GET /v1/keywords`
Return ranked keywords with filters.

Query:
- period: `intraday|daily|weekly`
- market: `kr|us|all`
- sector: optional
- limit: optional

Fields:
- keyword_id
- keyword
- score
- confidence
- delta_1d
- reason_tags

### `GET /v1/keywords/{keyword_id}`
Return detail data for one keyword.

Fields:
- keyword
- score_summary
- timeseries
- related_news
- related_stocks
- related_sectors
- risk_flags

### `GET /v1/watchlist`
Return saved keywords and stocks.

### `POST /v1/watchlist`
Create or update a watch target.

### `GET /v1/alerts`
Return recent triggered alerts.

## Contract Rules
- Keep field names stable once mobile implementation starts.
- Add fields before renaming or removing existing ones.
- Document nullable fields explicitly when implementation begins.
