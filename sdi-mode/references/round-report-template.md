# Round Report Template

Every implementation round ends with a report. Same sections, same order. Users read many of these; consistency lets them scan quickly. The report's size ceiling is whatever the project's doc lint says (`scripts/docs_bounds.py` where the project has one) — cited here, never repeated.

## The shape

````markdown
## Round [letter or number] — [one-line description]

> **BASE_SHA:** [sha of the last `round X/CN review artifacts: <verdict>` commit of the previous round, OR for round A the phase-start commit. See `auto-review-mode.md` §"Per-round commit convention".]
>
> **PHASE_BASE_SHA:** [round A only — sha of the phase-start commit; later rounds reference this value literally.]
>
> **Commit A SHA (code-only):** [sha of `round X/CN: <summary>`.]
>
> **Commit B SHA (this report, paper trail):** `at HEAD <SHA-A>`.

### Delivered

[One line per file touched or created: path, what it does / why it changed, test coverage (counts or "n/a").]

### Design decisions worth review

1. [Decision + rationale + link to the DECISIONS entry if there is one.]

### Known issues / technical debt updates

- `KI-NNN` — [new / scheduled / partially mitigated / resolved], [one-line evidence or commit/status note]. "None" if the round touched none.

### Testing

[The generated block and nothing else:

<!-- test-summary -->
…the suite generator's output…
<!-- /test-summary -->

<!-- unittest-summary -->
…the script-test and declared-mutation generator's output…
<!-- /unittest-summary -->

A count written by hand outside the block is a lint failure. If the project has no generator, paste the runner's own output verbatim and name the command that produced it — the rule is that the numbers are copied from a machine, never retyped from memory.]

### Auto-review history (default for Checkpoints 2/3/4/5)

[**By link.** One row per reviewer per attempt: verdict, totals by mark, and the path to that reviewer's own report, which is committed with the round. Do **not** paste the reports — they are files, and pasting them is what made this section unreadable.

| Attempt | Reviewer | Verdict | `[code]` | `[gate]` | `[docs]` | Report |
|---|---|---|---|---|---|---|
| 1 | opus | FAIL | 2 | 0 | 3 | `docs/reviews/round-XN-attempt-1-opus.md` |
| 1 | sonnet | PASS | 0 | 0 | 1 | `docs/reviews/round-XN-attempt-1-sonnet.md` |
| 1 | codex | FAIL | 1 | 1 | 0 | `docs/reviews/round-XN-attempt-1-codex.md` |

Under the table, one line each: merged verdict per attempt and the mark that decided it (`auto-review-mode.md` §"Marks and the verdict matrix"); the reach measurement for every `[code]` finding that failed the attempt; the Decision Bundle action taken (obvious fixes applied / continued / paused for user); the fix commit SHAs; and any runtime note — degraded mode, timeout, a **recorded** Codex→Haiku authorization, a convergence trigger, or the user authorization for an attempt past the cap.

Omit the whole section only when (a) the round was Checkpoint 1, (b) the user opted out of auto-review this session, or (c) an always-escalate trigger fired and the round was user-gated.]

## Decisões desta rodada

[Fixed section, this exact heading, present in every round report. One line per `DECISIONS.md` or `KNOWN_ISSUES.md` entry written during the round: number, slug, and the decision in one sentence. Write "Nenhuma" when the round wrote none — the empty statement is the evidence that the question was asked.

Writing this is mandatory and happens **in the round**; reading it is the user's option. It is the mechanism that replaced stopping the round for every decision entry and every known-issue entry.]

- `#N` `slug-da-decisao` — [what was decided, one sentence].
- `KI-NNN` `slug-da-ki` — [what is wrong, one sentence, and the status it was written with].

## Paper-trail backlog

[Required whenever non-empty. Findings the mark matrix deferred, one line each: `[mark] [class] file:line — what is wrong — which attempt found it`. Carry it forward at every attempt and hand it to CP5, where it is paid. An empty backlog at CP5 with a non-empty history is a defect, not a saving.]

### Not done in this round (and why)

[Explicit list of deferred scope. For each: what, why, where it goes.]

### Open questions for the user

1. [Specific question with options if you have a view.]

### Next suggested round

[One-paragraph recommendation, or the options if there is a real fork.]
````

## Rules for writing a good report

### Specificity over summary

Bad:
> Added the webhook handler and some tests.

Good:
> `src/app/api/webhooks/ingest/[sourceId]/route.ts` — POST handler using `await request.text()` to preserve HMAC bytes; delegates to `ingestLead()` with `defaultIngestDeps + buildIngestObservability(sourceId).deps`; 500 handler wraps in `Sentry.captureException` with `stage: "unhandled"`.

Specific reports are grep-able, defendable, and give the reviewer an entry point.

### Honesty about what was NOT done

This is the section users are most grateful for. "Not done in this round" prevents the "you said you did X but I can't find it" cycle. Include anything a reasonable reader might expect to be in this round but isn't.

### Decisions are one paragraph, not essays

What the decision was, why this option, link to the DECISIONS entry if it's non-obvious. More than a paragraph means it is a standalone entry — write it there and reference it from the report.

### Known issues are not memory

A pre-existing bug, security gap, debt item, or deferred fix belongs in `KNOWN_ISSUES.md` as a `KI-NNN` entry. The report references the KI; today's memory can say the KI was added, but memory is not the durable catalog.

### Test evidence comes from the generator

Don't approximate and don't retype. The `Testing` section is the generated block; skips, timeouts, and unavailable local services appear in it or in one line beside it. A reviewer must be able to decide whether the evidence is adequate without trusting anyone's memory of the conversation.

### Open questions should be actionable

Bad:
> Should we think about rate limiting?

Good:
> Rate limiting strategy — plan §8 left this stubbed behind a feature flag. Options: (a) keep stubbed, revisit in hardening; (b) implement now with Upstash (~1h); (c) in-memory limiter (not production-safe). Recommend (a). OK to keep the stub?

### The "next suggested round" recommendation

You've been deep in the code; you have the best sense of what should come next and why. Make a recommendation, even if it's "fix these follow-ups then proceed to X."

## What NOT to include

- Long stretches of code, and **reviewer reports pasted inline** — both are files the user can open; the report links to them.
- Test counts typed by hand outside the generated block.
- Apologies for taking time, or hedging. Either it passes or it doesn't.
- Restating the plan. The plan is its own document; the report is about divergence and progress against it.

## Example (short but complete)

> ## Round B — Sources CRUD (API only)
>
> ### Delivered
>
> - `src/app/api/sources/route.ts` — `GET` list, `POST` create (returns secret once).
> - `src/app/api/sources/[id]/route.ts` — `GET` (masked), `PATCH`, `DELETE`.
> - `src/lib/sources/service.ts` — CRUD via `dbService`, explicit `organization_id` filter.
> - `src/lib/sources/validation.ts` — schemas for mapping, custom fields, country alpha-2.
>
> ### Design decisions worth review
>
> 1. Secret masking uses a `null` sentinel in `GET` responses, not `"****"` — non-ambiguous (DECISIONS #28).
> 2. `rotate-secret` invalidates the prior secret immediately; no grace period in Phase 1 (DECISIONS #29).
>
> ### Known issues / technical debt updates
>
> - None.
>
> ### Testing
>
> > `<!-- test-summary -->` … generated table (commit, date, command, tests, failures, errors, skipped, time) … `<!-- /test-summary -->`
>
> ### Auto-review history
>
> | Attempt | Reviewer | Verdict | `[code]` | `[gate]` | `[docs]` | Report |
> |---|---|---|---|---|---|---|
> | 1 | opus | PASS | 0 | 0 | 2 | `docs/reviews/round-B-C2-attempt-1-opus.md` |
> | 1 | sonnet | PASS | 0 | 0 | 0 | `docs/reviews/round-B-C2-attempt-1-sonnet.md` |
> | 1 | codex | PASS | 0 | 0 | 1 | `docs/reviews/round-B-C2-attempt-1-codex.md` |
>
> Merged: PASS on attempt 1; three `[docs]` findings deferred to the backlog below.
>
> ## Decisões desta rodada
>
> - `#28` `secret-masking-null-sentinel` — masked secrets return `null`, not a fixed string, so "masked" and "empty" are distinguishable.
> - `#29` `no-grace-period-on-rotation` — rotation is an instant cutover in Phase 1; coordination with the single integrator is acceptable.
>
> ## Paper-trail backlog
>
> - `[docs]` `[4]` `docs/reviews/round-B-C2-report.md:31` — "34 integration tests" typed outside the generated block — attempt 1.
>
> ### Not done in this round
>
> - UI (`/[orgSlug]/sources`, `/[orgSlug]/leads`) — Round C.
>
> ### Next suggested round
>
> Round C — UI (Sources pages + Leads list). Shares components, makes sense to do together.
