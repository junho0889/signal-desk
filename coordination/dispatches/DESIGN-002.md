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
- chart and stat-card patterns for ranking, detail, and evidence screens
- visual treatment for freshness, trust, and contradiction
- updated screen guidance that mobile implementation can follow

## Constraints
- do not fall back to generic finance-app defaults
- keep patterns viable on mobile first
- ensure the visual system supports evidence depth, not only score display

## Verification
- document consistency review against model and trust docs
- `git diff --check`

## Handoff
- identify the design tokens, chart blocks, and screen zones that app implementation should freeze next
