# Auto-audit checklist (Phase 0)

This is the programmatic scan the skill runs against the repo before asking the user anything. Each detection produces a confidence level (high / medium / low) based on signal strength.

The output of this phase is a **discovery report** shown to the user, not artifacts. Artifact generation happens in Phase 2.

## Project type detection

Map the repo to one of the 8 framework types. Heuristics:

| Type | Strong signals | Medium signals |
|---|---|---|
| **Web SaaS multi-tenant** | `next.config.*` + auth provider (clerk, supabase auth, nextauth) + multi-tenant schema patterns (`organization_id` columns) + billing integration (stripe) | `next.config.*` + auth + DB but tenancy unclear |
| **Landing page / marketing** | `astro.config.*`, `next.config.*` with `output: 'export'`, `gatsby-config.*`, `hugo.toml` + content-heavy `pages/` or `content/` directory + no auth | Static-site framework + no DB |
| **Dashboard / admin / internal tool** | Frontend framework + heavy charting libs (recharts, tremor, visx, echarts) + data fetching from analytics/warehouse | Internal-tool naming patterns + auth gate but minimal user signup flow |
| **Web API / backend service** | `package.json` with hono/express/fastify/koa OR `pyproject.toml` with fastapi/flask/django-rest + no UI directory | Backend framework + webhook handlers + no `pages/`/`app/` |
| **Mobile app** | `pubspec.yaml` (Flutter), `react-native.config.*`, `App.swift`/`MainActivity.kt` (native), `ios/`+`android/` folders | Expo config + RN dependencies |
| **Data pipeline / scraper** | Orchestrator config (airflow, prefect, dagster, inngest cron), scraping libs (playwright, scrapy, puppeteer), `pipelines/` directory | Cron + ETL libs + no UI |
| **AI agent / MCP server / chatbot** | MCP server signature (`@modelcontextprotocol/sdk`), agent SDKs (`@anthropic-ai/sdk` with tool-use loops), `prompts/`, `evals/` | LLM SDK + system prompt files |
| **Integration / automation workflow** | Inngest functions, Temporal workflows, Trigger.dev tasks, n8n custom nodes + multi-step flow definitions | Webhook handlers + queue config + multi-API integration code |

If signals overlap (common — a web SaaS often has admin dashboard inside it), pick the **dominant** type and note the secondary in the discovery report. Confidence: high if strong signals present; medium if only medium signals; low if heuristics conflict.

## Stack detection

| Layer | Signals to detect |
|---|---|
| Language | `package.json` → JS/TS; `pyproject.toml`/`requirements.txt` → Python; `go.mod` → Go; `Cargo.toml` → Rust; `pubspec.yaml` → Dart; `composer.json` → PHP |
| Framework | top-level config files (`next.config.*`, `vite.config.*`, `nuxt.config.*`, `astro.config.*`, `remix.config.*`, `svelte.config.*`); `package.json` deps |
| ORM / DB layer | `drizzle.config.*` → Drizzle; `prisma/schema.prisma` → Prisma; `alembic/` → SQLAlchemy; `knexfile.*` → Knex; raw SQL in `migrations/` → custom |
| Database | env var names (`DATABASE_URL`, `POSTGRES_URL`, `MONGODB_URI`, `REDIS_URL`); ORM config; docker-compose services |
| Auth | `@clerk/*`, `@supabase/auth-*`, `@auth/*`/`next-auth`, `@workos-inc/*`, custom JWT helpers in `src/lib/auth/` |
| Deployment | `vercel.json`, `fly.toml`, `railway.toml`, `netlify.toml`, `Dockerfile`, `eas.json`, GitHub Actions deploy workflows |
| Observability | `@sentry/*`, `@opentelemetry/*`, `posthog-*`, `datadog-*`; env vars (`SENTRY_DSN`, `POSTHOG_KEY`) |
| Feature flags | `@launchdarkly/*`, `@growthbook/*`, `unleash-client`, custom flag service modules |

Confidence: high when both manifest and config file confirm; medium when only one signal; low when inferring from filenames.

## Conventions detection

- **Top-level layout**: tree to depth 2, listing top-level directories with their content type.
- **File-naming patterns**: kebab-case vs camelCase vs PascalCase per directory; `*.test.ts` vs `*.spec.ts` test conventions.
- **Linting / formatting**: presence of `.eslintrc.*`, `.prettierrc.*`, `ruff.toml`, `pyproject.toml [tool.ruff]`, `biome.json`.
- **Test runner**: `vitest.config.*`, `jest.config.*`, `pytest.ini`, `playwright.config.*`.
- **TypeScript**: `tsconfig.json` strict mode, `noUncheckedIndexedAccess`, paths aliases.
- **Commit conventions**: scan `git log --oneline -50`. Detect conventional commits, semantic prefixes (`feat:`, `fix:`, `chore:`).
- **Branch model**: scan `git branch -a`. Detect `main`/`master`/`develop` patterns, feature-branch conventions.

