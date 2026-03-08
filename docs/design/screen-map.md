# Screen Map

## Scope
This update defines only APP-critical blueprints for:
- Keyword Ranking
- Keyword Detail
- Keyword Detail Evidence View
- shared state surfaces for those views

## Shared Blueprint Rules
- horizontal padding: `16dp`
- section gap: `16dp`
- card padding: `12dp`
- min touch target: `44dp`
- fixed zone order on these surfaces:
  - `Z0` context rail
  - `Z1` header
  - `Z2` trust/freshness strip
  - `Z3` primary chart/metric
  - `Z4` evidence stack
  - `Z5` actions

## Keyword Ranking

API mapping:
- `GET /keywords.generated_at` -> `Z0`
- `GET /keywords.items[]` -> row list
- `GET /keywords.next_cursor` -> pagination
- controls: `period`, `market`, `sector`, `cursor`

Layout blueprint:
- `Z0`: sticky context rail with generated time + scope
- filter strip directly under `Z0`, sticky, min height `44dp`
- collapsed row (min `104dp`) fixed order:
  1. rank + keyword (1-line clamp)
  2. movement (`score`, `delta_1d`)
  3. trust/freshness cue
  4. evidence cue (`reason_tags`, related sector)
- row gap `8dp`

Actions:
- primary: full-row tap -> Keyword Detail
- secondary: sticky filter controls

Lock rules:
- score/delta/trust positions never move by row
- long strings truncate, never change row geometry

## Keyword Detail

API mapping:
- `GET /keywords/{keyword_id}.generated_at` -> `Z0`
- `score_summary` -> S1/S2/S3/C3
- `timeseries[]` -> C2
- `reason_block`, `risk_flags` -> `Z2`/`Z4`
- `related_stocks[]`, `related_sectors[]` -> C6
- `POST /watchlist` -> `Z5`

Layout blueprint:
- `Z0`: context rail with freshness age
- `Z1`: keyword header + S1 movement card
- `Z2`: S2 trust and S3 freshness cards in two columns
- `Z3`: conditional S4 contradiction + C2 chart
- `Z4`: C3 contribution + reason block + C6 links
- `Z5`: watchlist action slot

Actions:
- primary: trailing `Add/Remove Watchlist` button (min `44dp` height, `120dp` width)
- same action persists as sticky bottom action after first major scroll break
- secondary: contradiction jump + related entity taps

Lock rules:
- top fold must include S1, S2/S3, and C2 before deep evidence content
- contradiction card appears between trust/freshness and chart when active

## Keyword Detail Evidence View

API mapping:
- `related_news[]` -> C5 timeline + evidence rows
- `risk_flags` -> contradiction markers
- `generated_at` + `published_at` -> freshness context

Layout blueprint:
- `Z1`: evidence header and freshness summary
- `Z2`: trust/freshness/contradiction strip
- `Z3`: C4 source mix ribbon
- `Z4`: C5 timeline + grouped evidence rows
- `Z5`: row trailing source-open controls

Actions:
- primary: open source link from row trailing action
- secondary: contradiction filter toggle

Lock rules:
- newest-first evidence order
- contradiction-marked rows pinned to top within each source group

## Shared State Surfaces (Ranking + Detail + Evidence)

### Loading
- skeleton structure mirrors final geometry exactly

### Empty
- one explanation sentence
- one next-step action

### Error
- error summary + retry in same card
- retry min `44dp` height

### Stale
- stale age shown in `Z0`
- interpretation note shown in `Z2`
