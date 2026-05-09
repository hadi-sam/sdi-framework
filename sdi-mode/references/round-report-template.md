# Round Report Template

Every implementation round ends with a report. Same sections, same order. Users read many of these; consistency lets them scan quickly.

## The shape

```markdown
## Round [letter or number] — [one-line description]

> **BASE_SHA:** [sha of the commit at the start of this round — last commit of the previous round, or phase-start commit for round A. Used by auto-review to compute `git diff BASE_SHA..HEAD`. Captured by the implementer at round start (see `auto-review-mode.md` §"Per-round commit convention").]

### Delivered

[Table or bullet list. For each file touched or created, one line:
 - Path
 - What it does / why it changed
 - Test coverage (counts or "n/a")]

### Design decisions worth review

1. [Decision + rationale + link to DECISIONS.md entry if applicable]
2. ...

### Known issues / technical debt updates

[List new or updated `KNOWN_ISSUES.md` entries. Use "None" if the round did not discover or change any known issue.]

- `KI-NNN` — [new / scheduled / partially mitigated / resolved], [one-line evidence or commit/status note]

### Testing

- Commands/checks run:
  - `[exact command]` — PASS / FAIL, [runtime], [count/result], [relevant output summary]
  - `[exact command]` — PASS / FAIL, [runtime], [count/result], [relevant output summary]
- Skipped/not run: [explicit list with reason, or "None"]
- Manual smoke test: [what was exercised, environment, result, or "not applicable"]
- Evidence notes: [fixtures, local services, env vars, screenshots/logs, or other context needed to judge the checks]

### Auto-review history (default for Checkpoints 2/3/4)

[For each attempt, in order. Default schedule unless the user overrides it: attempt 1 has THREE reviewers (Opus subagent + Sonnet subagent + Codex); attempt 2 has TWO reviewers (Opus subagent + Codex); attempt 3 has ONE reviewer (Opus subagent). Note any degraded mode, skipped reviewer, timeout, or user-requested schedule change.

**Attempt 1 — merged verdict**: PASS / FAIL / ESCALATE.
  - **Opus subagent verdict**: PASS / FAIL / ESCALATE (or "skipped: <reason>" if it failed to run).
    - Full output verbatim from `docs/reviews/round-XN-attempt-1-opus.md` (findings + verdict line).
  - **Sonnet subagent verdict**: PASS / FAIL / ESCALATE (or "skipped: <reason>" if it failed to run).
    - Full output verbatim from `docs/reviews/round-XN-attempt-1-sonnet.md` (findings + verdict line).
  - **Codex verdict**: PASS / FAIL / ESCALATE (or "skipped: <reason>" if it failed to run).
    - Full output verbatim from `docs/reviews/round-XN-attempt-1-codex.md` (findings + verdict line).
  - **Runtime notes**: degraded mode, timeout, extended timeout declaration, or user-requested schedule change if applicable.
  - **Merge rule applied**: e.g., "Opus PASS + Sonnet FAIL + Codex PASS → FAIL (any FAIL blocks)".
  - **Issues found** (union of reviewer findings if FAIL/ESCALATE): list and the fix applied between attempts, with the fix commit SHA.

**Attempt 2 — merged verdict**: PASS / FAIL / ESCALATE.
  - **Opus subagent verdict**: PASS / FAIL / ESCALATE (or "skipped: <reason>" if it failed to run).
    - Full output verbatim from `docs/reviews/round-XN-attempt-2-opus.md`.
  - **Codex verdict**: PASS / FAIL / ESCALATE (or "skipped: <reason>" if it failed to run).
    - Full output verbatim from `docs/reviews/round-XN-attempt-2-codex.md`.
  - **Runtime notes**: degraded mode, timeout, extended timeout declaration, or user-requested schedule change if applicable.
  - **Prior findings re-checked**: list the prior findings included in `[PRIOR_REVIEW_FINDINGS]`.
  - **Merge rule applied**: e.g., "Opus PASS + Codex FAIL → FAIL (any FAIL blocks)".
  - **Issues found** (if FAIL/ESCALATE): list and the fix applied between attempts, with the fix commit SHA.

**Attempt 3 — Opus verdict**: PASS / FAIL / ESCALATE.
  - **Opus subagent verdict**: PASS / FAIL / ESCALATE (or "skipped: <reason>" if it failed to run).
    - Full output verbatim from `docs/reviews/round-XN-attempt-3-opus.md`.
  - **Runtime notes**: timeout or user-requested/degraded reviewer mode if applicable.
  - **Prior findings re-checked**: list the prior findings included in `[PRIOR_REVIEW_FINDINGS]`.
  - **Issues found** (if FAIL/ESCALATE): list and the fix applied between attempts, with the fix commit SHA.

Omit this section only when (a) the round was Checkpoint 1 or 5 (always user-gated), (b) the user opted out of auto-review for this session, or (c) an always-escalate trigger fired and the round was user-gated. See `auto-review-mode.md`.]

### Not done in this round (and why)

[Explicit list of scope items deferred. For each: what, why, where it goes.]

### Open questions for the user

1. [Specific question with options if you have a view]
2. ...

### Next suggested round

[One-paragraph recommendation of what should come next, or multiple options if there's a real fork.]
```

## Rules for writing a good report

### Specificity over summary

Bad:
> Added the webhook handler and some tests.

Good:
> `src/app/api/webhooks/ingest/[sourceId]/route.ts` — POST handler using `await request.text()` to preserve HMAC bytes; delegates to `ingestLead()` with `defaultIngestDeps + buildIngestObservability(sourceId).deps`; 500 handler wraps in `Sentry.captureException` with `stage: "unhandled"`.

Specific reports are grep-able, defendable, and give the reviewer an entry point.

