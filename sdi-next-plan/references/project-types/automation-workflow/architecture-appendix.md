# Architecture Appendix — Integration / automation workflow

Insert these sections into ARCHITECTURE.md at §2 ("Type-specific architecture") of the core architecture template.

## §2.1 Workflow runtime

State the engine choice and rationale:

- **Engine:** [Inngest] / [Temporal] / [Trigger.dev] / [AWS Step Functions] / [Cloudflare Workflows] / [Custom on top of a queue (BullMQ, SQS)]
- **Why this engine:** identify only the execution/state/recovery capabilities the approved workflows need
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

Within a workflow, document only the contracts relevant to each step:

- **Input/output types:** explicit schemas (Zod / Pydantic / equivalent)
- **Idempotency:** required when replay/concurrency can duplicate a material external write; use the provider's supported key shape
- **Retry policy:** add a per-step policy only when transient failure and delivery semantics require it
- **Timeout:** per-step max duration before treated as failed
- **Side effect classification:** read-only, idempotent write, non-idempotent write (latter requires design care)

## §2.5 State and persistence

- **Per-run state:** durable execution engine handles automatically (Inngest/Temporal); explicit DB for custom engines
- **Step history:** retain only fields required for a named audit or recovery contract, with secret/PII handling
- **Replay:** add only when operators or the delivery contract require recovery from a past run
- **Retention:** how long completed run history is kept

## §2.6 Concurrency and ordering

- **Per-workflow concurrency cap:** add only when overlapping runs create a measured resource or correctness risk
- **Per-key serialization:** when needed (e.g., one run per `customer_id` at a time), state the key
- **Trigger ordering:** if FIFO is required, mention the queue/engine config that guarantees it
- **Race protection:** explicit locks or idempotent operations for cases where two runs might collide

## §2.7 Reliability

- **Retry posture:** when required, state bounded attempts/backoff for the relevant step
- **Dead-letter destination:** add only when exhausted work must be retained for a recovery contract
- **Compensating actions:** for workflows with side effects, document rollback steps and when they're triggered (saga pattern)
- **Circuit breaker:** add only when measured cascade/load risk warrants it

## §2.8 Observability

Omit this section when no material operational detection/recovery or budget contract exists. Otherwise select the minimum useful surface:

- **Run timeline UI:** only when operators need step-level diagnosis or replay
- **Logs:** add only the correlation fields needed for the named failure; scrub PII at the boundary
- **Metrics/alerting:** only actionable signals tied to an approved SLO or recovery trigger
- **Cost tracking:** only when metered workflow spend can materially affect an approved budget

## §2.9 Authoring surface (if user-facing)

For projects where end-users build workflows:

- **Authoring mode:** [Visual builder] / [YAML/JSON] / [Code in sandboxed runtime]
- **Validation:** structural (graph is connected, no orphan steps) + semantic (all referenced integrations are configured)
- **Test mode:** add a dry-run/preview only when the user-facing authoring contract requires safe rehearsal
- **Versioning:** drafts → published; rollback path; concurrent editing protection
- **Templates:** pre-built workflows users can clone and customize
