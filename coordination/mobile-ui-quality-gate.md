# Mobile UI Quality Gate

## Purpose
Use this checklist before calling a mobile surface polished enough for release or public-facing preview.

## Core Review Questions
- Can a first-time user understand the main action within three seconds?
- Does the screen explain why a ranked item matters without forcing a deep drill-in?
- Are trust, freshness, and evidence visible without becoming visual noise?
- Does the layout stay stable across short and long strings in Korean and English?

## Action Placement
- Primary action is visually dominant and located predictably.
- Secondary actions do not crowd the hero zone.
- Retry, refresh, and filter actions are obvious and reachable.

## Typography And Copy
- Heading, section, body, and label roles are visually distinct.
- No accidental clipping, overflow, or awkward wrapping on likely strings.
- Numeric formatting is consistent across ranking, charts, and detail views.

## Ranking Clarity
- Rank number, keyword, score, and movement cue align consistently across items.
- Trust or freshness cues support the row instead of distracting from it.
- Expanded or detailed views add evidence rather than repeat the same score in a different style.

## Chart Readability
- Chart titles state what changed, not just the metric name.
- Axes, legends, or labels are understandable on a phone-sized viewport.
- The first chart on a screen answers a real user question instead of filling space.

## State Design
- Loading skeletons mirror the final structure well enough to avoid a broken feel.
- Empty states explain what the user can do next.
- Error states expose a clear next action.
- Stale-data states explain the age of the data and the safest interpretation.

## Accessibility
- Tap targets remain comfortable.
- Contrast and text size stay readable.
- Important distinctions do not rely on color alone.

## Release Guidance
- If the answer to any core review question is no on a primary surface, treat it as a release blocker.
- If the UI is understandable but still has spacing or visual polish debt, log it as non-blocking only when user trust is not reduced.
