# Dispatch DESIGN-002

## Task
- id: DESIGN-002
- owner role: signal-desk-design
- priority: high

## Objective
Define a premium analytics visual system with charts, trust indicators, and information-dense layouts that still feel modern and MZ-friendly on mobile.

## Required Reads
- `AGENTS.md`
- `coordination/working-agreement.md`
- `coordination/premium-mobile-brief.md`
- `coordination/mobile-ui-quality-gate.md`
- `docs/design/ui-principles.md`
- `docs/design/screen-map.md`
- `docs/design/analytics-visual-system.md`
- `docs/model/ranking-roadmap.md`
- `docs/trust/trust-framework.md`
- `coordination/handoffs/MODEL-001.md` when available
- `coordination/handoffs/TRUST-001.md` when available

## Files You Own
- `docs/design/analytics-visual-system.md`
- `docs/design/screen-map.md`

## Deliverables
- foundation rules for spacing, typography, action placement, sheet behavior, and localization resilience
- ranking-list, detail, chart, and evidence-zone patterns that stay readable at phone widths
- chart and stat-card patterns for ranking, detail, and evidence screens
- visual treatment for freshness, trust, and contradiction
- updated screen guidance that mobile implementation and publisher work can follow without improvising layout rules

## Constraints
- do not fall back to generic finance-app defaults
- do not use a third-party UI kit as the visual foundation; use SignalDesk-owned rules on top of Flutter Material 3
- keep patterns viable on mobile first
- every primary screen must make the main action obvious in one glance
- avoid clever layouts that hide explanation, ranking movement, or trust cues
- ensure the visual system supports evidence depth, not only score display

## Verification
- document consistency review against model and trust docs
- document compliance review against `coordination/premium-mobile-brief.md` and `coordination/mobile-ui-quality-gate.md`
- `git diff --check`

## Handoff
- identify the design tokens, chart blocks, screen zones, and no-go anti-patterns that `APP-006` and `APP-007` must freeze next