### Honesty about what was NOT done

This is the section users are most grateful for. "Not done in this round" prevents the "you said you did X but I can't find it" cycle. Include anything that a reasonable reader might expect to be in this round but isn't. Be explicit about deferrals.

### Decisions are one paragraph, not essays

Each design decision gets one short paragraph:

- What the decision was.
- Why this option over the alternatives.
- Link to DECISIONS.md if it's non-obvious.

If you find yourself writing more than a paragraph, it's probably a standalone DECISIONS.md entry — do that, and reference it from the report.

### Known issues are not memory

If the round discovered a pre-existing bug, security gap, technical debt item, or deferred fix outside current scope, it belongs in `KNOWN_ISSUES.md` with a `KI-NNN` entry. The round report should reference the KI; today's memory can say the KI was added, but memory is not the durable issue catalog.

### Test evidence should be exact

Don't approximate. If your test runner says "23 tests, 23 passing," report that with the exact command you ran. If a command was skipped, timed out, failed, or required a local service/env var that was unavailable, say so. If integration tests aren't passing, say so loudly (it's an open issue, not something to gloss over). A reviewer must be able to decide whether the evidence is adequate without trusting memory from the conversation.

### Open questions should be actionable

Bad:
> Should we think about rate limiting?

Good:
> Rate limiting strategy — plan §8 left this stubbed behind a feature flag. Options:
> (a) keep stubbed, revisit in hardening phase;
> (b) implement now with Upstash (~1h);
> (c) implement with an in-memory limiter (not production-safe but catches runaway tests locally).
> Recommend (a). OK to keep the stub?

Actionable questions can be answered with a short reply.

### The "next suggested round" recommendation

You've been deep in the code; you have the best sense of what should come next and why. Make a recommendation, even if it's "fix these follow-ups then proceed to X." Don't leave the user guessing.

### Auto-review history is not optional when auto-review fired

Auto-review is the default for Checkpoints 2/3/4. If it fired, the history must appear in the report — every attempt, every reviewer's verdict, every gate, with file:line evidence as the reviewers returned it (verbatim from `docs/reviews/round-XN-attempt-N-{reviewer}.md`). On attempt 1 all three reviewers' outputs appear; on attempt 2 both reviewers' outputs appear; on attempt 3 the Opus output appears, along with the prior findings it was asked to re-check. The user uses this to spot-check the reviewers' calls. Don't summarize ("3 attempts, eventual PASS"); paste the structured output. Omitting or compressing it defeats the purpose of the audit trail.

If auto-review did not fire (Checkpoint 1 or 5, user opt-out, or always-escalate trigger), omit the section entirely.

## What NOT to include

- Long stretches of code. The user can read the files. Reports are about *why* and *what changed at a high level*, not *line-by-line what the code looks like*.
- Apologies for taking time. Just deliver.
- Hedging. Don't say "I think" when you mean "I did." Don't say "probably works" — either it passes tests or it doesn't.
- Restating the plan. The plan is its own document; the report is about divergence and progress against it.

## Example (short but complete)

> ## Round B — Sources CRUD (API only)
>
> ### Delivered
>
> - `src/app/api/sources/route.ts` — `GET` list, `POST` create (returns secret once).
> - `src/app/api/sources/[id]/route.ts` — `GET` (masked), `PATCH`, `DELETE`.
> - `src/app/api/sources/[id]/rotate-secret/route.ts` — `POST`.
> - `src/app/api/sources/[id]/test-webhook/route.ts` — `POST` dry-run.
> - `src/lib/sources/service.ts` — CRUD via `dbService`, explicit `organization_id` filter.
> - `src/lib/sources/validation.ts` — schemas for mapping, custom fields, country alpha-2.
> - Unit tests: 25 new (9 suites, 117 total passing). Integration tests: 23 new (2 suites, 34 total passing).
>
> ### Design decisions worth review
>
> 1. Secret masking uses `null` sentinel in `GET` responses, not `"****"`. Non-ambiguous (see DECISIONS.md #28).
> 2. `rotate-secret` invalidates prior secret immediately; no grace period in Phase 1 (see DECISIONS.md #29).
> 3. Webhook URL built from `[base URL env var]`, not `Host` header. Preview deploys would otherwise burn ephemeral URLs into source records (see DECISIONS.md #30).
> 4. `requireRoleApi()` for JSON API routes vs `requireRole()` for page redirects. Two guards, two purposes (see DECISIONS.md #31).
>
> ### Known issues / technical debt updates
>
> - None.
>
> ### Testing
>
> - Commands/checks run:
>   - `pnpm test:unit -- sources` — PASS, 117 tests passing, 789ms.
>   - `pnpm test:integration -- sources` — PASS, 34 tests passing, 12.96s against `[local DB service]`.
> - Skipped/not run: None.
> - Manual smoke: tested full create → POST signed payload → dedup detect → rotate → old secret 401 flow against `[local DB service]`. No issues.
> - Evidence notes: local DB reset before integration run; webhook secret fixtures generated by test setup.
>
> ### Not done in this round
>
> - UI (`/[orgSlug]/sources`, `/[orgSlug]/leads`) — Round C.
> - End-of-phase housekeeping (update `PROJECT_STRUCTURE.md`, smoke test doc) — Round D.
>
> ### Open questions
>
> Does `test-webhook` import `defaultIngestDeps`, or is it a standalone dry-run reusing only `applyMapping` + `normalizePhone`? Answer: standalone, in `src/lib/sources/test-webhook.ts` — 1 SELECT, zero writes. Integration test confirms zero side effects.
>
> ### Next suggested round
>
> Round C — UI (Sources pages + Leads list). Shares components, makes sense to do together.
