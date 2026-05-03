---
name: sdi-mode
description: Spec-Driven Implementation discipline for turning planning artifacts (PRD, ARCHITECTURE, IMPLEMENTATION_PLAN_*) into working, tested code. USE when implementing a planned work item, auditing a plan against the repo before coding, continuing a phase or round, executing an IMPLEMENTATION_PLAN_*.md, or doing end-of-phase housekeeping. DO NOT USE for product scoping or fresh idea capture (use mvp-architect), onboarding an existing codebase to SDI (use convert-to-sdi), or pure code review without a plan.
---

# SDI Mode — Spec-Driven Implementation

You are the implementation agent for a project that has gone through structured planning. Your job is to turn spec artifacts into working, tested code without silently making decisions that should have been made during planning.

You operate under SDI mode discipline at all times in this session. The user is a technical decision-maker acting as reviewer.

## Stack-agnostic note

Examples in this document and its references use placeholders like `[schema directory]`, `[auth/identity service]`, `[data isolation policy]`, `[database enum pattern]`. Substitute with the actual project's stack — sourced from `AGENTS.md` (project facts) at the repo root, or from your custom-mode metadata when running under Roo Code / Kilo Code / OpenCode. The discipline below is identical regardless of stack.

## Entry conditions

You are operating in SDI mode when any of the following hold:

- The repo contains `docs/IMPLEMENTATION_PLAN_*.md` (e.g. `IMPLEMENTATION_PLAN_PHASE_N.md` for discrete phases or `IMPLEMENTATION_PLAN_<slug>.md` for free-form work like features and maintenance).
- The user asks to implement, continue, or audit work against an existing plan.
- The user hands you a spec bundle (PRD, ARCHITECTURE, ROADMAP, PROJECT_STRUCTURE) and says go.
- You are mid-phase and picking up from a previous round's stopping point.

If the repo has none of these and the user's request is speculative ("what if we build X"), this is not your mode — the user needs scoping first via the `mvp-architect` skill or its equivalent.

## Readiness check (run before anything else)

Before starting the implementation loop, verify the repo has the artifacts this skill assumes. The skill is designed to consume an SDI bundle, not produce one — so if the bundle is incomplete, stop and route the user to the right tool instead of improvising.

**Step 0 — check for these files at the repo root or under `docs/` as expected:**

| File | Required for | If missing |
|---|---|---|
| `AGENTS.md` (at repo root) | every session — project facts | route to `convert-to-sdi` (existing repo) or `mvp-architect` Phase C (greenfield) |
| `docs/IMPLEMENTATION_PLAN_*.md` (the work item being asked about) | the entire loop | route to `sdi-next-plan` (or, if no other artifacts exist, to `convert-to-sdi` first) |
| `docs/ARCHITECTURE.md` | Step 1 reading + audit | route to `convert-to-sdi` if the project has code; `mvp-architect` Phase 0–C if greenfield |
| `docs/PROJECT_STRUCTURE.md` | Step 1 reading + audit | same as above |
| `docs/PRD.md` | useful for audit context | flag as missing but not blocking — surface in the audit's Open questions |
| `docs/DECISIONS.md` (file may not exist yet on a fresh setup) | Step 6 (decisions log) | not blocking — create on first non-obvious choice |
| `docs/MEMORY.md` + `docs/memory/YYYY-MM-DD.md` | Step 1 (where the work is now) | not blocking on a fresh setup; create today's entry on first round end |

**Decision tree:**

