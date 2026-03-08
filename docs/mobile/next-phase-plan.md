# Mobile Next-Phase Plan

## Objective
Convert DESIGN-002 freeze output into a concise APP-007 execution plan without starting feature implementation.

## Frozen Inputs
- design freeze source: `coordination/handoffs/DESIGN-002.md`
- product constraints: `coordination/premium-mobile-brief.md`, `coordination/mobile-ui-quality-gate.md`
- mobile contract source: `docs/backend/api-contract.md` (`v1`, additive only)

## APP-007 Package Freeze
- `flex_color_scheme`
- `fl_chart`
- `flutter_localizations` (SDK)
- `intl`
- no additional UI/state framework packages in APP-007

## APP-007 Component Freeze
Implement exactly these shared components:
- `SignalDeskMetricRow`
- `SignalDeskTrustStrip`
- `SignalDeskFreshnessBadge`
- `SignalDeskTrendChartCard`
- `SignalDeskRiskCallout`
- `SignalDeskSectionCard`
- `SignalDeskStateSurface`

## APP-007 Screen-Shell Freeze
- Home: context rail, top-keyword cards, sector block, alert block, one-primary-action card taps
- Ranking: fixed row order (`rank -> name -> movement -> score -> trust/freshness -> evidence`), stable row height, period filter strip
- Detail: top fold fixed order (`movement -> trust/freshness -> contradiction -> chart`) before deeper evidence blocks
- Watchlist: same row rhythm as Ranking for keyword rows; stock rows follow same spacing and severity slot
- Alerts: severity filter strip + fixed severity/time/target row alignment

## APP-007 Implementation Order (Short)
1. apply theme/tokens/localization shell
2. add shared components
3. migrate Ranking and Detail first (highest design-risk surfaces)
4. migrate Home, Watchlist, Alerts to same shell geometry
5. verify loading/empty/error/stale states and Korean/English overflow safety

## Hard Guardrails
- do not change API shapes or enum literals
- do not re-order frozen row/shell zones by screen
- do not hide trust/freshness/risk cues behind secondary interactions
- if a required field is missing in `v1`, render placeholder state instead of inventing payload fields

## Open Contracts (Not Frozen In APP-006)
- BE-004 read-model additive fields
- MODEL-001 explanation payloads
- TRUST-001 contradiction/trust-summary payloads

APP-007 should implement only frozen package/component/shell scope above and defer open contracts.
