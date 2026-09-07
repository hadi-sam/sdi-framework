# Architecture Appendix — Integration / automation workflow

Insert these sections into ARCHITECTURE.md at §2 ("Type-specific architecture") of the core architecture template.

## §2.1 Workflow runtime

State the engine choice and rationale:

- **Engine:** [Inngest] / [Temporal] / [Trigger.dev] / [AWS Step Functions] / [Cloudflare Workflows] / [Custom on top of a queue (BullMQ, SQS)]
- **Why this engine:** durable execution, retries, state, observability — match the project's needs
- **Hosting:** managed service vs self-hosted
- **Workflow definition style:** [code-first (TypeScript/Python functions)] / [YAML/JSON config] / [visual builder]

## §2.2 Trigger sources

| Trigger type | Source | Frequency | Auth |
|---|---|---|---|
| Webhook | [provider] | event-driven | HMAC verified |
| Cron | internal | every N min | n/a |
| Manual | UI | user-initiated | session auth |
| Internal event | upstream workflow | event-driven | n/a |

For each webhook source: signature verification scheme, dedup strategy, ack-fast pattern (200 immediately + enqueue).

## §2.3 Workflow catalog

Each workflow gets a row.

| Workflow | Trigger | Steps (high-level) | External calls | Failure mode |
|---|---|---|---|---|
| `lead_inbound` | webhook | validate → enrich → CRM upsert → notify Slack | CRM API, Clearbit, Slack | retry 3× then DLQ |
| `daily_digest` | cron 9am | gather data → render → email | DB read, SES | alert on failure, no retry |
| ... | | | | |

## §2.4 Step contracts

Within a workflow, each step has:

- **Input/output types:** explicit schemas (Zod / Pydantic / equivalent)
- **Idempotency:** every external write tagged with idempotency key derived from `(workflow_run_id, step_name)`
- **Retry policy:** per-step override of workflow default (e.g., flaky API gets 5 retries with longer backoff)
- **Timeout:** per-step max duration before treated as failed
- **Side effect classification:** read-only, idempotent write, non-idempotent write (latter requires design care)

## §2.5 State and persistence

- **Per-run state:** durable execution engine handles automatically (Inngest/Temporal); explicit DB for custom engines
- **Step history:** every step's input, output, duration, attempt count, error (if any) is logged and queryable
- **Replay:** a past run can be re-triggered with original inputs (or with overrides) — surface this in the ops UI
- **Retention:** how long completed run history is kept

## §2.6 Concurrency and ordering

- **Per-workflow concurrency cap:** limit simultaneous runs of a workflow type
- **Per-key serialization:** when needed (e.g., one run per `customer_id` at a time), state the key
- **Trigger ordering:** if FIFO is required, mention the queue/engine config that guarantees it
- **Race protection:** explicit locks or idempotent operations for cases where two runs might collide

## §2.7 Reliability

- **Retry posture:** exponential backoff with jitter; max attempts per step
- **Dead-letter destination:** failed-after-retries runs land in a DLQ table or queue, with manual replay UI
- **Compensating actions:** for workflows with side effects, document rollback steps and when they're triggered (saga pattern)
- **Circuit breaker:** if an external service is consistently failing, circuit opens to prevent cascade

## §2.8 Observability

- **Run timeline UI:** every run renders as a step-by-step timeline (duration, status, logs)
- **Logs:** structured, with run_id and step_id; PII scrubbed at the boundary
- **Metrics:** runs per minute by workflow, success rate, p50/p95 duration, retry rate per step
- **Alerting:** on workflow failure rate exceeding threshold, on DLQ depth growth
- **Cost tracking:** if engine is metered (Inngest, Temporal Cloud, Step Functions), per-workflow cost dashboard

## §2.9 Authoring surface (if user-facing)

For projects where end-users build workflows:

- **Authoring mode:** [Visual builder] / [YAML/JSON] / [Code in sandboxed runtime]
- **Validation:** structural (graph is connected, no orphan steps) + semantic (all referenced integrations are configured)
- **Test mode:** dry-run with mocked external calls; preview of step outputs
- **Versioning:** drafts → published; rollback path; concurrent editing protection
- **Templates:** pre-built workflows users can clone and customize
