# PROJECT_STRUCTURE Template — Web API / backend service

Repo layout for a headless API or service. Adapt to chosen language/framework.

Target length: 200–300 lines.

## Structure

```markdown
# [Product] — Project Structure & Conventions

> Folder layout and conventions for the [Node/Express, Hono, Fastify | Python/FastAPI | Go/Echo | etc.] API service. Read by the coding agent as context when generating code.

## Top-Level Layout

\`\`\`
[repo-root]/
├── .github/                # CI workflows
├── src/
│   ├── routes/             # endpoint handlers (or controllers/ in some frameworks)
│   ├── handlers/           # webhook handlers (separate from regular routes)
│   ├── services/           # domain logic — business operations
│   ├── repositories/       # data access — DB queries
│   ├── schemas/            # request/response validation (Zod / Pydantic / etc.)
│   ├── middleware/         # auth/error handling; rate limit/logging only when required
│   ├── workers/            # background workers / queue consumers (if applicable)
│   ├── lib/                # cross-cutting utilities (clients, hashing, signing)
│   └── types/              # shared types
├── migrations/             # checked-in DB migrations
├── tests/                  # unit + integration
├── docs/                   # PRD, ARCHITECTURE, DECISIONS, KNOWN_ISSUES, MEMORY, OpenAPI/AsyncAPI specs
└── [config files]
\`\`\`

## src/routes/ — Endpoint handlers

\`\`\`
[tree organized by resource: users/, organizations/, webhooks/, billing/, etc.]
\`\`\`

### Route conventions

- One file per resource. Routes are thin: validate input → call service → format response.
- No business logic in routes. If you're tempted, extract to `services/`.
- Every route has: input schema (Zod/Pydantic), service call, success response shape, error mapping.
- Auth/middleware composition is declarative at the file or route level.

## src/handlers/ — Webhook handlers

\`\`\`
[tree — one file per provider: stripe.ts, twilio.ts, github.ts]
\`\`\`

### Webhook conventions

- Signature verification happens in middleware before the handler runs.
- Dedup check (`webhook_events` table) before processing.
- Queue work only when the provider acknowledgement deadline or recovery contract requires it.
- Replay-safe: re-running a handler with the same event yields the same DB state.

## src/services/ — Domain logic

\`\`\`
[tree — one file per domain area: userService.ts, billingService.ts]
\`\`\`

### Service conventions

- Services orchestrate; they don't reach into HTTP or DB drivers directly.
- Services use repositories for data access and external clients (from `lib/`) for third-party calls.
- Services may be tested in isolation when the proportional test threshold is met.

## src/repositories/ — Data access

\`\`\`
[tree — one file per table: usersRepo.ts, apiKeysRepo.ts]
\`\`\`

### Repository conventions

- One file per table or close-knit table group.
- Each function has a clear name describing the query (`findActiveKeysForOrg`, not `query`).
- Transactions are passed in; repos don't open them.

## src/schemas/ — Validation

\`\`\`
[tree — request/response schemas mirroring routes]
\`\`\`

- Schemas are reusable. Shared shapes live in `schemas/shared/`.
- Schemas double as TypeScript types via `z.infer<typeof X>` (or equivalent).

## src/middleware/

\`\`\`
[tree — auth/error handling plus only the rate-limit/correlation middleware required]
\`\`\`

### Middleware conventions

- Auth middleware sets `req.context` (or equivalent) with `{ key, organizationId, scopes }`.
- When rate limiting is required, derive its bucket from the authenticated contract rather than untrusted input.
- Error handler is the single place that maps exceptions → HTTP status + body.

## src/workers/ — Background workers

\`\`\`
[tree if applicable — webhook delivery worker, async event processor]
\`\`\`

## migrations/

\`\`\`
[tree — timestamped migration files]
\`\`\`

### Migration conventions

- One concern per migration. No drive-by changes.
- Forward-only at MVP unless rollback is genuinely needed.
- Checked into the repo. Never edit applied migrations.

## Coding Conventions

### Language-specific
- [TypeScript: strict mode, no `any` in production code, Zod for I/O validation]
- [Python: type hints required, Pydantic for I/O, ruff/black]

### Auth and tenant context
- `req.context` is the only source of `organizationId`. Routes never trust query string for tenancy.
- Repositories accept `organizationId` explicitly; no hidden globals.

### Errors
- Domain errors are explicit classes (e.g. `NotFoundError`, `RateLimitError`).
- Routes don't catch — middleware does.
- Never leak stack traces in 5xx responses; log them, return generic message.

### Observability
- Add request correlation/logging when a reachable failure needs operational detection; scrub PII at the boundary.

### Testing
- Add only tests required by an approved criterion or a material silent-harm path.
- When that path crosses DB/HTTP/signature boundaries, use an integration test that exercises the real boundary.

### Commits & Branches
- [conventional commits, branch naming]

### Environment Variables
- DB: `DATABASE_URL`.
- External providers: `STRIPE_API_KEY`, `STRIPE_WEBHOOK_SECRET`, etc.
- Feature flags or per-tier limits only when the approved product/API contract defines them.

## Coding agent kickoff prompt template

[End-of-doc prompt template — what the user pastes into the coding agent on day one.]
```

## Writing tips

- **Routes are thin.** Anything beyond validation + service call + response formatting is misplaced.
- **Auth context is the only source of tenancy.** Anything else invites cross-tenant bugs.
- **Webhook processing follows the provider contract.** Queue only when acknowledgement latency or recovery semantics require it.
- **Migrations are immutable once applied.** Forward-only by default.
