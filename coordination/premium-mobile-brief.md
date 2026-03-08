# Premium Mobile Brief

## Goal
SignalDesk should feel like a serious intelligence product, not a stitched-together hobby dashboard. Every primary screen must communicate trust, hierarchy, and control in one glance.

## Foundation Decisions
- Base the product on Flutter Material 3 plus SignalDesk-owned tokens and components.
- Use `flex_color_scheme` for theme shaping and `fl_chart` for chart rendering when the mobile lane reaches implementation.
- Treat third-party UI kits as inspiration only. Do not make them the app shell.

## Non-Negotiables
- no generic finance-app clone styling
- no mystery actions or floating controls with unclear meaning
- no ranking rows that shift layout between items
- no chart blocks that require the user to decode the legend before understanding the message
- no overflow-prone text treatments that collapse in Korean or English

## Layout Rules
- Use a tight but intentional spacing scale: `4, 8, 12, 16, 24, 32`.
- Default horizontal screen padding should resolve to one stable rule per surface, not ad hoc values.
- Each screen gets one obvious primary action. Secondary actions should never compete visually with the main path.
- Filters, periods, and sort controls must stay predictable across ranking surfaces.
- Bottom sheets and modal surfaces should be reserved for clear, reversible tasks, not essential reading.

## Typography Rules
- Headline, section, body, and micro-label roles must be explicit and reused consistently.
- Avoid all-caps labels and decorative type treatments.
- Define truncation rules for keyword names, source labels, and evidence snippets before implementation.
- Design for Korean and English from the start. Do not assume English string length.

## Ranking Surface Rules
- Each ranking row should keep a fixed reading order: rank, name, movement cue, score, trust or freshness cue, then supporting evidence or sector context.
- Score, delta, and trust signals must never swap positions between rows.
- If a row is expandable, the collapsed state must still answer why the item matters.
- Freshness and contradiction should read as evidence quality cues, not decorative badges.

## Detail Surface Rules
- Top section should explain why the signal matters now.
- Evidence, trust, and chart zones should have stable order and visual weight.
- Statistics must support the narrative rather than appear as unlabeled numbers.
- Risk and contradiction callouts should be prominent without overwhelming the core signal.

## State Rules
- Loading, empty, error, stale, and retry states are first-class design surfaces.
- Skeletons should match final geometry closely enough that layout shifts do not feel broken.
- Retry controls must be obvious and reachable with one hand.
- Stale data needs a calm but explicit treatment that tells the user what is old and what still remains trustworthy.

## Accessibility And Comfort
- Minimum tap targets must remain comfortable on phones.
- Contrast must stay readable in bright environments.
- Charts should survive color-vision differences by using shape, position, or labels in addition to color.
- Dense screens must still preserve breathing room around the most important elements.

## Deliverable Expectations
- `DESIGN-002` freezes the visual rules, component patterns, and anti-patterns.
- `APP-006` translates those rules into implementation sequencing and component boundaries.
- `APP-007` implements the baseline without improvising new rules.
- `QA-005` verifies that the app still feels deliberate under runtime conditions.