## Existing docs detection

Read and **classify** any existing canonical artifacts. Detection has two parts: (1) presence, (2) format compatibility — both feed Phase 1.5 (`existing-artifact-handling.md`).

### Files to check

For each, record `present: yes/no` and `compatibility: compatible / partially-compatible / incompatible / n/a`:

- `README.md` — at root
- `PRD.md`, `ARCHITECTURE.md`, `ROADMAP.md`, `PROJECT_STRUCTURE.md`, `DESIGN_SYSTEM.md`, `KNOWN_ISSUES.md`, `DECISIONS.md` — at root or in `docs/`
- `AGENTS.md`, `CLAUDE.md` — at root
- `CHANGELOG.md` — at root
- `docs/decisions/` or `docs/adr/` — ADR folder (count files; check if `0001-...md` numbering)
- `docs/runbooks/`, `docs/onboarding/`, etc. — custom doc folders (just inventory)
- All other `docs/*.md` files — list as "custom docs"

### Format compatibility heuristics

For canonical artifacts, after reading the file, classify compatibility per the rules in `existing-artifact-handling.md` §"Format compatibility detection". Quick reference:

| Artifact | Compatible if has | Partially if missing | Incompatible if |
|---|---|---|---|
| `README.md` | summary + stack table + doc links (3 of 3) | 2 of 3 | <2; pure clone instructions |
| `PRD.md` | sections matching: goal, users, in-scope, out-of-scope, success metrics (5 of 5) | 3+ of 5 | <3; pure prose without sections |
| `ARCHITECTURE.md` | tech stack + critical flows/overview + trade-offs (3 of 3) | 2 of 3 | <2; pure decision list (treat as ADR) |
| `ROADMAP.md` | phases/cycles/quarters with deliverables + acceptance criteria | phases without AC | pure backlog list, Trello/CSV export, no sequence |
| `PROJECT_STRUCTURE.md` | directory tree + conventions section | one of two | prose without structure |
| `DESIGN_SYSTEM.md` | tokens (color/typography/spacing) + 2+ of {layout, motion, a11y, components} | tokens only | aesthetic prose without tokens |
| `KNOWN_ISSUES.md` | append-only `KI-NNN` entries or empty scaffold with format/status/severity legend | issue list exists but format varies | prose bug list with no lifecycle/status/evidence |
| `AGENTS.md` / `CLAUDE.md` | project context + document map + work tracker, with no embedded discipline (no 8-step list, no tone/precedence/checkpoint instructions) | framework-aware but missing pieces, contains residual discipline that needs to be stripped, or one file is still a pointer | not framework-aware |
| `DECISIONS.md` (single file) | numbered entries with Context/Decision/Rationale | entries with format variance | prose without entries |

For non-canonical artifacts (CHANGELOG, runbooks, custom `docs/*.md`), compatibility is `n/a` — they're preserved unconditionally per Strategy A.

### Don't overwrite checks

Hard rules even before Phase 1.5:

- If `AGENTS.md` and `CLAUDE.md` already exist with **compatible** structure (facts-only, same canonical project-fact content), still show the Phase 1.5 matrix. Recommend Strategy A / no material change for those files and explain that the project already appears framework-adopted; do not skip the matrix.
- If any canonical artifact is **compatible** → default to Strategy A (preserve + framework header) in the matrix.
- Never silently overwrite. **Always** route through Phase 1.5 if any canonical artifact is detected.

### Output in discovery report

Add a section to the discovery report (per `auto-audit-checklist.md` §"Discovery report format"):

```markdown
## Existing canonical artifacts

| File | Present | Compatibility | Notes |
|---|---|---|---|
| `README.md` | yes | compatible | has summary + stack + doc links |
| `docs/ARCHITECTURE.md` | yes | partially compatible | has stack + flows; missing trade-offs |
| `docs/ROADMAP.md` | yes | incompatible | Trello CSV export — no phase structure |
| `docs/decisions/` | yes (12 ADR files) | special: ADR | preserve — see Phase 1.5 |
| `docs/PRD.md` | no | n/a | will be generated thin in Phase 2 |
| `docs/KNOWN_ISSUES.md` | no | n/a | will be generated as empty scaffold in Phase 2 |
| `AGENTS.md` | no | n/a | will be generated in Phase 2 |
| `CLAUDE.md` | no | n/a | will be generated in Phase 2 with same content as `AGENTS.md` |

## Other docs detected

- `CHANGELOG.md` — preserved as-is (production indicator)
- `docs/runbooks/` (3 files) — custom; preserved + linkable in AGENTS.md / CLAUDE.md doc map
```