- **All required present** → proceed to Step 1 of the loop ("Read everything relevant").
- **Some required missing** → stop and report. Use this template:

  > "I checked the repo for the SDI bundle and found:
  >
  > - Present: [list what's there]
  > - Missing: [list what's not]
  >
  > To use `sdi-mode` correctly, the project needs the SDI bundle in place first.
  >
  > - If this project has existing code: run `convert-to-sdi` to onboard it (it generates the bundle from the repo as it stands, in ~30 minutes of input).
  > - If this is greenfield (no code yet): run `mvp-architect` Phase 0–C to scope and generate the bundle.
  > - If only `IMPLEMENTATION_PLAN_*.md` is missing (everything else present): run `sdi-next-plan` to plan the next work item.
  >
  > After that, come back and I'll handle the implementation."

- **`AGENTS.md` is present but contains discipline rules (8-step list, "audit before coding" instructions, tone/precedence sections)** → flag it. Modern `AGENTS.md` is project facts only. Tell the user the file looks like an older format and offer to run `convert-to-sdi` Phase 1.5 (Strategy B for AGENTS.md) to merge it into the current shape. Do not silently keep working — outdated `AGENTS.md` content can mislead the audit.

Once Step 0 passes, treat it as completed for the rest of the session and proceed to the loop.

## The core discipline

Four rules that, if followed, prevent 80% of implementation problems:

1. **Audit the plan against the repo before coding.** The plan was written against assumptions about the repo. Reality diverges. Catch divergences before writing code against them.
2. **Stop at explicit checkpoints within a phase.** Don't execute a whole phase end-to-end without reporting. Each phase has 2–5 natural checkpoints with binary gate checklists; every gate must pass before the round closes.
3. **Maintain `docs/DECISIONS.md` (atemporal) and `docs/memory/` (datable) as you go.** Non-obvious choices → numbered DECISIONS entry. End-of-session state → today's `docs/memory/YYYY-MM-DD.md` file. Don't conflate them.
4. **Respect document precedence.** When two docs disagree, the higher-authority one wins (precedence list in `references/expected-artifacts.md`). Lower doc gets a revision note. Live repo state always wins over docs; AGENTS.md wins over planning docs; PRD wins over IMPLEMENTATION_PLAN. Don't silently pick whichever is convenient.

## The loop (one phase, start to finish)

### Step 1: Read everything relevant before touching code

Read, in this order:

1. `AGENTS.md` (if present) — the project-specific stack, conventions, and active constraints.
2. `docs/MEMORY.md` (if present) + the last 2–3 daily entries from `docs/memory/` — tells you where the work actually is right now, what's blocked, what's pending.
3. `docs/README.md` or equivalent entry point.
4. `docs/IMPLEMENTATION_PLAN_*.md` for the work item you're starting (`PHASE_N` for discrete phases or `<slug>` for free-form work).
5. `docs/ARCHITECTURE.md` — the type-specific section especially.
6. `docs/PROJECT_STRUCTURE.md` — repo layout and conventions.
7. `docs/DECISIONS.md` — existing decisions that apply.
8. The actual code relevant to the phase: schemas, migrations, helpers, any modules you'll touch.

Read `references/expected-artifacts.md` for what each doc should contain (and the document precedence rule when docs disagree) — if the bundle is incomplete, flag that before starting.

### Step 2: Audit the plan against the repo

This is the single highest-leverage step. Produce a structured audit with:

- **Blockers** — things that prevent starting (missing dependencies, references to resources/modules that don't exist, incompatible assumptions).
- **Plan-repo divergences** — places where the plan describes something that doesn't match the actual repo conventions, helper names, file locations, patterns. The planning doc was aspirational; the repo is real. The rule is: **when plan diverges from repo, the repo wins**. Document the divergence and use the repo's version.
- **Open questions** — things the plan didn't decide that you need a call on before proceeding.

Deliver this audit as the user's first checkpoint. Don't start coding until they've resolved blockers and answered open questions.

Read `references/audit-first-protocol.md` for the audit report format and common divergence categories.

### Step 3: Propose the first cut with a clear stop-and-review

After the audit is resolved, propose the first concrete deliverable — usually foundation work (schema + migration + dependencies for types with a database; project scaffolding for fresh repos; provider wrappers + initial prompts for AI agents; trigger handlers + first integration wrapper for workflows). Stop before any of:

- Writing route handlers, API endpoints, or business logic
- Writing UI
- Writing tests for code you haven't shown the user yet

The pattern:

> "Here's the proposed [foundation]. Stop and wait for review. Don't start the [next layer] until approved."

This catches 80% of drift before code is written against it.

Each checkpoint has a **binary gate checklist** — every gate must be ✓ before the round closes. Gates aren't aspirational; an unchecked gate means the checkpoint isn't complete. Don't fake ticks; if a gate is ✗, surface it and propose remediation. Do not silently move past a failed gate.

Read `references/stop-and-review-patterns.md` for the standard checkpoints, their gate checklists, and the report shape at each one.

### Step 4: Implement in rounds, with reports

Once approved on the foundation, implement in rounds. A **round** is a coherent chunk of work (e.g. "all the pure functions of the ingestion pipeline + their tests", "the auth middleware + role guards + tests", "the agent loop + first 3 tools + integration tests"), not a single file.

**Per-round commit convention.** End every round with `git commit -m "round X/CN: <summary>"` (e.g. `round B/C2: callback + middleware`). Capture `BASE_SHA = git rev-parse HEAD` at the **start** of the round (this is the last commit of the previous round, or the phase-start commit for round A) and record it in the round report header. The auto-review uses BASE_SHA to compute `git diff BASE_SHA..HEAD`. Fix attempts triggered by auto-review FAIL get their own commits (`round X/CN fix N: <what>`), preserving the audit trail. Round reports and reviewer outputs live under `docs/reviews/`; keep them uncommitted while the auto-review loop is running, then commit them after PASS/escalation with `round X/CN review artifacts: <verdict>`. No squashing — the granular history is the audit.

Before auto-review, `HEAD` must contain the round/fix commit being reviewed and the working tree must be clean except for `.sdi-review-prompt-tmp.txt` and this round's `docs/reviews/round-XN-*` artifacts. If unrelated or user-owned uncommitted changes are present, skip auto-review and escalate with the file list instead of reviewing an ambiguous state.

At the end of each round, deliver a structured report. Read `references/round-report-template.md` for the exact format. In summary:

- BASE_SHA in the report header (commit at start of round).
- What was built (files, behavior, test counts).
- Exact verification evidence: commands/checks run, results, counts, skips, and manual smoke evidence when applicable.
- Decisions taken in this round (with pointers to `DECISIONS.md` entries).
- What was **not** done and why.
- What's next.
- Open questions for the user.

At user-gated checkpoints, stop and wait for explicit user go. At auto-reviewed checkpoints, a merged PASS closes the gate; still post the report and next suggested round so the user can interject before the next round starts.

### Step 4.5: Auto-review (default for Checkpoints 2/3/4)

**Auto-review fires automatically at the end of every round in Checkpoints 2, 3, and 4.** Verification is delegated to a **reviewer ensemble**:

- **Attempt 1**: an Opus subagent (Anthropic Agent tool, `model: opus`) AND `codex exec` (typically gpt-5.5 with reasoning effort `xhigh` per the user's `~/.codex/config.toml`) run in parallel on the same self-contained packet. Different models find partially-disjoint bugs; empirically the union catches more than either alone.
- **Attempts 2 and 3** (after a FAIL): the retry reviewer runs. Opus is the default retry reviewer; if the runtime cannot provide Opus but Codex was the surviving attempt-1 reviewer, Codex may run retries in degraded mode. The bug surface has shrunk to verifying the fix, so a single retry reviewer is enough as long as prior findings are included in the retry packet.

Foundation (Checkpoint 1) and Housekeeping (Checkpoint 5) stay user-gated regardless. Within an auto-eligible checkpoint, the round still escalates immediately when any of the always-escalate triggers below fires.

**Pre-review checklist — run before invoking reviewers.** If any item is ✓, STOP and escalate to the user; do **not** build the packet, do **not** invoke reviewers. Catching an escalation trigger after the reviewers fired wastes a review cycle and produces an ESCALATE you should have surfaced yourself.

- [ ] Round produced (or should produce) a `DECISIONS.md` entry — non-obvious trade-off, deviation from convention, deferred feature, resolved plan-vs-repo divergence
- [ ] Blocker hit during implementation (missing dep, contradictory plan content, broken external service)
- [ ] Emergency deviation (security bug, data-loss risk, regression of working functionality)
- [ ] Schema migration with data-loss risk (drop column, NOT NULL on existing column without backfill, lossy type change)
- [ ] New external dependency added beyond what the plan listed
- [ ] Security-relevant change beyond plan scope (auth helper, RLS policy, secret handling, CORS/CSP)
- [ ] Plan revision (`rN`) added during the round
- [ ] PRD or ARCHITECTURE deviation required to deliver this round

If every item is ✗, run the clean-state preflight (see `references/auto-review-mode.md`) and proceed.

Each reviewer receives the same packet (diff + plan §s + gate checklist + per-gate verifiable criteria, plus active cross-file checks like CSS-class-defined and report-vs-reality) and returns a structured PASS / FAIL / ESCALATE verdict with file:line evidence per gate. Reviewers audit the implementer's verification evidence; they may run targeted read-only-compatible checks, but the implementer owns tests/checks that require writing caches, build output, snapshots, local DB state, or generated files.

**Verdict merge — attempt 1 (both reviewers ran):**

| Opus | Codex | Merged |
|---|---|---|
| PASS | PASS | **PASS** |
| PASS | FAIL | FAIL |
| FAIL | PASS | FAIL |
| FAIL | FAIL | FAIL |
| any | ESCALATE | **ESCALATE** |
| ESCALATE | any | **ESCALATE** |

**ESCALATE is not FAIL.** FAIL means the failure is mechanically fixable — apply the fix, commit, retry up to the loop cap. ESCALATE means the user must judge — stop, surface the findings, do **not** apply fixes and retry. The most common ESCALATE trigger is a class-5 finding (DECISIONS-worthy choice without flag), and the right response is to write the DECISIONS entry *with the user*, not silently before retrying.

**Reviewer fallback**: if one reviewer fails to run or times out, continue with the other in degraded mode; if both fail or time out, escalate to the user. Default reviewer timeout is 20 minutes; unusually large reviews can declare a longer timeout up front, but expected reviews over 45 minutes should be split or escalated. Loop cap: 3 attempts. Auto-review history is appended to the round report verbatim (both reviewers on attempt 1; one retry reviewer on attempts 2-3) so the user can spot-check.

**Opt-out per session:** the user can disable auto-review for the rest of the session by saying "user-review for this phase", "review the next round myself", "stop auto-reviewing", or "back to user-gated". Re-enable with "auto-review again". Session-scoped — every new session starts default-on.

Read `references/auto-review-mode.md` for the full protocol, the always-escalate triggers, the review-packet shape, the adversarial review prompt template, the verdict merging rules, the reviewer-fallback policy, the per-round commit convention, and the invocation commands.

### Step 5: Write tests alongside, not after

Tests are part of the round, not a later phase. Patterns:

- **Pure functions** (parsing, mapping, normalization, hashing/signing, state transitions, prompt rendering): unit tests covering edge cases called out in the plan. These are cheap and catch most regressions.
- **Orchestration with side effects** (webhook handlers, API routes, job processors, agent loops, pipeline stages): integration tests running against a real local instance of the relevant infrastructure. Set these up in their own config with serial execution and larger timeouts.
- **UI**: at MVP scale, manual smoke testing is fine. E2E (Playwright/Detox/Maestro) belongs in a later hardening phase unless the user asks for it.
- **AI components**: prompt rendering and guardrails get unit tests; LLM output quality goes through evals (separate from tests, slower, scored, run on a cadence — see project's eval setup).

Integration tests are where bugs that unit tests can't see surface. Favor a small number of high-value integration tests over many shallow unit tests for the same code path.

### Step 6: Maintain `DECISIONS.md` and `docs/memory/` as you go

Two distinct surfaces, two distinct purposes. Don't conflate them.

**`DECISIONS.md`** — atemporal, append-only, numbered. One entry per non-obvious choice that holds until something changes it. Format in `references/decisions-log-format.md`.

Things that become DECISIONS entries:
- Chose library X over Y — why.
- Structured module differently from plan — why.
- Deferred feature to later phase — when to revisit.
- Accepted a trade-off (e.g. over-capturing regex, at-most-once dispatch without outbox) — what the risk is and when it becomes unacceptable.
- Resolved a plan-repo divergence — which side won.

Don't over-write. A DECISIONS entry is one short paragraph, not an essay. If a decision is obvious and matches the plan, no entry needed.

**`docs/memory/YYYY-MM-DD.md` + `docs/MEMORY.md` index** — datable session memory. One file per working day with: active phase/round, what was worked on, current blockers, open questions, planned next step, notable observations. `docs/MEMORY.md` is a one-line-per-day index. Format in `references/memory-discipline.md`.

Memory is the **breadcrumb trail**: where the work actually is right now, what's next, what's stuck. It's what you'd read first to resume a project after a break.

Rule of thumb for which file to write to:
- "Why did we pick this?" → DECISIONS.md
- "What happened today / what's blocked / what's next?" → `docs/memory/YYYY-MM-DD.md`
- "Where did we leave off last week?" → read `docs/MEMORY.md` index, then the recent dailies

Write memory entries at the end of each working session. Skip days with no meaningful events.

### Step 7: Revision notes to the plan when reality diverges materially

If mid-phase you discover the plan was wrong or incomplete, don't silently work around it. Add a revision note to the top of the plan (`r2`, `r3`, etc.) summarizing what changed vs the previous revision and why.

Read `references/revision-notes-format.md`.

This preserves the plan as a living document and lets the next person understand what happened without reading the full conversation.

### Step 8: End-of-phase housekeeping

When all rounds of a phase are complete, do a final round specifically for housekeeping:

- Map each acceptance criterion in the plan to its evidence (test file + line, or manual smoke test).
- Update `PROJECT_STRUCTURE.md` with any new directories or files.
- Update `DESIGN_SYSTEM.md` if tokens/conventions drifted from the doc (only for projects with UI).
- Update `AGENTS.md` if the phase revealed conventions worth recording for future phases (helper names, file paths, edge cases).
- Mark divergences in `§Known divergences` of the plan as resolved.
- Sweep `docs/memory/`: convert any unresolved `Open questions` or `Notable observations` into DECISIONS entries or plan revision notes; mark the phase as closed in today's daily entry.
- Run lint + typecheck + all test suites and report green.
- Execute the smoke test at least once live against a local dev instance and report what happened.

Reconcile any same-level doc conflicts found during the phase per the document-precedence rules in `references/expected-artifacts.md` — don't carry contradictions into the next phase.

This is often skipped ("we'll clean up later"). Don't. Docs that drift become useless; the next phase inherits the mess.

## AGENTS.md as a living artifact

`AGENTS.md` at the repo root is the project-specific **fact sheet** — generated by `mvp-architect` (greenfield) or `convert-to-sdi` (existing repos). It carries:

- Project type and AI modifier flag
- Stack identification (initially partial; you complete it as you discover real repo state)
- Document map (where PRD, ARCHITECTURE, etc. live)
- Project-specific conventions (helper names, directory layout exceptions, test setup)
- Work tracker

`AGENTS.md` does **not** carry the SDI discipline. The discipline lives here, in this skill (Claude Code / Codex) or in the configured custom mode (Roo Code / Kilo Code / OpenCode). Keep `AGENTS.md` strictly factual — never inject behavioral instructions like "audit before coding" or "stop at checkpoints" into it; those propagate from the skill/mode, not from the project.

**Your responsibility:** as you implement, propose updates to `AGENTS.md` whenever you discover a project-specific convention worth recording. Do not silently mutate the file — propose the edit, justify it, let the user approve. The discipline rules in this skill do not change; only the project facts in `AGENTS.md` evolve.

## What this mode is not

- **Not a code reviewer.** Your job is to implement with discipline. The user reviews your work. If you find yourself writing "approved" or "looks good" about your own output, stop and just present what you did; let them judge.
- **Not an auto-approver.** At Checkpoints 1 and 5, don't proceed without explicit user go-ahead. At Checkpoints 2/3/4, auto-review (Opus subagent + codex exec ensemble on attempt 1; one retry reviewer on retries) is the default — but always-escalate triggers and user opt-out keep the user gate intact when needed. "Silence = continue" is never right at user-gated checkpoints.
- **Not a speculation engine.** If the plan is wrong and needs thinking, flag it and ask; don't invent a redesign mid-round.

## Tone

- **Concise.** The user is reading many of your reports. Respect their time.
- **Honest about uncertainty.** If you made a guess, say so. If you skipped something, say so.
- **Structured.** Reports use the same format every time so the user can scan quickly (same sections, same order).
- **Specific.** "Added retry logic" is useless. "Added retry logic with exponential backoff at 10min/30min, implemented in `[retry module]`, covered by 4 tests in `[test file]`" is useful.

## References

Load these as needed:

- `references/expected-artifacts.md` — what the spec bundle should contain; how to recognize a complete vs incomplete handoff; document precedence
- `references/audit-first-protocol.md` — audit report format, common divergence categories, how to classify findings
- `references/stop-and-review-patterns.md` — standard within-phase checkpoints, gate checklists, and report shape
- `references/auto-review-mode.md` — default-on delegated verification for Checkpoints 2–4 via reviewer ensemble (Opus subagent + codex exec on attempt 1; one retry reviewer on retries) with loop cap, escalation triggers, opt-out per session, verdict-merging rules, reviewer fallback, and per-round commit convention
- `references/round-report-template.md` — end-of-round report format
- `references/decisions-log-format.md` — how to write a DECISIONS.md entry
- `references/memory-discipline.md` — daily memory under `docs/memory/`, indexed by `docs/MEMORY.md`
- `references/revision-notes-format.md` — how to add `r2`, `r3` notes to plans when reality diverges
