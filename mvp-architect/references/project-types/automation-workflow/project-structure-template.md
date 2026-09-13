# PROJECT_STRUCTURE Template — Integration / automation workflow

Repo layout for an automation/integration workflow system. Adapts to the chosen engine (Inngest, Temporal, custom queue, etc.).

Target length: 200–300 lines.

## Structure

```markdown
# [Product] — Project Structure & Conventions

> Folder layout and conventions for the [Inngest / Temporal / custom] workflow system. Read by the coding agent as context when generating code.

## Top-Level Layout

\`\`\`
[repo-root]/
├── .github/                # CI workflows
├── src/
│   ├── workflows/          # one file per workflow
│   ├── steps/              # reusable step functions
│   ├── triggers/           # webhook handlers, cron registrations, manual triggers
│   ├── integrations/       # external service clients (one file per provider)
│   ├── schemas/            # input/output schemas for workflows and steps
│   ├── lib/                # only shared utilities justified by workflow contracts
│   └── ops/                # ops UI / dashboard / replay tools (if user-visible)
├── tests/
├── docs/
└── [config files]
\`\`\`

## src/workflows/ — Workflow definitions

\`\`\`
[tree — one file per workflow: leadInbound.ts, dailyDigest.ts, syncCrm.ts]
\`\`\`

### Workflow conventions

- One file per workflow. Filename matches the workflow id.
- Each file exports the workflow's required metadata; retry/concurrency policy only when applicable.
- Workflows compose steps from `src/steps/`; they don't inline business logic.
- Schema for trigger payload is defined alongside the workflow.

## src/steps/ — Reusable steps

\`\`\`
[tree — pure functions or step classes that workflows compose]
\`\`\`

### Step conventions

- Each step has input schema, output schema, execute function.
- Steps that can replay or race on a material external write use the provider's supported idempotency boundary.
- Steps that read are pure where possible; side-effecting reads (e.g., increment counter) are marked.
- When required, retry/timeout policies live on the workflow's invocation of the step, not in the step itself.

## src/triggers/ — Trigger surface

\`\`\`
[tree — webhooks/, cron.ts, manual.ts]
\`\`\`

### Trigger conventions

- **Webhook handlers:** verify signature and dedupe; enqueue only when provider latency/delivery semantics require it.
- **Cron triggers:** registered with the engine; payload is the run window.
- **Manual triggers:** auth-gated, parameterized, audit-logged.

## src/integrations/ — External clients

\`\`\`
[tree — one file per provider: stripe.ts, hubspot.ts, slack.ts]
\`\`\`

### Integration conventions

- One file per provider. Single client export with typed methods.
- Centralize only shared authentication or provider contracts; add rate limiting/retry only when that integration requires them.
- Sandbox/test credentials switchable via env var.
- Each method returns typed responses; errors are domain errors, not raw HTTP.

## src/schemas/

\`\`\`
[tree mirroring workflows and steps]
\`\`\`

- Reusable shared shapes go in `schemas/shared/`.
- Schemas serve as both runtime validation and TypeScript types.

## src/lib/

\`\`\`
[tree — only the idempotency, logging, retry or context helpers required by approved flows]
\`\`\`

### Library conventions

- Idempotency key generator: deterministic from (workflow_run_id, step_name, parameters).
- Propagate only the context fields needed by a named audit/recovery boundary.

## src/ops/ — Operations UI (if applicable)

\`\`\`
[tree if there's a user-visible run dashboard, replay tool, or template gallery]
\`\`\`

## Coding Conventions

### Language-specific
- [TypeScript: strict mode, Zod for I/O validation]
- [Python: type hints, Pydantic for I/O]

### Engine-specific
- [Inngest: functions exported from `src/workflows/`, `inngest.send()` only inside step.run boundaries]
- [Temporal: workflows are deterministic — no Date.now, no random without injection]

### Errors
- Domain errors are explicit classes (`RetryableError`, `PermanentError`).
- The retry policy distinguishes — permanent errors don't retry.

### Logging
- Log step/retry context when a material failure could otherwise be silent; add stable alert codes only where operations consume them.

### Testing
- Add a test only for material silent harm or an approved acceptance criterion.
- Exercise real signature/dedup/external-write boundaries when those are the risk being proved.

### Idempotency
- Protect an external write from duplication when replay/concurrency can cause material harm; use the narrowest supported boundary.
- Require replay to yield the same end state only for workflows whose contract permits replay.

### Commits & Branches
- [conventional commits, branch naming]

### Environment Variables
- Engine credentials (Inngest event key, Temporal namespace, etc.).
- Per-integration secrets (API keys, webhook signing secrets).
- Feature flags for new workflows or canary versions.

## Coding agent kickoff prompt template

[End-of-doc prompt template — what the user pastes into the coding agent on day one.]
```

## Writing tips

- **Workflows compose, steps execute.** Mixing concerns produces unreadable spaghetti.
- **Idempotency follows duplicate-write risk.** Protect material writes when replay or concurrency is reachable.
- **Integration boundaries follow shared contracts.** Do not add a wrapper solely for a hypothetical provider swap.
- **Trigger acknowledgement follows the provider contract.** Queue work when its latency or delivery semantics require it.
