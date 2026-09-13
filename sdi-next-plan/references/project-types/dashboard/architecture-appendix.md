# Architecture Appendix — Dashboard / admin / internal tool

Insert these sections into ARCHITECTURE.md at §2 ("Type-specific architecture") of the core architecture template.

## §2.1 Data sources and ingestion

State the upstream data layer:

- **Primary source:** [App DB direct] / [Read replica] / [Warehouse (BigQuery/Snowflake/Redshift)] / [dbt-modeled marts] / [Multiple sources joined at query time]
- **Connection pattern:** [Direct query from server] / [API gateway with cached proxy] / [Edge function with prepared queries]
- **Aggregation tier:** raw rows vs pre-aggregated summaries — at what level (hourly cube, daily cube, on-demand)?
- **Source-specific caveats:** known slow tables, large fact tables, late-arriving data windows

## §2.2 Query and caching strategy

- **Query authoring:** [hand-written SQL in `lib/queries/`] / [ORM] / [SQL-as-code (kysely)] / [GraphQL with persisted ops]
- **Query cache:** [server-side Redis with TTL N min] / [CDN edge cache for public dashboards] / [SWR client-side only]
- **Cache invalidation:** [time-based TTL] / [event-based (DB triggers)] / [manual refresh from UI]
- **Stale-while-revalidate (if the freshness contract permits stale data):** UX shows last-known good while fetching fresh
- **Query timeout/recovery (when slow queries are reachable):** choose the least complex supported state: retry, partial result or error

## §2.3 Refresh and real-time

State how fresh the data is and the mechanism.

- **Refresh model:** [On-page-load only] / [Polling every N seconds] / [WebSocket / SSE for live counters] / [Hybrid — initial load + push for specific metrics]
- **Reconnect strategy:** if a websocket drops, what happens to the current view?
- **Time-zone handling:** server stores UTC, UI renders user/tenant timezone — confirm a single source of truth

## §2.4 Visualization layer

- **Chart library:** [Recharts] / [Tremor] / [Visx] / [ECharts] / [Plotly] / [Custom]
- **Chart kit:** what charts the design system standardizes on (line, bar, KPI tile, etc.)
- **Cross-filter / drill-down:** mechanism (URL state, store, context provider) and which charts participate
- **Data states:** design only the zero/error/slow states reachable in the approved flow

## §2.5 Filters and view state

- **State location:** [URL query params (shareable)] / [Server-stored saved views] / [Hybrid]
- **Filter dimensions:** enumerate the dimensions and their cardinality
- **Default view per role:** what the user sees on first load
- **Saved views / bookmarks:** persistence model, shareability

## §2.6 Action surface (if not read-only)

For dashboards with operational actions:

- **Action catalog:** list each mutating action — what it does, who can perform it, blast radius
- **Confirmation pattern:** modal with re-typing for destructive actions, simple confirm for low-blast
- **Audit log:** add fields/surface only when authorization, destructive impact or a production contract requires traceability
- **Rate limit / circuit breaker:** add only for a measured automated-misuse or cascade risk

## §2.7 Performance budget

| Metric | Target |
|---|---|
| Initial dashboard render | < 3s on broadband |
| Filter change response | < 1s |
| Largest single query | < 5s |
| Concurrent user ceiling (at MVP) | N |

Choose the smallest existing measurement that proves an approved performance target; do not add RUM or synthetic checks by default.

## §2.8 Export and sharing

- **Export formats:** only formats required by the product contract
- **Row limits:** prevent CSV-of-10M-rows scenarios; offer async export with email when above threshold
- **Scheduled reports:** [out of MVP] / [daily/weekly digest with chosen filters]
- **Shareable links:** [public read-only URL with token] / [auth-gated link only]
