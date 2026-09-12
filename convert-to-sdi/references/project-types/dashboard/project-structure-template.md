# PROJECT_STRUCTURE Template — Dashboard / admin / internal tool

Repo layout for a dashboard or internal tool. Adapt to chosen framework.

Target length: 200–300 lines.

## Structure

```markdown
# [Product] — Project Structure & Conventions

> Folder layout and conventions for the [Next.js / Remix / SvelteKit / etc.] dashboard. Read by the coding agent as context when generating code.

## Top-Level Layout

\`\`\`
[repo-root]/
├── .github/                # CI workflows
├── public/                 # static assets
├── src/
│   ├── app/                # routes (or pages/ if classical)
│   ├── components/
│   │   ├── ui/             # primitives (Button, Card, Badge, etc.)
│   │   ├── charts/         # chart wrappers + theme adapters
│   │   ├── tables/         # data table primitives
│   │   └── layout/         # shell, nav, sidebar
│   ├── queries/            # data fetching — one file per logical query
│   ├── lib/                # domain helpers, formatters, auth
│   ├── filters/            # filter definitions + serialization
│   ├── actions/            # operational mutations (if not read-only)
│   ├── hooks/              # data + UI hooks (useDashboardQuery, useFilter)
│   └── types/              # shared TS types
├── tests/
├── docs/
└── [config files]
\`\`\`

## src/app/ (or pages/) — Routes

\`\`\`
[tree — overview, per-feature dashboards, drill-downs, settings]
\`\`\`

### Page conventions

- Each dashboard page sets a layout that includes filter bar + chart grid.
- Filter state lives in URL. Components read from URL, not from local state.
- Pages declare their data dependencies via the queries they import; no inline fetch in components.

## src/queries/ — Data fetching

\`\`\`
[tree — one query per file: usersByDay.ts, revenueByCohort.ts, etc.]
\`\`\`

### Query conventions

- Each file exports: query name, parameter schema (Zod), execute function, return type.
- Queries are pure data fetchers — no formatting, no UI logic.
- Server components / loaders import queries; client components read from hooks.
- Slow queries (>1s typical) are tagged so the UI can render skeletons appropriately.

## src/components/charts/

\`\`\`
[tree — LineChart, BarChart, KpiTile, FunnelChart wrappers]
\`\`\`

### Chart conventions

- App code imports our wrappers, not the underlying library directly. Provider swaps stay surgical.
- Empty state, loading state, error state are first-class — every chart accepts these props.
- Theme integration: charts read from CSS tokens, not hardcoded colors.

## src/components/tables/

\`\`\`
[tree — DataTable, Pagination, ColumnHeader, Row]
\`\`\`

### Table conventions

- Columns declared as a config array, not inline JSX.
- Pagination strategy is consistent across tables (cursor-based preferred).
- Bulk actions use a single component pattern (selection state + action menu).

## src/filters/ — Filter system

\`\`\`
[tree — filter definitions, URL serialization, default values]
\`\`\`

### Filter conventions

- Each filter has: id, label, type (date-range, single-select, multi-select), default value.
- Serialization to URL is centralized in one helper; components don't touch URL directly.
- Saved views (if applicable) store the filter set as JSON keyed by user.

## src/actions/ — Mutations (if not read-only)

\`\`\`
[tree — one file per action: suspendUser.ts, refundOrder.ts]
\`\`\`

### Action conventions

- Each action: name, input schema, permission check, execute, audit log emit.
- Destructive actions require explicit confirmation token in the input (forces UI to ask).
- Actions enter the audit log when authorization, destructive impact or a production contract requires traceability.

## Coding Conventions

### Framework idioms
- [Next.js: Server Components for read-heavy pages, Server Actions for mutations]
- [Remix: loaders for data, actions for mutations, forms for everything]
- [SvelteKit: load functions, form actions]

### TypeScript
- Strict mode. Query inputs/outputs typed. No `any` in production code.

### Auth and roles
- Auth check is middleware-level, not per-page.
- Role check is per-action (server-side) and per-component (UI gating). Never trust the UI gating alone.

### Performance
- Skeleton loaders match final layout (prevent CLS).
- Large tables use virtualization.
- Initial page renders the most important chart first; secondary charts can lazy-load.

### Testing
- Add unit/integration/visual tests only for material silent harm or an approved acceptance criterion; choose the level that exercises the risky boundary.

### Commits & Branches
- [conventional commits, branch naming]

### Environment Variables
- DB / warehouse: `DATABASE_URL`, `WAREHOUSE_URL`.
- Cache: `REDIS_URL` (if applicable).
- Auth: provider-specific keys.

## Coding agent kickoff prompt template

[End-of-doc prompt template — what the user pastes into the coding agent on day one.]
```

## Writing tips

- **Queries are the spine.** Treat them as first-class modules, not glue code.
- **Filters in URL, not state.** Shareability matters more than ergonomics.
- **Actions get proportionate safeguards.** Confirmation, audit and rate limits follow destructive impact, authorization risk and production constraints.
- **Empty/loading/error states are designed, not afterthoughts.**
