# Audit-First Protocol

Before writing code for a phase, audit the plan against the repo. This catches divergences cheaply — before they're baked into code.

## Stack-agnostic note

Examples in this document use placeholders like `[schema directory]`, `[auth/identity service]`, `[data isolation policy]`, `[database enum pattern]`. Substitute with your project's actual stack — defined in `AGENTS.md` (Claude Code/Codex) or in mode metadata (Roo/Kilo/OpenCode). The audit categories themselves are universal.

## When to audit

- User asks you to implement a phase described in `IMPLEMENTATION_PLAN_PHASE_N.md`.
- User asks you to continue a phase that previously started.
- User hands you a spec bundle and says "go."

Don't audit when:
- You're making a single small fix within an already-audited phase.
- User explicitly asks to skip the audit because time is tight. (Flag the risk, but respect the call.)

## The audit report format

Deliver the audit as a single response. The user reads it, resolves issues, then gives you the go-ahead to proceed (or to revise the plan first).

```markdown
## Phase N audit — [plan revision number]

### Blockers
(things that prevent starting — fix these before any code)

1. [Specific issue]. Recommendation: [what to do].
2. ...

### Plan-repo divergences
(things where plan says X but repo has Y — repo wins by default)

1. Plan §X.Y references `someHelper()` — actual helper is `otherHelperName()` in `[path]`. Using repo's version. Flag in DECISIONS if not already.
2. ...

### Open questions for the user
(things the plan didn't decide — need a call)

1. [Question] → [options A, B, C with trade-offs if you have a view]
2. ...

### Known issues / tech debt updates
(pre-existing bugs, security gaps, or tech debt discovered during audit that are outside current scope)

1. Added / propose `KI-NNN`: [short title] — evidence: [file:line or repro]. Why deferred: [reason].
2. Updated `KI-NNN`: [status/severity/blast radius change].

### Aligned / no action
(quick list of things the plan got right or that are already in place; helps the user calibrate the audit's thoroughness)

- [item]
- ...

### Proposed next step
Concrete proposal for what to deliver first, pending resolution of the above.
```

## What to check, by category

### Database / schema (when applicable)

- Tables/collections the plan references — do they exist in the actual `[schema directory]` (migrations, schema modules, ORM definitions)?
- Column names, types, nullability — match?
- Foreign-key references — do the referenced tables exist? Is the on-delete behavior aligned?
- `[data isolation policy]` (RLS, app-layer guards, tenant filters) — what's the actual pattern in the repo (helper names, role grants)? The plan may use invented names.
- Enum values — exist in the DB / use the project's `[database enum pattern]`?

### Helpers and conventions

- Auth helpers (`requireRole`, `getSession`, equivalents) — file locations and names in the repo?
- DB client choice (ORM, query builder, raw SQL) — is there already a service-role vs authenticated split? Follow the existing pattern.
- Error classes, response shapes (`{ error, fields }` vs `{ message }`) — consistent with repo?
- Logging / observability wrappers — does the repo wrap Sentry / OTel directly or have a utility?

### Files and directories

- Does the plan reference paths that don't exist? (Example: plan says `src/lib/auth/guards.ts` but repo has `src/lib/auth/session.ts`.)
- Does the plan say "create in `X/`" when the repo convention is actually `Y/`? Follow repo convention.

### Dependencies

- Packages the plan wants installed — already present?
- Versions (if specified) — compatible with existing manifest (`package.json`, `pyproject.toml`, etc.)?
- Any packages that were deferred per prior DECISIONS?

### Security / isolation

- The plan's claims about `[data isolation policy]`, service-role use, auth gates — do they hold given the actual repo's `[auth/identity service]`, middleware, etc.?
- The plan's isolation invariants (e.g. "organization_id enforced in code because RLS is bypassed here") — is the code path it describes actually going to execute as planned?
- If you find a pre-existing security/data correctness issue outside current scope, add or propose a `KNOWN_ISSUES.md` entry instead of hiding it in the audit narrative.

### Type-specific concerns (load only the relevant)

For projects whose primary type is one of:

