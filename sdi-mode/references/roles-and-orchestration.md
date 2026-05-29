# Roles & Orchestration — how SDI executes a plan

This is **the** execution model for `sdi-mode`. Turning an `IMPLEMENTATION_PLAN_*.md` into working, tested code is a **multi-agent** job split across three roles:

- **PM / orchestrator** — the main session. Runs the audit, writes briefs, dispatches subagents, reconciles verdicts, owns the entire paper trail. **Never writes or reviews code.**
- **Engineer** — a dispatched subagent (always Opus) that implements code and runs the build/tests. **Never touches the paper trail.**
- **Reviewer** — a dispatched read-only subagent that adversarially reviews the diff and returns findings + a verdict. **It edits no repo files**; the PM persists each reviewer's output to `docs/reviews/` (Agent-tool reviewers return text the PM writes; the Codex CLI writes its own output file via `--output-last-message`).

There is no separate "single agent implements it all" path — this role split *is* how the loop runs, at every checkpoint. The SDI discipline (audit-first, checkpoint gates, DECISIONS/KNOWN_ISSUES/memory/WORK_LOG, document precedence) is unchanged; what this doc makes explicit is **who performs each part**. All reviewer mechanics — the ensemble roster, the loop cap, the Decision Bundle classification, the convergence check, the Codex two-step invocation, the Haiku-for-Codex substitution — live in [`auto-review-mode.md`](auto-review-mode.md) and are **cited, not restated** here.

## Roles & tool scoping

| Role | Does | Never does | Tools |
|---|---|---|---|
| **PM / orchestrator** (main session) | Runs the CP1 audit directly (read/grep/analyze); writes Engineer & Reviewer briefs; sizes and dispatches **1–3 Engineers** per step (§"Engineer fan-out"), then the **three** parallel reviewers; reconciles verdicts; decides convergence; owns the **entire paper trail** (plan, DECISIONS, KNOWN_ISSUES, memory, WORK_LOG); **proposes** `AGENTS.md`/`CLAUDE.md` fact updates for user approval; pauses for the user on non-trivial decisions, loop-cap, or blocker. | Implement or edit code (any source/test/migration file); review code itself; inject role/orchestration discipline into the fact sheets. | Read, Edit/Write (**docs only**; fact-sheet updates are *proposed*, not free edits), Glob, Grep, Bash (git/gh/grep/codex), Agent, the host's stop-and-ask mechanism (`AskUserQuestion` under Claude Code), TodoWrite. |
| **Engineer** (dispatched subagent — **always Opus**; 1–3 concurrent) | Implements its slice of the step's deliverables; runs the build/tests/typecheck/lint required by the round; commits the code (commit A); reports SHAs + files + test deltas + any deferred decisions/divergences back to the PM. | Edit the paper trail; dispatch other subagents; ask the user (reports to the PM instead); "finalize at any cost" — it must **stop and report** on test failure, a wrong-plan discovery, a non-trivial decision, repeated internal retries, or an off-path/scope violation. | Read, Edit/Write (**code only**), Glob, Grep, Bash (build/test/git commit), TodoWrite. |
| **Reviewer** (dispatched subagent — three in parallel) | Adversarially reviews the step's combined diff against the plan; returns findings (bug classes 1–7/K) + `VERDICT: PASS/FAIL/ESCALATE` as text (the PM persists Agent-tool output to `docs/reviews/`; the Codex CLI writes its own output file). | Edit any repo file (strictly read-only); dispatch subagents; ask the user. | Read, Glob, Grep, Bash (read-only: `git diff`/`git log`, grep). |

The roles realize the reviewer/implementer separation that `sdi-review` preserves: the agent that writes code never grades its own work, and the agent that orchestrates never writes the code it ships.

## Engineer fan-out — PM judgment (1–3 per step)

The PM sizes the Engineer fan-out per checkpoint **before** dispatching, and states the chosen count + partition in each brief:

- **1 Engineer** when the work is small, when concurrent Engineers would touch overlapping files (conflict risk), or when correctness depends on a single coherent change.
- **Up to 3 Engineers in parallel** only when the deliverables **partition cleanly into non-overlapping slices** and parallelism buys real speed **without** quality loss or merge conflict (e.g. independent modules, or backend + frontend + tests as separate surfaces).

**One Engineer owns each slice; slices don't overlap.** See §"Parallel-Engineer logistics" for the worktree + merge mechanics.

## The per-checkpoint cycle

Granularity is **per checkpoint** — each `§11` checkpoint of the plan is one implementation step.