This section triggers Phase 1.5 (the existing-artifact-triage phase) whenever any canonical artifact is present, including when every detected artifact is `compatible` and the recommended action is simply Strategy A. Skip Phase 1.5 only when no canonical artifacts are present at all. Compatible artifacts still deserve a visible matrix so the user sees exactly what will be preserved, minimally touched, or left alone.

See `existing-artifact-handling.md` for the full Phase 1.5 protocol and the four canonical strategies (A/B/C/D).

## Production indicators

Strong signals the project is in production with real users:

- **Semver tags**: `git tag -l 'v*'` returns multiple tags (especially crossing major versions like `v1.0.0`, `v2.0.0`)
- **CHANGELOG with multiple releases**: dated entries spanning 6+ months
- **Monitoring/observability config**: Sentry DSN, Datadog API key, OTel exporter — present and not commented out
- **Feature flag system**: real flag service (LaunchDarkly, GrowthBook, Unleash, Statsig), not just env booleans
- **Customer-facing patterns**:
  - Billing/subscription code (Stripe customers, subscription tables)
  - Multi-tenancy enforced (tenant_id columns, RLS policies)
  - Email service for transactional sends (SendGrid, Resend, Postmark)
  - Analytics events fired at user actions
- **Compliance signs**: GDPR/cookie consent code, data retention helpers, audit log tables, PII scrubbing utilities
- **On-call infrastructure**: PagerDuty/Opsgenie integration, runbook references in docs, SLO/SLA mentions

If 3+ strong signals present → likely **mature production**. 1–2 → **mvp-launched**. 0 → likely greenfield-mvp.

This auto-detection is one input to Q3 in Phase 1 — the user confirms or corrects.

## AI modifier detection

Auto-set the AI modifier if any of these are present:

- LLM SDKs: `@anthropic-ai/sdk`, `openai`, `@google/generative-ai`, `langchain*`, `llamaindex*`, `vercel ai`, `@cloudflare/ai`
- `prompts/` directory with markdown files
- `evals/` directory
- Tool-use loop patterns in code (`tool_choice`, `function_call`, agent iterators)
- Vector store libs: `pinecone-client`, `qdrant-js`, `@chromadb/*`, `pgvector` extension

If detected, `AI modifier = yes` is the default; user may override in Q2 of Phase 1.

## Discovery report format

After running the audit, produce a structured report shown to the user:

```markdown
# Discovery report — [project root name]

> Generated by convert-to-sdi Phase 0 auto-audit. Confirm or correct in Phase 1.

## Project type
**Detected:** [Type] (confidence: high/medium/low)
**Reason:** [signals that drove the detection]
**Secondary type signals:** [if applicable, e.g. "dashboard within web SaaS"]

## Stack
| Layer | Detected | Confidence |
|---|---|---|
| Language | [TypeScript] | high |
| Framework | [Next.js 15 App Router] | high |
| ORM | [Drizzle] | high |
| Database | [Postgres via Supabase] | high |
| Auth | [Supabase Auth] | medium |
| Deployment | [Vercel] | high |
| Observability | [Sentry, PostHog] | high |
| Feature flags | [none detected] | n/a |

## Conventions detected
- File naming: kebab-case in `src/app/`, camelCase in `src/lib/`
- Test runner: vitest (unit + integration configs)
- Linting: eslint + prettier
- TypeScript strict mode: yes
- Commits: conventional commits style

## Existing docs found
- README.md (will be preserved; product summary extracted)
- docs/ folder with [N] files (will be preserved)
- CHANGELOG.md (5 entries spanning 8 months — production indicator)
- AGENTS.md / CLAUDE.md: not present

## Production indicators
**Stage suggestion: mature-production** (3 strong signals)
- Sentry + PostHog active
- CHANGELOG with multiple releases
- Multi-tenancy code with tenant_id columns

## AI modifier
**Auto-detected: no** (no LLM SDKs, no prompts/, no evals/)

## Anything unusual
- [list anomalies, e.g. "two test runners (vitest + jest) — possible migration in progress"]
- [or: "none"]
```

The user reads this report and either confirms in Phase 1 or corrects specific fields. Phase 1's questions reference the report.
