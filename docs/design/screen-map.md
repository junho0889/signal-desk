# Screen Map

## Scope
Frozen implementation map for visible mobile surfaces only:
- Keyword Ranking
- Keyword Detail
- shared Loading/Error/Stale state behavior

## Shared Rules
- horizontal padding: `16dp`
- section gap: `16dp`
- card padding: `12dp`
- min touch target: `44dp`
- zone order (fixed):
  - `Z0` context rail
  - `Z1` header
  - `Z2` trust/freshness
  - `Z3` chart entry
  - `Z4` evidence summary
  - `Z5` actions

## Keyword Ranking

API mapping:
- `GET /keywords.generated_at` -> `Z0`
- `GET /keywords.items[]` -> row content
- `GET /keywords.next_cursor` -> pagination

Layout blueprint:
- `Z0`: sticky generated-time + scope rail
- sticky filter strip under `Z0`, min `44dp` height
- row blueprint (collapsed, min `104dp`):
  1. rank + keyword (1-line clamp)
  2. movement (`score`, `delta_1d`) + CE1 sparkline
  3. trust/freshness cue
  4. evidence cue (`reason_tags`, related sector)
- row gap: `8dp`

Actions:
- primary: full-row tap -> Keyword Detail
- secondary: sticky `period/market/sector` filter controls

Lock:
- score/delta/trust slots cannot move by row
- long strings truncate; row geometry stays fixed

## Keyword Detail

API mapping:
- `GET /keywords/{keyword_id}.generated_at` -> `Z0`
- `score_summary` -> movement + trust/freshness + contribution entry
- `timeseries[]` -> CE2 trend chart
- `reason_block`, `risk_flags` -> trust/evidence cues
- `POST /watchlist` -> `Z5`

Layout blueprint:
- `Z0`: context rail with freshness age
- `Z1`: keyword header + movement card
- `Z2`: trust/freshness cards (two-column)
- `Z3`: contradiction card (if active) + CE2 trend chart
- `Z4`: CE3 contribution entry + reason summary
- `Z5`: watchlist primary action slot

Actions:
- primary: trailing `Add/Remove Watchlist` button (`44dp` h min, `120dp` w min)
- same action persists as sticky bottom action after first major scroll break
- secondary: contradiction jump action

Lock:
- top fold must include movement, trust/freshness, and CE2 before deep evidence
- contradiction card appears between trust/freshness and CE2 when active

## Shared State Behavior (Ranking + Detail)

### Loading
- skeletons mirror final structure exactly

### Error
- error summary + retry in same card
- retry min `44dp` height

### Stale
- stale age in `Z0`
- interpretation note in `Z2`

## Trust Visibility Rules
- trust state always visible in ranking rows and detail top fold
- contradiction cannot be hidden behind secondary tabs
- trust and contradiction use icon/label in addition to color