- **CP1 (Foundation/audit)** and **CP5 (Housekeeping)** are **PM-direct** — no Engineers (see §"PM-direct checkpoints").
- **CP2 / CP3 / CP4** are **Engineer(s) + review** cycles:

  1. **PM writes the brief(s)** — sizes the fan-out, partitions the work, fills each Engineer brief (§"Engineer brief template").
  2. **Engineer(s) implement + commit + report** — each produces its code commit (commit A) and reports SHAs, files, test deltas, and any deferred decisions.
  3. **PM verifies green and reconciles** — confirms the build/tests are green **from the Engineer's reported evidence** (it does not run the suites itself); if parallel, merges the slices into one diff (§"Parallel-Engineer logistics").
  4. **PM dispatches the 3 reviewers in parallel** on the combined diff, then reconciles their verdicts.
  5. **PM decides:** advance, run a fix cycle, or pause for the user.

A **round** is one dispatch of the three reviewers plus the fix it triggers (a fix-Engineer dispatch for a code fix, or a PM edit for a paper-trail fix). A round **consumes one attempt against the loop cap** defined in [`auto-review-mode.md`](auto-review-mode.md) §"Loop cap", under that file's existing **"what counts vs doesn't count"** rule (the (a)/(b) conditions) — unchanged, and deliberately **not** reproduced here. See that section for the exact conditions.

## Reconciliation & convergence

The PM runs the **same dedup + classification** as [`auto-review-mode.md`](auto-review-mode.md) §"The loop" (steps 7–8) over the union of the three reviewers' findings, then merges verdicts per [`auto-review-mode.md`](auto-review-mode.md) §"Verdict merging". Do not duplicate those tables here — they are authoritative there. The role-specific decisions on top of that machinery:

