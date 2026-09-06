# Roles & Orchestration — how SDI executes a plan

This is **the** execution model for `sdi-mode`. Turning an `IMPLEMENTATION_PLAN_*.md` into working, tested code is a **multi-agent** job across three roles:

- **PM / orchestrator** — the main session. Runs the audit, writes briefs, dispatches subagents, reconciles verdicts, assigns each finding's mark, owns the entire paper trail. **Never authors code.** It does run `git` and `grep` — reading the tree and merging non-overlapping slices is not authoring; a conflict needing a choice *about code* goes to an Engineer.
- **Engineer** — a dispatched subagent (always Opus) that implements code and runs the build/tests. **Never touches the paper trail.**
- **Reviewer** — a dispatched read-only subagent that reviews the diff and returns findings with a proposed mark and a verdict. **It edits no file of the repository under review**; writing its own report into `docs/reviews/` is not editing, which is why a read-only Codex sandbox with `--output-last-message` works and an Agent-tool reviewer's text is written down by the PM.

There is no "single agent implements it all" path — this split *is* how the loop runs at every checkpoint. All reviewer mechanics — roster, cap, classification, the mark matrix, convergence, the Codex invocation and the **ask-the-user rule when Codex is unavailable** — live in [`auto-review-mode.md`](auto-review-mode.md), **cited and not restated** here.

## Roles & tool scoping

| Role | Does | Never does | Tools |
|---|---|---|---|
| **PM** (main session) | Runs the CP1 audit; writes the briefs; dispatches **1–3 Engineers** then the **three** reviewers; reconciles verdicts and **assigns marks**; owns the **paper trail**; **proposes** fact-sheet updates; pauses on a decision, the cap or a blocker. | Author or edit code; review code itself; inject orchestration discipline into the fact sheets. | Read, Edit/Write (**docs only**), Glob, Grep, Bash (git/gh/grep/codex), Agent, the stop-and-ask tool, TodoWrite. |
| **Engineer** (dispatched — **always Opus**; 1–3 concurrent) | Implements its slice; runs the checks the round requires; commits the code (commit A); reports SHAs, files, test deltas and deferred decisions. | Edit the paper trail; dispatch subagents; ask the user; "finalize at any cost" — it **stops and reports** on a test failure, a wrong plan, a non-trivial decision, repeated retries, or an off-slice violation. | Read, Edit/Write (**code only**), Glob, Grep, Bash (build/test/git commit), TodoWrite. |
| **Reviewer** (dispatched — three in parallel) | Reviews the combined diff against the plan; returns findings (classes 1–7/K) with a proposed mark and `VERDICT: PASS/FAIL/ESCALATE`. | Edit any file of the repository under review; dispatch subagents; ask the user; assign the final mark. | Read, Glob, Grep, Bash (read-only), plus writing its own report into `docs/reviews/`. |

## Engineer fan-out — PM judgment (1–3 per step)

The PM sizes the fan-out **before** dispatching and states count and partition in each brief. **1 Engineer** when the work is small, when concurrent Engineers would touch overlapping files, or when correctness needs one coherent change; **up to 3** only when the deliverables partition into **non-overlapping** slices and parallelism buys real speed. One Engineer owns each slice.

## The per-checkpoint cycle

Granularity is **per checkpoint**. **CP1 and CP5 are PM-direct**, no Engineer for their own deliverables. **CP2 / CP3 / CP4** run: the PM writes the brief(s), sizing the fan-out → the Engineer(s) implement, commit A and report SHAs, files, test deltas and deferred decisions → the PM confirms green **from that reported evidence** (it does not run the suites) and, if parallel, merges the slices into one diff → the PM dispatches the 3 reviewers and reconciles → it advances, runs a fix cycle, or pauses.

A **round** is one dispatch of the reviewers plus the fix it triggers, **consuming one attempt against the cap** in [`auto-review-mode.md`](auto-review-mode.md) §"Loop cap", under that file's "what counts" rule.

