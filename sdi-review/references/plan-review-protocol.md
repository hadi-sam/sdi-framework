# Plan review protocol

Framework for reviewing an SDI implementation plan — the **check framework** the coordinator and the reviewers it dispatches apply against the plan (what to read, what to verify, the bug classes, the output format). The coordinator runs the autonomous loop from `SKILL.md` (dispatch Opus + Sonnet + Codex with the adversarial prompt, dedup, apply obvious fixes to the plan doc, re-dispatch up to 5 rounds, escalate decisions). A dispatched reviewer applies these checks against the plan and returns findings; **a reviewer never loads `sdi-review`** — it gets the filled adversarial prompt.

This file is loaded by `sdi-review` for **Mode 1: plan review**. Other modes use `round-report-review-patterns.md`.

## Why this exists

A plan written by the same agent that scoped it tends to overstate readiness — the planner is not adversarial but wants to ship. An external review applies adversarial pressure: cross-checks every concrete claim against the repo, every choice against `DECISIONS.md`, every known issue against `KNOWN_ISSUES.md`, and every gate against evidenceability. The coordinator combines perspectives by dispatching the ensemble (Opus + Sonnet + Codex; Haiku if Codex fails) — partially-disjoint blind spots, so the union catches more than any one model alone.

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

G. **Vague or non-binary gates** — gates a reviewer can't mark ✓/✗ from evidence. "Verify the integration tests pass" is too vague; "Integration test count matches plan §8 list and all pass per the runner output below" is binary.

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
- `TOTAL FINDINGS: N. By class: 1=a, 2=b, 3=c, 4=d, 5=e, 6=f, 7=g.`
- `VERDICT: PASS / FAIL / ESCALATE.`

**VERDICT rules:** PASS only if zero findings of class 1–6. FAIL if there is at least one mechanically fixable finding in class 1–4 or 6. ESCALATE if there is at least one class-5 finding, a class-7 urgent risk, a scope/architecture conflict, or anything requiring user judgment. Non-urgent class 7 alone can remain PASS if it is only an advisory note.

## Saving the review

After writing the findings-first report (above format):

1. Save to `docs/reviews/plan-review-NN.md`.
2. Surface the report to the user in the conversation — don't make them open the file to read it. Lead with: "Saved to `docs/reviews/plan-review-NN.md`. Findings: N. Verdict: PASS/FAIL/ESCALATE. Top issues: [the 2-3 most material]."
3. Wait for user direction — accept findings, revise plan, request second pass.

## Iteration (the loop's later rounds)

The autonomous loop in `SKILL.md` handles iteration: after round 1, the coordinator applies obvious fixes to the plan and dispatches round 2, and so on. On each later round:

1. Obvious-fix findings are applied to the plan **by the coordinator** (the plan is a doc — in scope); non-trivial / decision findings are resolved by the user (or the planner agent) before the next round.
2. Re-run this protocol with the second-pass branch active: also read the prior round's `docs/reviews/plan-review-(NN-1).md` (the second-pass step in "Steps you must perform"), and apply check K (resolution of prior findings).
3. Save each round's output as `docs/reviews/plan-review-NN.md` (`01`, `02`, ...).

Cap at **5 rounds** + the convergence check (per `SKILL.md` and `auto-review-mode.md`). If the plan still has class 1-6 issues at the cap, the structural problem isn't a review problem — escalate to the user.

## Common pitfalls

- **Trusting the plan's claims without verifying.** "We use the existing `useAuth` hook" — Grep for `useAuth` in the repo. If it doesn't exist or has a different shape, that's a finding (class 3).
- **Stopping at internal consistency.** Plans that are internally consistent but disagree with `AGENTS.md` / `CLAUDE.md`, `DECISIONS.md`, or the actual repo are still wrong. Cross-check externally.
- **Treating "passes lint/typecheck" as approval.** A plan can be lint-clean and still wrong. The review is about correctness against the bundle, not syntax.
- **Rubber-stamping because the plan is well-written.** Style ≠ correctness. Polished plans can still have class-3 prerequisite holes or class-5 unflagged DECISIONS.
- **Inventing findings to look thorough.** If everything checks out, output zero findings and PASS. The discipline is honest verdicts, not productivity theater.
- **Skipping the saved artifact.** The saved file IS the audit trail. Future sessions read it; without it, the review is conversational only and disappears at session end.

## Model diversity

The coordinator dispatches Opus + Sonnet + Codex (Haiku if Codex fails) every round — each reviewer gets the filled adversarial prompt and runs it against the plan, returning findings + verdict. **Dispatched reviewers can't read this protocol file** (it lives in the skill, not the project repo), so the adversarial prompt is **self-contained**: its general checks (A–H, K) plus the SDI plan-vs-bundle check (item I — plan-vs-DECISIONS, plan-vs-KNOWN_ISSUES, PRD/ARCHITECTURE precedence, round-structure soundness) cover the checks listed above. This protocol is the **coordinator's** reference — for interpreting findings, deduping, and second-pass resolution (check K). What differs between reviewers is their blind spots; the union catches more than any single model. The coordinator dedups and reconciles per `SKILL.md`.

A user may also open a fully separate session in another tool and load `sdi-review` there as an independent second coordinator — their choice. But the reviewers a coordinator dispatches always receive the filled adversarial prompt, **never this skill**.
