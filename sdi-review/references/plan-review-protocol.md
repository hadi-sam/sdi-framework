# Plan review protocol

Framework for reviewing an SDI implementation plan. The coordinator dispatches the persistent work-item profile with the same adversarial prompt, deduplicates findings, applies only blocking mechanical fixes and escalates decisions. A reviewer never loads `sdi-review`.

This file is loaded by `sdi-review` for **Mode 1: plan review**. Other modes use `round-report-review-patterns.md`.

## Why this exists

A plan written by the same agent that scoped it tends to overstate readiness. Independent review cross-checks concrete claims against the repo, decisions and known issues. The coordinator uses the profiled reviewers; cross-vendor diversity is recommended, not a gate, and any scheduled failure returns to the PO without automatic replacement.

## When this is used

- **First-pass plan review** — no prior findings; the plan is freshly written or revised.
- **Second-pass plan review** — prior findings exist; the planner revised the plan in response and the user wants the revisions checked.

## Setup

Before starting:

1. Identify the plan file path (typically `docs/IMPLEMENTATION_PLAN_*.md`).
2. Identify the project's stack from `AGENTS.md` or `CLAUDE.md` (one-line summary — frontend, backend, db, key services).
3. Identify the repo root (project directory containing `AGENTS.md`, `CLAUDE.md`, or the planning `docs/` bundle).
4. For a second-pass review, locate the prior review output (`docs/reviews/plan-review-NN.md`).

## Where the review goes

- **Output file** (committed for audit trail): `docs/reviews/plan-review-NN.md` where `NN` is the pass number, zero-padded (`01`, `02`, ...). If `docs/reviews/` doesn't exist, create it.
- For second-pass reviews, read `docs/reviews/plan-review-01.md` first and verify each prior finding was addressed in the plan revision. Save the second-pass review as `docs/reviews/plan-review-02.md`.

## Steps you must perform

1. Read the plan file end to end.
2. Read `AGENTS.md` or `CLAUDE.md` (if either exists) for stack, conventions, project facts. If both exist, note any drift.
3. Read `docs/PRD.md` (if exists).
4. Read `docs/ARCHITECTURE.md` (if exists).
5. Read `docs/PROJECT_STRUCTURE.md` (if exists).
6. Read `docs/KNOWN_ISSUES.md` (if exists) — every open known issue may affect scope, prerequisites, or deferrals.
7. Read `docs/DECISIONS.md` (if exists) — every prior decision binds the new plan.
8. Spot-check the actual repo (Glob/Grep/Read) for any concrete reference the plan makes (helpers, files, modules, env vars).
9. **[Second pass only]** Read `docs/reviews/plan-review-01.md` and verify each prior finding was addressed; flag dismissals without justification.

## Things you MUST actively check

A. **Internal consistency** — § X says one thing, § Y says another (numbers, names, behaviors, lifetimes, ordering of rounds, dates, counts).

B. **Plan-vs-repo grounding (verify-before-claim audit)** — every reference to a file path / helper / env var / table / module / method / class / hook / file:line / precedent ("mirrors pattern of X") / count ("N sites to change") must exist in the repo or be created by the plan itself. Verify by Glob/Grep/Read, not by trust. **Plan reviews are especially vulnerable to fictitious citations** because the coding agent hasn't touched code yet — claims about "what exists" are easy to invent. Match the disciplined check K from the manual adversarial prompt: invented citations are class-3 (missing prerequisite), shape mismatches are class-1 (internal inconsistency). Especially watch for assertions like "(already exists in code)" / "(method available)" / "(N sites)" without Grep evidence immediately before the assertion in the plan prose.

C. **Plan-vs-DECISIONS** — every choice that overrides or contradicts a `DECISIONS.md` entry must be flagged.

D. **Plan-vs-KNOWN_ISSUES** — if the plan fixes `KI-NNN`, it must reference it and include a status-update gate. If it defers a known issue, it must not accidentally claim the issue is solved.

E. **Plan-vs-PRD/ARCHITECTURE precedence** — PRD wins over plan; ARCHITECTURE wins over plan. Any plan choice that contradicts a higher-precedence doc is a finding.

F. **Missing prerequisites** — references components, hooks, env vars, tables, helpers, conventions that no prior phase delivered AND this plan doesn't create.

G. **Vague or non-binary gates** — flag only when ambiguity breaks an existing mandatory gate or invalidates the only evidence for an approved acceptance criterion. `Verify tests pass` is vague; `run <existing command>, require exit 0 and the named isolation scenario to pass` is binary. The example does not authorize a new test or count by habit.

H. **DECISIONS-worthy choices not flagged** — library choice, architecture pattern, scope deviation, accepted trade-off — must be called out as new `DECISIONS.md` entries in the plan. If the plan picks library X over Y without a `DECISIONS.md` entry, that's a finding.

I. **Stack-specific architecture mistakes** — wrong patterns for the project's stack. In-memory state in serverless, sync APIs in RSC, missing root layouts, RLS bypass, race conditions, unhandled promise rejections, ORM N+1, etc. Adapt the lens to the stack you read in `AGENTS.md` / `CLAUDE.md`.

