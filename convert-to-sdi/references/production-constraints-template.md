# Production constraints template

Insert this section into both `AGENTS.md` and `CLAUDE.md` (root) after the "Project context" section when:

- Q3 = `(c) mature-production` or `(d) maintenance`, OR
- Q3 was skipped but Phase 0 auto-audit detected 3+ production indicators

Adapt examples to the project's actual stack and type. Below is the canonical template — replace bracketed placeholders with project specifics.

## Template content (paste into AGENTS.md and CLAUDE.md)

```markdown
## Production constraints (live system)

> **Source:** code analysis + user-confirmed (medium confidence). This is a live system with real users. Default postures below; override per work item only with explicit reason in DECISIONS.md.

### Schema changes
- **Backward-compatible by default.** Use additive migrations: add columns nullable or with default; deprecate before drop.
- **Never drop columns/tables in a single migration.** Two-phase: stop reading → wait → stop writing → wait → drop.
- **Renames go through additive-deprecate.** Add new column, dual-write, migrate readers, deprecate old column, drop after release window.
- **Migrations must be online for non-trivial tables.** No table locks > [N] seconds. Use `CREATE INDEX CONCURRENTLY` (Postgres) or equivalent.

### API contracts
- **Existing endpoints have external consumers.** Breaking changes require: (1) deprecation header on old endpoint, (2) timeline communicated, (3) consumer notification (email, status page, or contractual channel).
- **Versioning:** [URL-based `/v1/`, header-based, none — fill per project]. New breaking behavior under new version, never silently mutate `v1`.
- **Response shape stability:** new fields OK; removing or renaming fields requires the deprecation cycle above.

### Feature gating
- **New behavior ships behind a feature flag by default.** Default-off for existing users; can default-on for new users in [feature flag system: LaunchDarkly / GrowthBook / custom].
- **Flag removal cycle:** flag → roll out → bake → remove flag. Don't leave permanent flags as on/off switches without rationale in DECISIONS.md.

### Migrations on production tables
- **Online migration patterns required.** No exclusive locks on tables with >[N] rows or active write traffic.
- **Backfills run async.** Long-running backfills run as background jobs, paginated, idempotent. Never inline in a migration.
- **Test migration on a recent production-data clone before deploying.** [Tooling: pgcopydb / Supabase clone / custom — fill per project].

### Observability before code
- **Alerts/logs/metrics for new code paths exist before merge.** No "ship code now, add observability later" — that pattern fails silently in production.
- **New endpoints/handlers/jobs:** structured log on entry + exit, error path captured to [Sentry/Datadog/etc.], latency metric with appropriate dimensions.
- **Cost monitoring** for any new external API call (LLM, payment, comms): per-call cost logged, daily aggregate visible.

### On-call awareness
- **Runbooks live in [location: docs/runbooks/, Notion, Confluence — fill per project].**
- **On-call rotation tooled via [PagerDuty / Opsgenie / custom — fill per project].**
- **New code that can page on-call must have a runbook entry** before merge. Otherwise silent toil for whoever responds.

### Critical paths that MUST NOT break

> Populate as discovered. Each entry: (1) the path/flow, (2) what happens if it breaks, (3) how to verify it's still working post-change.

- [Example: `POST /api/webhooks/billing/stripe` — receives Stripe events for paid customers. If broken, billing state diverges from Stripe within minutes; revenue + customer trust at risk. Verify post-change: signature verification test against Stripe CLI sample event + integration test on a sandbox account.]
- [Example: `multi-tenant signup flow at /signup` — new customer onboarding. If broken, no new revenue lands. Verify post-change: smoke test from clean browser, complete to dashboard.]
- ...

### Test data isolation
- **Production data never used in dev/staging directly.** Use scrubbed clones or synthetic data.
- **PII handling:** [scrubbing helpers location — fill per project]. Logs must redact PII before exiting the process boundary.

### Deployment cadence
- **Deploy windows:** [no Friday afternoon deploys / freeze on Mondays / etc. — fill per project].
- **Rollback procedure:** [tooling and steps — fill per project].
- **Feature freezes:** [if applicable — e.g. "no merges to main during quarter-end financial close (last week of Mar/Jun/Sep/Dec)"].
```

## Type-specific additions

Append the relevant block based on the project type. Insert after the "Critical paths" section and before "Test data isolation".

### For Web SaaS multi-tenant

```markdown
### Multi-tenant invariants
- **Every multi-tenant query goes through tenant-resolved auth context.** Never trust `tenant_id` from request body or query string.
- **Cross-tenant data leakage is a P0 incident.** Add a regression test for any code path that touches multiple tenants.
- **Service-role / admin queries** are rare and audited. Each call site is documented in DECISIONS.md.
```

### For Web API / backend service

```markdown
### API stability
- **API key revocation must propagate within [N] seconds.** Cache TTLs respect this.
- **Rate limit changes require deprecation cycle** for paid tiers (notify before tighter, no notice for looser).
- **Webhook signature verification** is non-negotiable. Don't accept unsigned webhooks even in fallback paths.
```

### For Data pipeline / scraper

```markdown
### Pipeline safety
- **Backfills are idempotent.** Re-running a window must produce identical final-table state.
- **Schema changes to source data** detected at ingest boundary; failed records go to quarantine, never to staging silently.
- **Output deliverables** (PDFs, emails, downstream API calls) — failures alert; no silent drops.
```

### For AI agent / MCP server / chatbot

```markdown
### AI safety in production
- **Cost ceiling per session enforced.** Hard kill switch when [$X] exceeded; user-facing graceful degradation message.
- **Prompt-injection defenses** validated on every change to system prompt or tool surface.
- **Tool authorization changes** require explicit DECISIONS entry. New high-blast tool? User-confirmation flow first.
- **Eval regression blocks merge** when score drops on golden set.
```

### For Mobile app

```markdown
### Mobile production constraints
- **OTA updates: JS-only.** Native module changes ship via store releases.
- **API breaking changes** must be backward-compatible with the longest-supported app version still in stores (typically [N] versions back).
- **Crash reports** from new versions reviewed within [N] hours of release.
```

### For Integration / automation workflow

```markdown
### Workflow reliability
- **Idempotency keys** required on every external write step.
- **Retry policies** explicit per step; no infinite-retry defaults.
- **DLQ depth** monitored; growth triggers alert.
- **Concurrency limits** per workflow type prevent cascade failures during partner-side incidents.
```

## How the user fills the placeholders

After convert-to-sdi runs, the user reads `AGENTS.md` or `CLAUDE.md` and replaces brackets:

- `[N]` thresholds with project-specific numbers
- `[location]` placeholders with their actual paths
- `[tool]` placeholders with their actual tool names
- The "Critical paths" section with their actual critical paths

This is intentional — the framework can't know these without asking. Encourage the user to fill the most load-bearing placeholders before starting the first work item; the rest can fill in over time.

## When to skip this section

- Q3 = `(a) greenfield-mvp` AND no production indicators detected. There are no production constraints because there's no production.
- Q3 was skipped AND <3 production indicators. Default to skipping; user can add later if needed.

If unsure, **include it** with low-confidence flag — over-cautious is safer than under-cautious in production.
