# Analytics Visual System

## Scope
Production polish rules for primary mobile surfaces:
- Home
- Ranking
- Detail
- Watchlist
- Alerts
- shared loading, error, stale, and trust surfaces

## Non-Negotiables
- no generic finance-app clone styling
- no row layout shifts between items
- one obvious primary action per screen
- no chart requiring legend-first interpretation
- no Korean or English overflow/clipping

## Core Tokens
- spacing scale: `4, 8, 12, 16, 24, 32`
- horizontal screen padding: `16dp` (all primary surfaces)
- section gap: `16dp`
- card padding: `12dp`
- primary radius: `14dp`
- secondary radius: `10dp`
- minimum tap target: `44dp`

## Typography And Formatting
- `hero_value`: 24/28 semibold with tabular numerals
- `section_title`: 17/22 semibold
- `body`: 14/19 medium
- `label`: 12/16 medium
- `micro`: 11/14 medium
- no all-caps labels in body content
- `score`: signed or unsigned with 2 decimals
- `delta_1d`: signed with 2 decimals
- `confidence`: percentage with one-decimal precision
- null display only: `-` or `insufficient data`

## Breakpoint Contract
- `BP-compact`: `320-360dp` width
- `BP-standard`: `361-412dp` width
- `BP-wide`: `413dp+` width

Rules:
- no horizontal scrolling on primary content
- top-fold must preserve hierarchy at every breakpoint
- multiline clamps:
  - keyword and sector label: 1 line
  - alert message: 2 lines
  - evidence title: 2 lines

## DESIGN DEFECT LIST
Observed defects from current mobile implementation and frozen docs.

| defect_id | screen | defect | impact |
|---|---|---|---|
| `D-001` | Home | long metric strings are packed into one subtitle block (`score/delta/confidence/reasons/risk`) | weak hierarchy and low scan speed |
| `D-002` | Home | generated timestamp is raw ISO text without freshness framing | stale vs fresh state is unclear |
| `D-003` | Ranking | filter row is not sticky and only exposes period | filtering control consistency breaks while scrolling |
| `D-004` | Ranking | row content is text-dense multiline subtitle without fixed visual slots | score/trust/evidence are hard to compare row-to-row |
| `D-005` | Detail | top fold lacks explicit chart block and two-card trust/freshness structure | "why now" is not answered quickly |
| `D-006` | Detail | watchlist action appears only at content tail | primary action discoverability is weak |
| `D-007` | Watchlist | severity shown as plain trailing text with no grouped urgency | triage is slow and visually ambiguous |
| `D-008` | Alerts | severity list uses raw text hierarchy and long ISO timestamps | critical alerts are not visually dominant |
| `D-009` | Shared | padding and card margins use mixed values (`12dp` and `16dp`) across screens | rhythm inconsistency and reduced polish |
| `D-010` | Shared | Korean/English text-fit rules are not enforced in row and tile subtitles | clipping/awkward wraps likely on long strings |
| `D-011` | Shared | chart clarity rules exist in docs but are not tied to implementation acceptance checks | chart readability can regress silently |

## APP-READY FIX SPEC
Use this as implementation freeze guidance for mobile polish.

### F1 Hierarchy And Readability
- replace dense subtitle paragraphs with slot-based rows:
  - slot A: title and rank
  - slot B: movement (`score`, `delta_1d`)
  - slot C: trust/freshness
  - slot D: evidence/risk summary
- move generated time into a context rail with relative freshness text
- render severity as badge/chip style, not plain trailing text

### F2 Spacing And Layout
- enforce `16dp` horizontal padding on all main scroll surfaces
- keep row vertical gap at `8dp`; section gap at `16dp`
- avoid mixed outer margins by standardizing list cards to:
  - horizontal margin `16dp`
  - vertical margin `4dp`

### F3 Button Placement
- Home: primary action button at end of top-keyword zone (`View full ranking`)
- Ranking: full-row tap remains primary; filters remain sticky and reachable
- Detail: primary watchlist action in top fold and mirrored as sticky bottom action
- Watchlist: add explicit trailing quick action (remove or manage) per row
- Alerts: row tap opens detail when keyword exists; otherwise opens alert detail panel

### F4 Korean Text-Fit
- enforce line clamp and overflow behavior:
  - keyword/sector labels `maxLines=1`, ellipsis
  - alert messages and reason summaries `maxLines=2`, ellipsis
- keep chip labels padded for Korean characters (`horizontal >= 8dp`)
- avoid uppercase transforms in dynamic labels

### F5 Chart Clarity
- `CE1` ranking sparkline required in ranking row movement zone (`88x28dp`)
- `CE2` detail trend chart required in detail top fold (`168dp` height)
- each chart must show:
  - explicit title with interpretation context
  - first and last value labels
  - non-color-only differentiation (line style or marker shape)
- if chart data is missing, render neutral fallback with `insufficient data`

### F6 Trust And Risk Visibility
- trust state must be visible in ranking row and detail top fold
- contradiction state cannot be hidden behind tabs
- stale age and interpretation note must appear together on each primary screen

## Acceptance Gate For Mobile
- first-time user can identify primary action within 3 seconds on each screen
- score, delta, and trust cues remain in fixed positions between list rows
- no clipping or overflow for long Korean and English samples at all breakpoints
- stale, error, and retry states are reachable with one hand
- first visible chart on a screen answers a user question without opening legend help