J. **Round structure soundness** — does each round's output enable the next? Are gates evidenceable from THAT round's deliverable, not a downstream one? Can each round be reviewed in isolation?

**[Second pass only]** K. **Resolution of prior findings** — for each finding in `plan-review-01.md`, does the plan fix it? Was a finding dismissed without reasoning? Did a fix introduce a NEW issue?

## Bug classes

1. Internal inconsistency.
2. Plan-vs-repo divergence.
3. Missing prerequisite.
4. Vague non-binary gate.
5. DECISIONS-worthy choice without flag.
6. Convention or architecture mistake.
7. Anything else surprising or risky.

If you discover a pre-existing out-of-scope bug/security gap/tech debt item while reviewing, apply `known-issues-review.md`: do not duplicate existing entries; append/update `KNOWN_ISSUES.md` if allowed, or include a ready-to-paste KI entry in the review report.

## Output format

Findings-first. Do not summarize what works.

For each finding:
- **Class** (1–7).
- **Where** (§ + line region for plan; file:line for repo references).
- **What is wrong** (one sentence).
- **Why it bites** (one sentence).
- **Suggested fix** (one sentence).

End with TWO summary lines:
- `TOTAL FINDINGS: N. By class: 1=a, 2=b, 3=c, 4=d, 5=e, 6=f, 7=g, K=k.`
- `BOTTOM LINE: <SHIP | FIX-THEN-SHIP | RETHINK | BLOCK> + one sentence saying why.`

⚠️ **The canonical blocking predicate decides the round, not class or artifact type.** The coordinator applies [`sdi-mode/references/auto-review-mode.md`](../../sdi-mode/references/auto-review-mode.md) §"Marks and the verdict matrix". A plan being the deliverable does not by itself promote a documentary finding.

**BOTTOM LINE is a proposal:** `SHIP` when no finding meets the canonical blocking predicate; `FIX-THEN-SHIP` for a reachable mechanical defect; `RETHINK` when PO judgment is needed; `BLOCK` for urgent material risk. The coordinator owns the round.

## Saving the review

After writing the findings-first report (above format):

1. Save to `docs/reviews/plan-review-NN.md`.
2. Surface the report to the user in the conversation — don't make them open the file to read it. Lead with: "Saved to `docs/reviews/plan-review-NN.md`. Findings: N. Bottom line: SHIP/FIX-THEN-SHIP/RETHINK/BLOCK. Top issues: [the 2-3 most material]."
3. Wait for user direction — accept findings, revise plan, request second pass.

## Iteration (the loop's later rounds)

The autonomous loop in `SKILL.md` handles iteration: after round 1, the coordinator applies obvious fixes to the plan and dispatches round 2, and so on. On each later round:

1. Obvious-fix findings are applied to the plan **by the coordinator** (the plan is a doc — in scope); non-trivial / decision findings are resolved by the user (or the planner agent) before the next round.
2. Re-run this protocol with the second-pass branch active: also read the prior round's `docs/reviews/plan-review-(NN-1).md` (the second-pass step in "Steps you must perform"), and apply check K (resolution of prior findings).
3. Save each round's output as `docs/reviews/plan-review-NN.md` (`01`, `02`, ...).

Apply the cap and convergence check canonical in [`sdi-mode/references/auto-review-mode.md`](../../sdi-mode/references/auto-review-mode.md) §"Loop cap". The last allowed round without SHIP is a mechanical stop; only the PO authorizes another, with the authorization recorded first.

## Common pitfalls

- **Trusting the plan's claims without verifying.** "We use the existing `useAuth` hook" — Grep for `useAuth` in the repo. If it doesn't exist or has a different shape, that's a finding (class 3).
- **Stopping at internal consistency.** Plans that are internally consistent but disagree with `AGENTS.md` / `CLAUDE.md`, `DECISIONS.md`, or the actual repo are still wrong. Cross-check externally.
- **Treating "passes lint/typecheck" as approval.** A plan can be lint-clean and still wrong. The review is about correctness against the bundle, not syntax.
- **Rubber-stamping because the plan is well-written.** Style ≠ correctness. Polished plans can still have class-3 prerequisite holes or class-5 unflagged DECISIONS.
- **Inventing findings to look thorough.** If everything checks out, output zero findings and SHIP. The discipline is honest verdicts, not productivity theater.
- **Skipping the saved artifact.** The saved file IS the audit trail. Future sessions read it; without it, the review is conversational only and disappears at session end.

## Model diversity

The coordinator dispatches the persistent profile in parallel. Each reviewer gets the same filled self-contained prompt and returns findings plus verdict. Reviewers cannot read this protocol file, so the prompt carries the minimal proportionality and plan-vs-bundle checks. The coordinator deduplicates and reconciles per `SKILL.md`.

A user may also open a fully separate session in another tool and load `sdi-review` there as an independent second coordinator — their choice. But the reviewers a coordinator dispatches always receive the filled adversarial prompt, **never this skill**.
