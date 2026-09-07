# Architecture Appendix — Data pipeline / scraper + reports

Insert these sections into ARCHITECTURE.md at §2 ("Type-specific architecture") of the core architecture template.

## §2.1 Pipeline topology

State the high-level shape:

- **Stages:** Source → [Fetch/Ingest] → [Raw store] → [Parse/Normalize] → [Transform/Enrich] → [Final store] → [Deliver]
- **Style:** [Linear (one stage feeds the next)] / [DAG (fan-in/fan-out across sources)] / [Streaming (continuous)] / [Mini-batch (windowed)]
- **Granularity:** [Per-record processing] / [Batch (e.g. 1k records per chunk)] / [Per-window]
- **Triggers per source:** what initiates a run for each source

## §2.2 Sources catalog

For each source:

| Source | Type | Cadence | Auth | Volume per run | Quirks |
|---|---|---|---|---|---|
| [name] | [API/scrape/file/DB] | [hourly/daily] | [key/cookie/none] | [N pages or rows] | [pagination, rate limit, etc.] |
| ... | | | | | |

## §2.3 Fetching strategy

For sources that need it (especially scraping):

- **HTTP client choice:** [native fetch/requests] / [Playwright headless] / [scraping API (Apify/ScrapingBee)] / [proxy network (Bright Data/Oxylabs)]
- **Concurrency:** N parallel fetches per source, with per-source semaphore
- **Retry posture:** N attempts with exponential backoff; distinguish transient (5xx, network) from permanent (4xx) errors
- **Politeness:** rate limit per source (e.g. 1 req/s), respect robots.txt where applicable
- **Identity:** user-agent string, IP rotation policy, session/cookie management

## §2.4 Storage tiers

Raw → Staging → Final.

- **Raw zone:** [S3/GCS/blob] in original format (HTML, JSON, CSV). Path convention: `raw/{source}/{date}/{run_id}/{filename}`. Retention: [N days].
- **Staging:** typed records ready for transformation. [Postgres staging schema] / [Parquet in object storage] / [DuckDB local].
- **Final:** [Warehouse] / [Analytics DB] / [Operational DB]. Schema is stable and versioned.

## §2.5 Transformation

- **Approach:** [SQL-first (dbt-style)] / [Python/Node functions on records] / [Spark/Polars for big batch] / [Stream processor]
- **Schema-on-read vs schema-on-write:** raw is read-time, final is write-time
- **Idempotency:** transformations are deterministic given inputs; re-running a window produces the same final-table state
- **Deduplication:** strategy (hash-based, business-key-based) and where it happens

## §2.6 Output and delivery

For each consumer:

| Consumer | Format | Delivery | Cadence |
|---|---|---|---|
| [Sales team] | PDF report | Email | Daily 9am |
| [BI tool] | Postgres view | Pull (BI queries) | Real-time |
| [Partner] | CSV upload | SFTP push | Weekly |
| ... | | | |

- **Templating:** how reports are generated (e.g., HTML → PDF via Playwright/Puppeteer, Jinja templates, library)
- **Personalization:** per-recipient parameterization
- **Failure surfacing:** on delivery failure, who gets notified

## §2.7 Scheduling and orchestration

- **Orchestrator:** [Airflow / Prefect / Dagster / GitHub Actions / Inngest / cron + script]
- **Schedule:** explicit cron expressions per pipeline
- **Backfill:** how to re-run for a past window — supported via [orchestrator UI] / [CLI] / [config flag]
- **Concurrency control:** prevent two runs of the same pipeline overlapping
- **Manual trigger:** UI/CLI for ad-hoc runs (e.g., to recover from a missed schedule)

## §2.8 Quality and validation

- **Schema validation:** at the ingest boundary, reject malformed records to a quarantine zone
- **Statistical checks:** per-run, compare row count, null rate, distinct counts to a rolling baseline; alert on Z-score deviation
- **Reconciliation:** against an external truth (e.g., partner-reported totals) on a defined cadence
- **Anomaly review surface:** quarantine zone is queryable; weekly review ritual documented

## §2.9 Observability

- **Per-run telemetry:** start, end, duration, rows in/out per stage, error count, retry count
- **Centralized log destination:** structured logs with run_id, source, stage
- **Long-running alert:** if a run exceeds expected duration by N×, page
- **SLA dashboard:** freshness lag per source, success rate per pipeline

## §2.10 Cost posture

Pipelines often surprise on cost.

- **Compute:** estimated cost per run (orchestrator, transform engine, scraping API)
- **Storage:** raw retention is the silent killer; estimate growth and pruning policy
- **Egress:** if delivering large files via email/SFTP, consider bandwidth costs
