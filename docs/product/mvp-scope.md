# MVP Scope

## MVP Outcome
A single operator can complete a reliable daily signal review in under 10 minutes and identify what needs deeper manual research.

## In Scope (Release-1)
- Home dashboard: top signals, largest risers/fallers, and last-update context.
- Keyword ranking list: sortable/filterable ranked keywords with score and change indicators.
- Keyword detail page: score breakdown, supporting signal evidence, recent change timeline, and linked symbols.
- Personal watchlist: track selected keywords/symbols for follow-up review.
- Alert rules: server-side triggers for significant watchlist score movement, delivered as mobile push notifications.

## Out of Scope (Release-1 Exclusions)
- Any execution flow: order placement, brokerage account linking, or trade automation.
- Collaboration/social features: comments, shared watchlists, leaderboards, or publishing.
- Monetization flows: paywall, subscriptions, billing, or entitlement management.
- Conversational assistant/chatbot for investment guidance.
- Advanced analytics: portfolio attribution, backtesting suite, options analytics, or multi-strategy modeling.
- Multi-platform expansion: no end-user web app requirement in Release-1.

## MVP Feature Boundaries
- Rankings are informational and evidence-linked; they are not predictions or advice.
- Alerts are based on server-evaluated rule thresholds; client-side alert logic is excluded.
- Detail views consume precomputed derived data from API payloads; ad-hoc on-device recalculation is excluded.
- Watchlist supports personal tracking only; import/export and sharing are excluded.

## MVP Success Conditions
- Daily review loop is consistently completed within a few minutes.
- Top-ranked keywords are directionally credible to the operator.
- Alert volume remains actionable rather than noisy.
- Every ranked keyword includes enough evidence to explain why it moved.
