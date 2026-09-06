# Round Report Template

Every implementation round ends with a report: same sections, same order, so a user reading many of them can scan. The size ceiling is whatever the project's doc lint says (`scripts/docs_bounds.py` where the project has one) — cited here, never repeated.

## The shape

````markdown
## Round [letter or number] — [one-line description]

> **BASE_SHA:** [last `round X/CN review artifacts` commit of the previous round; for round A, the phase-start commit — `auto-review-mode.md` §"Per-round commit convention".]
> **PHASE_BASE_SHA:** [round A only; later rounds reference this value literally.]
> **Commit A SHA (code-only):** [sha of `round X/CN: <summary>`.]
> **Commit B SHA (this report):** `at HEAD <SHA-A>`.

### Delivered

[One line per file touched or created: path, what it does / why it changed, test coverage (counts or "n/a").]

### Design decisions worth review

1. [Decision + rationale + link to the DECISIONS entry if there is one.]

### Known issues / technical debt updates

- `KI-NNN` — [new / scheduled / partially mitigated / resolved], [one-line evidence or commit/status note]. "None" if the round touched none.

### Testing

[The generated block and nothing else — `<!-- test-summary -->…<!-- /test-summary -->` for the suite, `<!-- unittest-summary -->…<!-- /unittest-summary -->` for script tests and declared mutation proofs. A count written by hand outside the block is a lint failure. If the project has no generator, paste the runner's own output and name the command that produced it: the rule is that numbers are copied from a machine, never retyped from memory.]

### Auto-review history (default for Checkpoints 2/3/4/5)

[**By link.** One row per reviewer per attempt: verdict, totals by mark, and the path to that reviewer's committed report. Do **not** paste the reports — they are files, and pasting them is what made this section unreadable.

| Attempt | Reviewer | Verdict | `[code]` | `[gate]` | `[docs]` | Report |
|---|---|---|---|---|---|---|
| 1 | opus | FAIL | 2 | 0 | 3 | `docs/reviews/round-XN-attempt-1-opus.md` |
| 1 | sonnet | PASS | 0 | 0 | 1 | `docs/reviews/round-XN-attempt-1-sonnet.md` |

Under the table, one line each: the merged verdict per attempt and the mark that decided it (`auto-review-mode.md` §"Marks and the verdict matrix"); the reach measurement for every `[code]` finding that failed; the Decision Bundle action; the fix commit SHAs; and any runtime note — degraded mode, timeout, a **recorded** Codex→Haiku authorization, a convergence trigger, or a user authorization past the cap.

Omit the section only when the round was Checkpoint 1, the user opted out this session, or an always-escalate trigger made the round user-gated.]

## Decisões desta rodada

[Fixed section, this exact heading, in every round report. One line per `DECISIONS.md` or `KNOWN_ISSUES.md` entry written during the round: number, slug, decision in one sentence. Write "Nenhuma" when there were none — the empty statement is the evidence that the question was asked. Writing it is mandatory and happens **in the round**; reading it is the user's option. It replaced stopping the round for every decision and known-issue entry.]

- `#N` `slug-da-decisao` — [what was decided, one sentence].
- `KI-NNN` `slug-da-ki` — [what is wrong, one sentence, and the status it was written with].

## Paper-trail backlog

[Required whenever non-empty. Findings the mark matrix deferred, one line each: `[mark] [class] file:line — what is wrong — which attempt found it`. Carry it forward at every attempt and hand it to CP5, where it is paid. An empty backlog at CP5 with a non-empty history is a defect.]

### Not done in this round (and why)

[Explicit list of deferred scope. For each: what, why, where it goes.]

### Open questions for the user

1. [Specific question with options if you have a view.]

### Next suggested round

[One-paragraph recommendation, or the options if there is a real fork.]
````

## Rules for writing a good report

**Specificity over summary.** Not "added the webhook handler and some tests", but "`src/app/api/webhooks/ingest/[sourceId]/route.ts` — POST handler using `await request.text()` to preserve HMAC bytes; delegates to `ingestLead()`; the 500 handler captures with `stage: "unhandled"`". Specific reports are grep-able, defendable, and give the reviewer an entry point.

**Honesty about what was NOT done.** This is the section users are most grateful for: it prevents the "you said you did X but I can't find it" cycle. Include anything a reasonable reader would expect in this round and won't find.

**Decisions are one paragraph.** What was decided, why this option, link to the entry if it's non-obvious. More than a paragraph means it is a standalone `DECISIONS.md` entry — write it there and reference it.

**Known issues are not memory.** A pre-existing bug, security gap, debt item, or deferred fix belongs in `KNOWN_ISSUES.md` as a `KI-NNN`. The report references it; memory may say it was added, but memory is not the durable catalog.

**Test evidence comes from the generator.** Don't approximate and don't retype. Skips, timeouts, and unavailable services appear in the block or in one line beside it. A reviewer must be able to judge the evidence without trusting anyone's memory of the conversation.

**Open questions should be actionable.** Not "should we think about rate limiting?", but "plan §8 left rate limiting stubbed behind a flag. (a) keep the stub, revisit in hardening; (b) implement now with a hosted limiter (~1h); (c) in-memory limiter, not production-safe. Recommend (a) — OK?"

**Make a next-round recommendation.** You've been deep in the code; you have the best sense of what comes next, even if it's "fix these follow-ups, then X."

## What NOT to include

- Long stretches of code, and **reviewer reports pasted inline** — both are files the user can open; link to them.
- Test counts typed by hand outside the generated block.
- Apologies, or hedging. Either it passes or it doesn't.
- Restating the plan. The report is about divergence and progress against it.
