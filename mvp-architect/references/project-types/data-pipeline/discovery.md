# Discovery — Data pipeline / scraper + reports

Type-specific themes for projects whose primary deliverable is automated data collection, transformation, and delivery (scrapers, ETL, scheduled report generators). Load alongside `references/discovery-themes.md`.

## ⚡ 1. Sources

What's the input?

Typical questions:
- Public web pages (scraping), APIs (auth required?), files (S3 drops, FTP, email attachments), DBs (CDC), or mix?
- Per-source cadence — minutes, hours, daily, on-demand?
- Per-source volume — pages per run, rows per batch, file sizes?
- Authentication — API keys, OAuth, login-walled scraping, cookies, none?
- Stability — does the source change shape often (HTML scraping is fragile, API contracts are firmer)?

## ⚡ 2. Anti-bot and throttling (for scraping)

Skip if no scraping is involved.

Typical questions:
- Bot mitigation in place at sources — Cloudflare, Akamai, Datadome, custom?
- Approach — direct fetches with rotating IPs (Bright Data, Oxylabs, Smartproxy), headless browser (Playwright), residential proxies, scraping API (ScrapingBee, ScraperAPI, Apify)?
- Rate limits per source — known, guessed, found by trial?
- Captcha handling — solve via service (2Captcha), avoid by behavior, accept partial failure?
- Legal/ethical posture — robots.txt, ToS review, only public data?

## ⚡ 3. Processing pipeline

What happens between input and output?

Typical questions:
- Pure passthrough (load and store), light transformation (parsing, normalization), or heavy transformation (enrichment, deduplication, joining across sources)?
- Pipeline shape — linear (A → B → C) or DAG (multiple sources fan-in, fan-out)?
- Stateful processing (windows, accumulation, joins) or stateless (per-record)?
- Error handling — fail fast and stop, skip-and-continue, dead-letter for retry?
- Partial-failure tolerance — what if 99 of 100 records process and 1 fails?

## 4. Storage

Where does intermediate and final data live?

Typical questions:
- Raw zone — store every fetched payload as-is for replay/debugging? (S3, GCS, blob)
- Staging — typed/validated rows ready for processing?
- Final — warehouse (BigQuery, Snowflake, Redshift), analytics DB (Postgres, ClickHouse), file output?
- Schema management — schema-on-read (raw JSON), schema-on-write (typed tables), both at different stages?
- Retention — keep raw forever, delete after N days?

## 5. Outputs and delivery

How does the data get to the consumer?

Typical questions:
- Output formats — CSV, PDF report, dashboard, email, webhook to downstream system, API endpoint?
- Delivery mode — push (email/webhook on schedule) or pull (consumer queries when needed)?
- Templating — fixed template, parameterized per-recipient, fully dynamic?
- Distribution list — fixed or self-service subscription?
- Notification on failure — who gets paged, how?

## 6. Scheduling and orchestration

How often and how reliably the pipeline runs.

Typical questions:
- Trigger — cron schedule, event-driven (file lands), manual, hybrid?
- Orchestrator — Airflow, Prefect, Dagster, GitHub Actions cron, Temporal, custom?
- Parallelism — sequential, parallel by source, parallel by partition?
- Backfill — easy to re-run for a past date range?
- Idempotency — safe to run twice for the same window?

## 7. Quality and validation

How do we know the output is correct?

Typical questions:
- Schema validation at ingest (reject malformed rows)?
- Statistical checks — row counts, duplicates, null rates compared to historical baseline?
- Reconciliation against a known truth — yes/no, what source?
- Manual review surface for anomalies?
- Alerting on anomalies — Slack/email/Pagerduty?

## 8. Observability

Pipelines fail silently more often than they should.

Typical questions:
- Per-run metrics — start time, end time, rows in/out per stage, error counts?
- Long-running monitor — alert if a run exceeds expected duration?
- Lineage — which source rows produced which output rows?
- Logs — where they go, retention, queryability?

## How to use

1. Themes 1, 2, 3 are foundational. Without them you can't sketch architecture.
2. Theme 2 (anti-bot) only matters for scraping; skip cleanly if not.
3. Theme 7 (quality) is often deferred. Ask the user if "data quality" is in MVP — if yes, scope it; if no, document the gap.
4. Ask Themes 6 and 8 only when cadence or a material operational detection/recovery need exists; do not turn them into infrastructure by default.
