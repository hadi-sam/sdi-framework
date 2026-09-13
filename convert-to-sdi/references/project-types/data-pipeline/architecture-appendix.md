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
- **Retry posture (when delivery/recovery semantics require it):** max attempts and backoff; distinguish transient from permanent errors
- **Politeness/contract:** honor source terms and robots.txt; add a rate limit only when the source contract or measured behavior requires one
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

Select only checks that protect a consumer contract or a material data-integrity risk.

- **Schema validation:** define the ingest behavior for malformed records; quarantine only when recovery requires it
- **Statistical checks:** add only when an approved quality threshold needs drift detection
- **Reconciliation:** add only when a named external truth and cadence are part of the contract
- **Anomaly review surface:** add only when operators need to inspect/recover rejected data

## §2.9 Observability

Omit this section when the pipeline creates no material operational detection or recovery need. Otherwise select the minimum signal for that need:

- **Per-run signal:** only the timestamps/counts needed to detect or recover the named failure
- **Log destination:** structured correlation fields only where stages must be traced together
- **Long-running alert:** only when a runtime/freshness contract has an actionable threshold
- **Dashboard:** only when operators consume aggregate freshness or success targets

## §2.10 Cost posture (when spend is material or contractually bounded)

Estimate only the metered resources that can affect the approved budget.

- **Compute:** estimated cost per run (orchestrator, transform engine, scraping API)
- **Storage:** raw retention is the silent killer; estimate growth and pruning policy
- **Egress:** if delivering large files via email/SFTP, consider bandwidth costs
