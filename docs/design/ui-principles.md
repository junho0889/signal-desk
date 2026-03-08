# UI Principles

## Product Feel
SignalDesk UI is fast, dense, and evidence-first.
The app should feel like a compact research console for one operator, not a social or promotional finance app.

## Core UX Outcomes
- complete the daily review loop in under 10 minutes
- make score movement and evidence readable in one glance
- keep watchlist and alerts as review prompts, never trade instructions

## Information Hierarchy
1. movement context: `score`, `delta_1d`, `rank_position`
2. trust context: `confidence`, `is_alert_eligible`, `risk_flags`
3. evidence context: `reason_tags`, related news/stocks/sectors
4. follow-up actions: watchlist add/remove and alert review

## Mobile Layout Rules
- target one-thumb scanning first; no screen requires horizontal scrolling
- show the top decision fields above the fold on every primary screen
- keep list rows compact and deterministic (same field order per row)
- use progressive disclosure for secondary evidence details

## Data Presentation Rules
- all score values use consistent decimal precision in UI labels
- nullable values must render explicit placeholders (`-` or `insufficient data`)
- empty arrays are rendered as neutral empty states, not errors
- `risk_flags` always use warning styling and are never hidden
- `is_alert_eligible=false` must be visible in detail/watchlist context

## Interaction Rules
- Home to Detail path: max 2 taps
- Ranking filters (`period`, `market`, `sector`) remain visible while scrolling results
- watchlist add/remove actions must be reversible without page exit
- alerts list must support quick severity triage and direct detail navigation

## Motion And Feedback
- prefer immediate state feedback (<300ms perceived response)
- avoid decorative transitions that delay list scanning
- reserve high-emphasis motion/color for alert and risk states only

## Scope Guardrails
- no portfolio analytics, broker actions, or social sharing controls
- no client-side recomputation of scoring logic
- no UI pattern that implies trade advice or automated execution