- **Web SaaS / API service:** all the above + tenant resolution chain, rate limit setup
- **Landing page:** content sources (CMS connectivity), build pipeline, deployment target
- **Dashboard:** data source connections, query module shapes, cache infra
- **Mobile:** native module presence, signing certs, OTA channel
- **Data pipeline:** orchestrator config, source credentials, raw zone storage paths
- **AI agent:** model provider keys, prompt files, eval harness skeleton
- **Automation workflow:** workflow engine setup, registered triggers, integration credentials

## Common divergence categories

After running several audits, you'll see the same categories recur:

### 1. Helper name drift
Plan uses helper name A; repo has helper name B. Almost always the repo wins.

### 2. File location drift
Plan wants something in `src/lib/foo/`; repo convention is `src/modules/foo/`. Repo wins, but if the plan has a reason (refactor, etc.), raise it.

### 3. Resource reference to future phase
Plan references resource `agents.id` as a relationship target in Phase 1, but the `agents` table is only created in Phase 2. Fix: make the column plain UUID with comment; FK added when the table exists.

### 4. Stale dependency assumption
Plan assumes package X is installed (because ARCHITECTURE.md mentioned it); it was deferred in DECISIONS.md. Audit must check DECISIONS.md, not just ARCHITECTURE.md.

### 5. Convention not written down
The repo follows a convention the plan doesn't mention (e.g. "all enums use `[database enum pattern]`, never `text` with check"). If the repo is consistent, follow it and add a note to DECISIONS.md so the convention becomes documented. Also propose adding the convention to `AGENTS.md` / `CLAUDE.md` if those fact files are present.

### 6. Missing runtime deps
Plan requires libraries (e.g. `jsonpath-plus`, `libphonenumber-js`, an LLM SDK) — not yet installed. Not a blocker if you'll install them, but flag it in the audit so the user sees the diff before you run the install.

### 7. Project fact sheet gap
Plan assumes a stack item that `AGENTS.md` / `CLAUDE.md` doesn't yet record (or the project fact sheet is missing entirely). Propose updating the fact sheet as part of resolving the audit.

## Classifying findings

Each audit finding goes in one bucket:

- **Blocker**: prevents starting. Must be resolved first. Examples: missing tables the plan assumes exist, contradictory `[data isolation policy]`, unresolved "how should X work" questions in the plan.

- **Divergence (repo-wins)**: plan says one thing, repo has another, and the repo's version is correct/idiomatic. Material divergences (judgment-call resolutions) → `DECISIONS.md` entry; mechanical divergences (idiomatic corrections) → noted in the round report only. See `decisions-log-format.md` for the distinction.

- **Divergence (plan-wins, needs migration)**: plan describes the target state; repo is out of date. Proceed per the plan, register the migration needed.

- **Open question**: the plan genuinely doesn't decide something you need a call on. Present options; get the user's answer.

- **Known issue**: pre-existing bug/debt/security gap with concrete evidence that is outside current scope. Add or propose a `KNOWN_ISSUES.md` entry; do not silently expand the implementation scope to fix it.

- **Aligned**: fine as is. Include a brief list in the report so the user can calibrate how thorough the audit was.

## Tone of the audit

- **Concise.** Bullets, not paragraphs. Each finding one or two lines.
- **Specific.** Reference files, line numbers (§2.1), function names.
- **Non-judgmental.** The plan was written earlier under different context. Divergence isn't a "bug in the plan" — it's expected, and the audit is the remediation.
- **Pre-loaded with recommendations.** For each divergence, say what you propose to do. The user should be able to say "yes, go" to most items without having to think hard.

## After the audit

Once the user resolves the blockers and open questions:

1. Update the plan with a **revision note** at the top (`r2`, `r3`) summarizing the audit resolutions. See `revision-notes-format.md`.
2. Add relevant entries to `DECISIONS.md`.
3. Add/update `KNOWN_ISSUES.md` for any concrete out-of-scope bugs, security gaps, or tech debt found during the audit.
4. Propose updates to `AGENTS.md` / `CLAUDE.md` for any project-specific conventions the audit surfaced; if both exist, keep them in sync.
5. Propose the first concrete deliverable and stop for review (see `stop-and-review-patterns.md`).

Don't skip the revision note. Later, someone will read the plan; they need to know it was audited and adjusted.