| Verdict shape | PM action |
|---|---|
| 3/3 PASS (or PASS + only non-load-bearing class-7 advisories) | → next checkpoint (advisories logged, not gated) |
| Obvious finding (class 1–4 / 6 / K) in a **paper-trail artifact** | → PM applies the fix directly, re-dispatches |
| Obvious finding (class 1–4 / 6 / K) in **code** | → PM dispatches a **fix-Engineer** cycle, re-dispatches (counts as one round) |
| Convergent blocker (2+ reviewers) **or** a solo **grounded** class 2–4/6/K finding the PM cannot grep-refute | → fix cycle, preserving the rest (**strict-solo gate** — encoded in [`auto-review-mode.md`](auto-review-mode.md) §"The loop" step 8; the PM's grep refutation/confirmation is logged in the round report) |
| Solo class-5 (deliberate decision) or urgent class-7 | → pause for the user |
| Loop cap reached without PASS, or the convergence check trips | → pause for the user (accept-with-debt / replan / manual override) |

> In rows 2–3, "obvious finding" means a finding the step-8 classification already marked `obvious-fix` — i.e. its convergence condition holds (2+ reviewers converge, **or** a surviving single reviewer in degraded mode, **or** a solo grounded class 2–4/6/K the PM can't grep-refute). A **solo, unconfirmed class-1** finding is *not* `obvious-fix`; it stays `needs-decision` (class-1 is outside the strict-solo gate's 2–4/6/K range). The full classification — including the other `obvious-fix` conditions (a specific fix is cited; it touches only the round's diff) — is in [`auto-review-mode.md`](auto-review-mode.md) §"The loop" step 8; these rows are the PM's actions *on top of* it, not a replacement for it.

**No FAIL silently advances:** any class 1–6/K finding is acted on (applied or fix-cycled), matching [`auto-review-mode.md`](auto-review-mode.md) §"Verdict merging" (any FAIL or ESCALATE blocks PASS). Only genuine class-7 advisories are non-gating.

**Model diversity is load-bearing.** The ensemble is not reducible to two reviewers — in production a third, model-diverse reviewer caught a cross-tenant coupling bug the other two PASSed. The roster and its single sanctioned substitution are defined in [`auto-review-mode.md`](auto-review-mode.md) §"Reviewer fallback" — reuse them, don't redefine them here.

## Autonomy mapping (per-finding behavior)

After dedup + classification, the PM acts **per finding** — obvious fixes are never blocked behind a coexisting decision:

- **Obvious/trivial fix in a paper-trail artifact** (plan, `docs/reviews/`, DECISIONS, KNOWN_ISSUES, memory) → the PM **applies it directly** (the PM owns docs), then continues.
- **Obvious/trivial fix in code** → the PM **does not edit code**; it **auto-dispatches a fix-Engineer (Opus) cycle** with the findings — the autonomous path, no user wait. The PM's own grep to *refute a solo finding before dispatch* (strict-solo gate) is a **gate check**, not re-verification; re-verification of the fix itself happens on the *next* reviewer round (the ensemble re-checks the fix on the new diff), not by an inline grep from the PM.
- **Non-trivial / decision finding** (class-5, scope/architecture, divergent reviewers, anything needing user judgment) → the PM **presents options + a recommendation and pauses**.

This is the same per-finding Decision Bundle flow as `auto-review-mode.md`, with the one role difference: a code fix routes to a fix-Engineer instead of an inline edit.

## PM-direct checkpoints & user gates

- **CP1 (Foundation/audit):** the PM does it directly — read/grep/analyze, no Engineer. **User-gated** — pause after the audit for the user to resolve blockers and answer open questions.
- **CP5 (Housekeeping):** **PM-only** doc work — the PM drafts and commits DECISIONS / KNOWN_ISSUES / memory / WORK_LOG and **proposes** `AGENTS.md`/`CLAUDE.md` fact updates for approval (committing once approved; no free edits, no Engineer for CP5 itself). The PM then dispatches the **CP5 comprehensive review** — reuse [`auto-review-mode.md`](auto-review-mode.md) §"CP5 comprehensive review" for its packet shape and loop (do not restate). On PASS it does **not** open the PR — CP5 closure still has the live-smoke gate below. An obvious *code* fix surfaced at CP5 routes to a fix-Engineer cycle like any other.
- **CP-final smoke (part of CP5 closure):** **user-gated** — the PM generates the smoke steps (a query, a `curl`, a UI walkthrough — whatever the plan's acceptance criteria call for); the **user runs** them and pastes the output; the PM interprets. The PM never runs the suite or the smoke itself — any suite rerun is Engineer-provided evidence.
- **PR open:** the PM via `gh pr create`, only after **both** the CP5 comprehensive review PASSes **and** the smoke passes.

## Parallel-Engineer logistics

**Single-Engineer (the common case):** the PM captures `BASE_SHA` (per [`auto-review-mode.md`](auto-review-mode.md) §"Per-round commit convention") **at round start, before any commit**; the Engineer creates commit A (code); the PM writes commit B (report referencing A's SHA) + the review-artifacts commit. A fix-Engineer cycle follows the same split (`fix N` code by the Engineer, `fix N report` by the PM).

**Parallel Engineers (2–3):**
- The PM captures `BASE_SHA` **before** dispatching.
- Each Engineer runs in an **isolated git worktree** off `BASE_SHA`, so concurrent edits don't race on a shared tree.
- The partition is **strictly non-overlapping** (no two Engineers touch the same file), so the PM's reconciliation is normally a **conflict-free `git merge`** of each Engineer's commit(s) onto the step branch — a mechanical command that authors no code content (the boundary is that the PM never *authors/edits* code, not that it never runs git).
- The Engineers' commits land as the round's `round X/CN` code commits — no PM-authored code commit; the PM then computes one combined `git diff BASE_SHA..HEAD` as the single review packet, and **one combined review** runs over all slices.

**If a real conflict arises** (the partition turned out imperfect — two Engineers touched the same region), the PM does **not** hand-resolve it (that would be authoring code) and does **not** discard the work. It **dispatches a merge-Engineer (Opus)** — in a worktree with both Engineers' branches available so it can see both sides — to integrate the slices and resolve the conflict, then reviews the result via the ensemble like any other round (the merge-Engineer's commit lands as a `round X/CN` code commit; work preserved, boundary intact). Re-partitioning or dropping to a single Engineer is the last resort, only if integration isn't sensible.

## Reviewer dispatch — the prompt, never a skill

The PM holds the review knowledge; **dispatched reviewers receive the filled, self-contained adversarial prompt — never a skill.** Telling a reviewer to load a review skill is the exact anti-pattern fixed for `sdi-review` (see the **"Who loads this skill"** guardrail at the top of [`sdi-review/SKILL.md`](../../sdi-review/SKILL.md)): a subagent that loads a skill tries to *re-coordinate* (dispatch its own reviewers) instead of reviewing. Reviewers also can't read skill reference files at all — those live in the install path, not the project repo — so **every check must be baked into the prompt**.

- For **round/diff targets** (CP2/3/4 rounds, the CP5 comprehensive review): fill the embedded prompt in [`auto-review-mode.md`](auto-review-mode.md) §"Adversarial review prompt template" — its placeholders are `[ROUND_ID]`, `[STACK]`, `[BASE_SHA]`, `[ROUND_REPORT_PATH]`, `[PLAN_PATH]`, `[PLAN_SECTIONS]`, `[PRIOR_REVIEW_FINDINGS]`.
- For **plan/standalone targets**: fill [`sdi-review/references/adversarial-review-prompt-template.md`](../../sdi-review/references/adversarial-review-prompt-template.md).

In both cases the dispatched subagent gets the *filled prompt as its `prompt`*, runs read-only, and returns its review as text. (`round-report-template.md` is a *report* format, not a reviewer prompt — don't hand it to a reviewer.)

## Relationship to `sdi-review`

Both the PM and the `sdi-review` coordinator apply obvious fixes to planning/review docs autonomously, and both dispatch reviewers with the prompt-not-skill rule. The clean line between them is **invocation + reach, not doc-edit autonomy**:

- **`sdi-review`** is a **user-invoked review consultant that never executes code work** — a code finding becomes a recommendation for the user or the executing `sdi-mode` session.
- **The PM** is the **running execution orchestrator** — a code finding routes to a **fix-Engineer cycle**.

`sdi-review` is the PM's review playbook by reference; this doc does not duplicate it.

## Reuse contract (what this doc must not restate)

To keep one authoritative copy, this doc **cites, never copies**: the verdict-merge table, the Decision Bundle classification list, the loop cap + convergence algorithm, the CP5 packet rules, the Codex two-step invocation, and the Haiku-for-Codex swap — each lives in `auto-review-mode.md`. The only net-new mechanics defined here are the **role split** (who commits, fix-Engineer routing, parallel-Engineer worktrees, tool scoping) and **PM-direct CP1/CP5**. The **strict-solo-blocker policy note** that this model relies on is recorded once, as a `DECISIONS.md`-style note, in [`auto-review-mode.md`](auto-review-mode.md) §"The loop" step 8.

---

## Engineer brief template

The PM fills this and passes it as the dispatched Engineer's `prompt` (Anthropic Agent tool, `subagent_type: general-purpose`, `model: opus`). Genericize every bracketed field; never inject SDI discipline rules — the brief carries the **task**, not the method.

```
You are the Engineer for [ROUND_ID] of a [STACK] implementation. You implement code only.

## Your slice
[SLICE] — e.g. "the validation + mapping pure functions in [module path] and their unit tests".
[If parallel] You are 1 of [N] Engineers this round. Your slice is strictly: [FILES/DIRS you own].
Do NOT touch files outside your slice — another Engineer owns them.

## Base
[If parallel] Work in the git worktree at [WORKTREE_PATH], based on [BASE_SHA].
[If single] Work on the current branch; the tree is clean at [BASE_SHA].

## Deliverables
[DELIVERABLES] — the concrete files/behaviors this slice must produce.
Plan reference: [PLAN_PATH] §[PLAN_SECTIONS] (read these for what the slice must satisfy).
Conventions: read AGENTS.md or CLAUDE.md for stack, helper names, and test setup.

## Verification (run before reporting)
Run the checks this slice requires — [unit/integration tests, typecheck, lint, build] —
and record the exact command, result, counts, and skips. "Tests pass" without command+count is not enough.

## Commit
Commit code only (no round report) as: `round X/CN: <summary>` (or `round X/CN fix N: <what>` for a fix cycle).
Do NOT write or edit any paper-trail file (plan, DECISIONS, KNOWN_ISSUES, memory, round report).

## Report back to the PM (do not ask the user)
- The commit SHA(s) you created.
- Files added/modified.
- Test deltas (command, counts, pass/fail, skips).
- Any decision you had to defer, divergence from the plan, or assumption you made.

## Stop-and-report triggers (do NOT push through these)
Stop and report instead of finalizing if: a test fails and the fix isn't obvious; the plan is wrong
or contradicts the repo; a non-obvious/DECISIONS-worthy choice is forced; you find yourself retrying
the same thing repeatedly; or the work would take you outside your slice. Report the situation — the PM decides.
```

## Reviewer brief template

The Reviewer brief **is the filled adversarial prompt — never a skill.** The PM does not author a new prompt per round; it fills the existing template (placeholders above, in §"Reviewer dispatch"):

- **Round/diff target** → fill [`auto-review-mode.md`](auto-review-mode.md) §"Adversarial review prompt template".
- **Plan/standalone target** → fill [`sdi-review/references/adversarial-review-prompt-template.md`](../../sdi-review/references/adversarial-review-prompt-template.md).

Dispatch mechanics (parallel Opus + Sonnet via the Agent tool, Codex via the two-step `codex exec` block, Haiku substituting when Codex is down, the per-attempt output files, the timeout policy) are all defined in [`auto-review-mode.md`](auto-review-mode.md) — reuse them. The PM's only per-round work is **substituting the placeholders with concrete values** and dispatching; it must verify no `[PLACEHOLDER]` token survives before sending, because reviewers do not expand placeholders.
