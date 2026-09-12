# PROJECT_STRUCTURE Template — Data pipeline / scraper + reports

Repo layout for an ingestion and report-delivery system. Adapt to chosen runtime (Python is common, Node also fine).

Target length: 200–300 lines.

## Structure

```markdown
# [Product] — Project Structure & Conventions

> Folder layout and conventions for the [Python/Node] data pipeline. Read by the coding agent as context when generating code.

## Top-Level Layout

\`\`\`
[repo-root]/
├── .github/                # CI workflows (lint, test, deploy)
├── pipelines/              # one folder per pipeline / source group
│   └── [pipeline-name]/
│       ├── fetch.py        # source-specific fetch logic
│       ├── parse.py        # raw → typed records
│       ├── transform.py    # business rules, enrichment
│       ├── load.py         # write to final destination
│       └── pipeline.py     # orchestration (calls the others)
├── shared/                 # cross-pipeline utilities
│   ├── http/               # HTTP clients; wrapper/retry/rate limit only per source contract
│   ├── proxy/              # proxy rotation (if scraping)
│   ├── storage/            # raw/staging/final storage clients
│   ├── quality/            # checks required by consumer/data-integrity contracts
│   ├── delivery/           # PDF/CSV/email output engines
│   └── observability/      # only if a material operational boundary requires it
├── reports/                # report templates (HTML, Jinja, etc.)
├── orchestrator/           # DAG definitions (Airflow/Prefect/Dagster) or cron specs
├── tests/                  # unit + integration
├── data/                   # local fixtures only — never production data
├── docs/                   # PRD, ARCHITECTURE, DECISIONS, KNOWN_ISSUES, MEMORY, etc.
└── [config files]
\`\`\`

## pipelines/{pipeline-name}/

\`\`\`
[tree showing one example pipeline's files]
\`\`\`

### Pipeline conventions

- One folder per source or tightly-coupled source group.
- Each pipeline is callable as a single entrypoint (`python -m pipelines.X.pipeline --window=...`).
- Stages are functions, not classes by default (simpler, easier to test, easier to compose).
- Each stage takes typed input and returns typed output (TypedDict / Pydantic / TypeScript types).
- No global state. Configuration flows in via parameters.

## shared/http/ — Fetch infrastructure

\`\`\`
[tree — clients plus only the retry/rate-limit helpers required by source contracts]
\`\`\`

### HTTP conventions

- Centralize a client only when shared auth, source-policy or response contracts justify it; direct calls are otherwise acceptable.
- Add retry, backoff, rate limiting and observability independently, only for the relevant source contract/risk.
- When a source requires a rate limit, scope and configure it at that source's actual boundary.

## shared/proxy/ — Proxy rotation (if scraping)

\`\`\`
[tree — proxy pool client, session management, captcha integration]
\`\`\`

### Proxy conventions

- One proxy provider integration per file. Easy to swap/add providers.
- Failed proxies are quarantined for N minutes before retry.

## shared/storage/

\`\`\`
[tree — raw_storage.py, staging.py, final.py]
\`\`\`

### Storage conventions

- Path convention is centralized: `raw/{source}/{YYYYMMDD}/{run_id}/{filename}`.
- Atomic writes: write to temp path, rename on success.
- Log storage metadata when loss/corruption/recovery risk requires operational evidence.

## shared/quality/

\`\`\`
[tree — schema validators, stats checks, anomaly detection]
\`\`\`

### Quality conventions

- Validation is pluggable per pipeline.
- Failures route to quarantine zone; runs do not silently drop records.
- Add statistical baselines only when a named quality criterion requires drift detection.

## shared/delivery/

\`\`\`
[tree — PDF generator, email sender, CSV builder, webhook poster]
\`\`\`

### Delivery conventions

- Templates live in `reports/`, separate from delivery code.
- Personalization is parameterized at delivery boundary; templates are pure.
- Persist failed deliveries or add retry only when a recovery/delivery contract requires it.

## reports/

\`\`\`
[tree — Jinja or HTML templates, asset folders]
\`\`\`

## orchestrator/

\`\`\`
[tree — DAG files, schedule config, environment-specific overrides]
\`\`\`

### Orchestration conventions

- DAG definitions live separately from pipeline code. The pipeline is invokable standalone for testing.
- Schedule is explicit (cron expressions or interval), with timezone declared.
- Concurrency limits per DAG to prevent overlap.
- Backfill is supported via parameterized run window.

## Coding Conventions

### Language-specific
- [Python: type hints required, Pydantic for I/O, ruff/black, virtualenv pinned in pyproject.toml]
- [Node: TypeScript strict, Zod for I/O, pnpm/npm pinned]

### Pipeline ergonomics
- Pipelines are runnable locally with a small fixture (`data/fixtures/`).
- A `--dry-run` flag suppresses external writes (storage, delivery) for testing.
- A `--window` parameter accepts ISO date or interval for backfill.

### Idempotency
- Same input window → same output state. Always.
- Use deterministic IDs (hashes) where natural keys are absent.

### Testing
- Add stage/integration/quality tests only for material silent data harm or an approved acceptance criterion; use the level that reaches the risky boundary.

### Observability
- Log stage/run fields and alert summaries only where a material failure could otherwise be silent or operations require recovery evidence.

### Commits & Branches
- [conventional commits, branch naming]

### Environment Variables
- Source secrets: per-source API keys, scraping API tokens.
- Storage: cloud bucket names, credentials.
- Delivery: SMTP, webhook URLs.

## Coding agent kickoff prompt template

[End-of-doc prompt template — what the user pastes into the coding agent on day one.]
```

## Writing tips

- **Pipelines as folders, not classes.** Easier to scan, easier to evolve.
- **Stages as functions.** Composition is testing's friend.
- **Idempotency is non-negotiable.** Re-runs must be safe.
- **Quality checks are part of the pipeline, not optional.** Without them, the pipeline rots silently.
