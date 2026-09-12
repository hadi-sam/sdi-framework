# Discovery — Integration / automation workflow

Type-specific themes for projects that connect APIs and automate multi-step processes (n8n-style flows, Zapier-style replacement, custom Inngest/Temporal workflows, webhook routers). Load alongside `references/discovery-themes.md`.

## ⚡ 1. Trigger model

What kicks off a workflow run?

Typical questions:
- Inbound webhooks from third-party services (Stripe, GitHub, calendar, CRM)?
- Scheduled (cron) — daily digests, periodic syncs?
- Polling (when source has no webhook)?
- Manual (user clicks a button)?
- Internal events (downstream of another workflow)?
- Mix of the above — which dominates?

## ⚡ 2. Workflow shape

Linear, branching, or graph?

Typical questions:
- Mostly linear (A → B → C → done)?
- Branching (if X then Y else Z)?
- Long-running (waits for external event mid-flow)?
- Saga-style (compensating actions on failure)?
- Multi-step approvals or human-in-the-loop?

## ⚡ 3. External integrations

Which systems are touched per workflow?

Typical questions:
- List of integrations — CRMs, communication (Slack/Discord/email), storage (Drive/Notion/Airtable), payments, custom internal APIs?
- For each: auth (OAuth, API key, service account), rate limits, sandbox availability?
- Source of truth — is the workflow doing writes, reads, or both, on each system?
- Sync vs async per integration — does the workflow await the call or fire-and-forget?

## 4. State and persistence

Most workflow engines track state — but at what fidelity?

Typical questions:
- Per-run state (history of steps, inputs, outputs)?
- Persistent storage of intermediate values (so a resumed run picks up correctly)?
- Audit trail — every step logged with timestamps and user/triggered_by?
- Replayability — can we re-run a past run with the same inputs?

## 5. Reliability

Workflows fail in interesting ways.

Typical questions:
- Retry policy per step — exponential backoff, max attempts?
- Timeout policy — per-step and per-workflow?
- Dead-letter handling — where do exhausted-retry runs go?
- Idempotency keys — every external write protected?
- Compensating actions — if step 5 fails, do we roll back steps 1-4?

## 6. Concurrency and ordering

Often where surprising bugs hide.

Typical questions:
- Multiple runs of the same workflow can be concurrent — yes or serialized?
- Per-resource serialization (e.g., one run per customer at a time)?
- Ordering guarantees on event triggers (FIFO, best-effort, none)?
- Race conditions — is there a key against which concurrent runs would conflict?

## 7. Observability

Workflows are diagnostic-heavy.

Typical questions:
- Per-run timeline view — visible to engineers? to users?
- Step-level logs — what's logged, with what PII scrubbing?
- Failure alerts — Slack, email, Pagerduty?
- Metrics — runs per minute, success rate, p95 duration, retry rate per step?
- Run replay tool — UI to inspect a past run and re-trigger?

## 8. Authoring and UX (if applicable)

If users build the workflows themselves (low-code surface).

Typical questions:
- Drag-and-drop builder, YAML/JSON config, code-only, or hybrid?
- Test mode — dry runs without external side effects?
- Versioning workflows — edit live or draft → publish?
- Sharing/templates — pre-built workflows users can clone?

## How to use

1. Themes 1, 2, 3 are foundational. Workflow architecture follows directly from these.
2. Ask Theme 5 to the depth warranted by replay, duplicate-write and delivery risk; omit mechanisms with no reachable failure contract.
3. Theme 6 (concurrency) is silent until it bites. Ask explicitly.
4. Theme 8 only applies if you're building a user-facing workflow builder; skip cleanly for internal automations.