## Reconciliation & convergence

The PM runs the **same dedup + classification** as [`auto-review-mode.md`](auto-review-mode.md) §"The loop" (steps 6–7) over the union of the reviewers' findings, merges verdicts per §"Verdict merging", and decides the attempt by §"Marks and the verdict matrix" — the PM assigns each mark, the reviewer only proposes. Those tables are not duplicated here. The role-specific actions on top:

| Verdict shape | PM action |
|---|---|
| 3/3 PASS (or PASS + only non-load-bearing class-7 advisories) | → next checkpoint; advisories logged, not gated |
| Obvious finding in a **paper-trail artifact** | → PM applies it directly, re-dispatches |
| Obvious finding in **code** | → PM dispatches a **fix-Engineer** cycle, re-dispatches (one round) |
| Convergent blocker (2+ reviewers) **or** a solo **grounded** finding the PM cannot grep-refute | → fix cycle, preserving the rest (**strict-solo gate**; the PM's refutation or confirmation is logged in the round report) |
| Solo class-5, or urgent class-7 | → pause for the user |
| Cap reached without PASS, or convergence trips | → pause for the user (accept-with-debt / replan / override) |

> "Obvious finding" means one that step-7 classification already marked `obvious-fix`: it **fails the attempt and has a mechanical fix**, with its convergence condition holding. These rows are the PM's actions *on top of* that classification, not a replacement.

**No FAIL silently advances**; only genuine class-7 advisories are non-gating. **Model diversity is load-bearing** — the ensemble is not reducible to two reviewers, and the roster with its one sanctioned substitution is in `auto-review-mode.md` §"Reviewer fallback".

The PM acts **per finding**, so an obvious fix is never blocked behind a coexisting decision, and its grep to *refute a solo finding before dispatch* is a **gate check**, not re-verification — that happens on the *next* attempt. **Every PM pause** goes through the host's **structured ask tool** (`AskUserQuestion` under Claude Code), never plain prose (see [`../SKILL.md`](../SKILL.md) §"Pausing for the user"). Only the PM asks the user.

## PM-direct checkpoints & user gates

- **CP1 (Foundation/audit):** PM-direct, no Engineer. **User-gated**: pause after the audit for blockers and open questions.
- **CP5 (Housekeeping):** the PM writes CP5's own deliverables — DECISIONS / KNOWN_ISSUES / memory / WORK_LOG — and **proposes** fact-sheet updates for approval. **No Engineer produces CP5's deliverables; CP5 does have a fix-Engineer** for any `[code]` finding the review raises — the same routing as everywhere else, not an exception to "PM-direct". It then dispatches the **CP5 comprehensive review** ([`auto-review-mode.md`](auto-review-mode.md) §"CP5 comprehensive review"). On PASS it does **not** open the PR.
- **CP-final smoke (part of CP5 closure):** **user-gated** — the PM generates the steps, the **user runs** them and pastes the output, the PM interprets. The PM never runs a suite or a smoke; any rerun is Engineer-provided evidence.
- **PR open:** the PM, via `gh pr create`, only after **both** the review PASSes and the smoke passes.

## Parallel-Engineer logistics

**Single Engineer (the common case):** the PM captures `BASE_SHA` (per [`auto-review-mode.md`](auto-review-mode.md) §"Per-round commit convention") **at round start, before any commit**; the Engineer makes commit A; the PM writes commit B and the review-artifacts commit. A fix cycle follows the same split.

**Parallel Engineers (2–3):** `BASE_SHA` is captured **before** dispatching, each Engineer runs in an **isolated git worktree** off it, and the partition is **strictly non-overlapping**, so reconciliation is normally a conflict-free `git merge` onto the step branch. Their commits are the round's code commits, and one combined `git diff BASE_SHA..HEAD` is the single review packet, so **one** review covers all slices.

**If a real conflict arises**, the PM neither hand-resolves it (authoring code) nor discards the work: it **dispatches a merge-Engineer (Opus)** in a worktree with both branches available, then reviews the result through the ensemble like any other round. Re-partitioning is the last resort.

## Reviewer dispatch — the prompt, never a skill

**Dispatched reviewers receive the filled, self-contained adversarial prompt — never a skill.** Handing a reviewer a review skill is the anti-pattern fixed for `sdi-review` (its "Who loads this skill" guardrail): a subagent that loads a skill tries to *re-coordinate* instead of reviewing. Reviewers also cannot read skill reference files — those live in the install path, not the repo — so **every check must be baked into the prompt**.

Fill the embedded prompt in [`auto-review-mode.md`](auto-review-mode.md) §"Adversarial review prompt template" for a **round/diff** target, or [`sdi-review/references/adversarial-review-prompt-template.md`](../../sdi-review/references/adversarial-review-prompt-template.md) for a **plan or standalone** one. The subagent gets the *filled prompt as its `prompt`*, runs read-only, and returns text. (`round-report-template.md` is a *report* format — never hand it to a reviewer.) Dispatch mechanics live in `auto-review-mode.md`; the PM's per-round work is substituting the placeholders, verifying none survives, and dispatching.

## Relationship to `sdi-review`

Both the PM and the `sdi-review` coordinator apply obvious fixes to planning and review docs autonomously, and both dispatch with the prompt-not-skill rule. The line is **invocation and reach, not doc-edit autonomy**: `sdi-review` is a **user-invoked consultant that never executes code work**, so a code finding becomes a recommendation; the **PM** is the **running orchestrator**, so a code finding routes to a **fix-Engineer cycle**. What is net-new here is the **role split** and **PM-direct CP1/CP5**; the rest is cited from `auto-review-mode.md`, including the **strict-solo policy note** (§"The loop" step 7).

---

## Engineer brief template

The PM fills this and passes it as the Engineer's `prompt` (Agent tool, `subagent_type: general-purpose`, `model: opus`). Genericize every bracketed field; never inject SDI discipline rules — the brief carries the **task**, not the method.

```
You are the Engineer for [ROUND_ID] of a [STACK] implementation. You implement code only.

## Your slice
[SLICE]. [If parallel] You are 1 of [N] Engineers this round; your slice is strictly [FILES/DIRS].
Do NOT touch files outside it — another Engineer owns them.

## Base
[If parallel] Work in the git worktree at [WORKTREE_PATH], based on [BASE_SHA].
[If single] Work on the current branch; the tree is clean at [BASE_SHA].

## Deliverables
[DELIVERABLES] — the concrete files and behaviors this slice must produce.
Plan: [PLAN_PATH] §[PLAN_SECTIONS]. Conventions: AGENTS.md or CLAUDE.md (stack, helpers, test setup).

## Verification (run before reporting)
Run the checks this slice requires — [tests, typecheck, lint, build] — and record the exact command,
result, counts and skips. "Tests pass" without command and count is not enough.

## Commit
Code only, no round report: `round X/CN: <summary>` (or `round X/CN fix N: <what>` for a fix cycle).
Do NOT write or edit any paper-trail file (plan, DECISIONS, KNOWN_ISSUES, memory, round report).

## Report back to the PM (do not ask the user)
The commit SHA(s); files added or modified; test deltas (command, counts, pass/fail, skips); and any
decision you deferred, divergence from the plan, or assumption you made.

## Stop-and-report triggers (do NOT push through these)
A test fails and the fix isn't obvious; the plan is wrong or contradicts the repo; a non-obvious,
decision-worthy choice is forced; you are retrying the same thing repeatedly; or the work would take
you outside your slice. Report the situation — the PM decides.
```

## Reviewer brief template

The Reviewer brief **is the filled adversarial prompt — never a skill**: the PM fills the existing template for the target type, per §"Reviewer dispatch" above, and never authors a new prompt per round.
