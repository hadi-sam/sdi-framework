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
│   ├── lib/                # cross-cutting utilities (idempotency keys, logging, retry helpers)
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
- Each file exports: id, name, trigger config, step graph, retry policy, concurrency policy.
- Workflows compose steps from `src/steps/`; they don't inline business logic.
- Schema for trigger payload is defined alongside the workflow.

## src/steps/ — Reusable steps

\`\`\`
[tree — pure functions or step classes that workflows compose]
\`\`\`

### Step conventions

- Each step has input schema, output schema, execute function.
- Steps that perform external writes accept (or generate) an idempotency key.
- Steps that read are pure where possible; side-effecting reads (e.g., increment counter) are marked.
- Retry / timeout policies live on the workflow's invocation of the step, not in the step itself.

## src/triggers/ — Trigger surface

\`\`\`
[tree — webhooks/, cron.ts, manual.ts]
\`\`\`

### Trigger conventions

- **Webhook handlers:** verify signature → dedupe (idempotency on upstream event id) → ack 200 → enqueue workflow.
- **Cron triggers:** registered with the engine; payload is the run window.
- **Manual triggers:** auth-gated, parameterized, audit-logged.

## src/integrations/ — External clients

\`\`\`
[tree — one file per provider: stripe.ts, hubspot.ts, slack.ts]
\`\`\`

### Integration conventions

- One file per provider. Single client export with typed methods.
- Authentication, rate limit, retry are in the wrapper — workflows don't deal with raw API.
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
[tree — idempotencyKey.ts, logger.ts, retry.ts, runContext.ts]
\`\`\`

### Library conventions

- Idempotency key generator: deterministic from (workflow_run_id, step_name, parameters).
- Run context propagates run_id, workflow_id, trigger metadata through logs and integration calls.

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
- Every external write goes through the integration wrapper, which enforces idempotency keys.
- Replaying a step yields the same end state.

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
- **Idempotency is the foundation.** Every external write protected, no exceptions.
- **Integration wrappers are mandatory.** Direct calls from workflows make provider swaps and observability hard.
- **Triggers ack fast.** Heavy work always happens in the workflow runtime, not the trigger handler.
