---
name: sdi-review
description: Consultative review during SDI implementation. Equips the review coordinator to run an SDI-aware adversarial review — read planning artifacts (PRD, ARCHITECTURE, DECISIONS, KNOWN_ISSUES, plan), dispatch a reviewer ensemble (never have a subagent load this skill — reviewers get the adversarial prompt), run an autonomous fix loop, return findings with verdict. USE when the user brings implementation work back for a second pair of eyes — "review this plan", "round X delivered, look at this", "agent is asking A or B", "found this bug, what now", "is this decision risky?". DO NOT USE for product scoping (use mvp-architect), planning the next work item (use sdi-next-plan), or executing implementation (use sdi-mode).
---

# sdi-review

Second pair of eyes during SDI implementation. The coding agent has produced something — a plan, a round report, a fork decision, a bug — and the user wants it reviewed.

This skill is the **playbook for the review coordinator** — the main session the user invokes. It reads the planning bundle and drives the review: loop, dedup, fix decisions and verdict. It dispatches the reviewers in the work-item profile rather than choosing a vendor, model or roster itself.

> **Who loads this skill — read this first.**
> Only the **coordinator** (the agent the user invoked) loads `sdi-review`. When the coordinator dispatches reviewers, it hands each one the **self-contained adversarial prompt** from [`references/adversarial-review-prompt-template.md`](references/adversarial-review-prompt-template.md) — **never this skill**. A subagent that loads `sdi-review` would try to *re-coordinate* (dispatch its own reviewers) instead of reviewing, causing recursion and wasted context. The skill is the conductor's score; a dispatched reviewer gets the sheet music (the filled prompt), reads its target, and returns findings + verdict.
>
> This mirrors `sdi-mode`'s auto-review, where the PM/orchestrator dispatches reviewers with a prompt and never tells them to load a skill.

## The review loop (autonomous, capped)

Read the work-item operating profile in plan §0. It persists across the item. If
the function is pending, ask the PO once before first dispatch and persist the
answer. If this is an ad-hoc review without a plan, ask once and record a
session-local profile in the first artifact. A rate limit, invocation failure or
unusable output returns to the PO for pause or explicit replacement; never fall
back automatically. Cross-vendor diversity is recommended, not a gate.

The coordinator runs this loop for artifact reviews, same shape as `sdi-mode`'s auto-review (see [`sdi-mode/references/auto-review-mode.md`](../sdi-mode/references/auto-review-mode.md) for the full mechanics it reuses). **Mode 1 (plan review) runs it in full** — obvious fixes land in the plan doc and it re-dispatches until SHIP or the cap. **Mode 2 (round/code review) runs one ensemble pass (steps 1-2) and does NOT auto-loop** — the coordinator can't auto-apply code fixes (step 3), so there's nothing for it to re-dispatch on; it presents findings + recommendations and escalates. (Modes 3-4 don't use this loop at all — they're single advisory passes.)

1. **Dispatch the profiled reviewers in parallel**, each in a fresh read-only non-persistent context with the same filled adversarial prompt. Validate exit zero, non-empty final output and evidence of reading/grepping the target. Any failure stops for the PO; there is no automatic substitution.
2. **Merge verdicts, dedup findings, classify per finding** — `obvious-fix` / `needs-decision` / `judgment-required`, same rules as `auto-review-mode.md`.
   Then assign each finding its final mark and read the round from [`sdi-mode/references/auto-review-mode.md`](../sdi-mode/references/auto-review-mode.md) §"Marks and the verdict matrix". Instrumental or documentary findings block only under that section's binary predicate; the fact that a plan is the deliverable does not promote prose by itself. **The coordinator classifies, never the reviewer.**
3. **Act per finding** (this is the autonomy):
   - **Obvious/trivial fix the coordinator may apply** — *only* a planning/review artifact: the plan under review, `docs/reviews/`, or `KNOWN_ISSUES.md`. Re-verify via Grep/Read, apply it, then **dispatch the next round**.
   - **Obvious fix to source code** — **never apply it.** The coordinator reviews; it does not implement. Present it with a recommendation for the user or `sdi-mode` to apply. (Reviewer/implementer separation is deliberate.)
   - **Non-trivial or decision finding** (class-5 DECISIONS-worthy, scope/architecture conflict, divergent reviewers, anything needing user judgment) — present **options + a recommendation** and stop for the user.
4. **Continue vs stop:** if a round produced only coordinator-appliable obvious fixes and nothing to escalate → auto-continue to the next round. If anything needs the user or `sdi-mode` → stop and present (the applied fixes are kept; the loop resumes after the user or `sdi-mode` responds).
5. **Apply the cap and convergence rule** canonical in [`sdi-mode/references/auto-review-mode.md`](../sdi-mode/references/auto-review-mode.md) §"Loop cap". At the last allowed round without SHIP, stop. Only the PO authorizes another round, with that authorization recorded first.

Net effect:
- A **plan review** iterates autonomously — the ensemble hammers the plan, obvious fixes land in the plan doc, decisions surface to you — until SHIP or the cap.
- A **round (code) review** dispatches the ensemble for a strong read but does **not** auto-apply code: it presents findings + recommendations and escalates, because `sdi-mode` (its Engineers, dispatched by the PM), not the reviewer, owns the code.

The user can opt out (run a single pass, review manually) at any time — say so and the coordinator does one round and stops.

## Why a single skill instead of multiple

Different review entry points (plan, round, fork, bug) share the same SDI grounding: read PRD/ARCHITECTURE/DECISIONS/KNOWN_ISSUES/PLAN/AGENTS, apply the same 7 bug classes, ground every finding in evidence. The mode-specific differences (what artifacts to focus on, what to lead with) are small enough to live in one skill with mode references.

## Entry modes

### Mode 1 — Plan review

Triggered when the user asks for review of an implementation plan document:

- "review this plan" / "review docs/IMPLEMENTATION_PLAN_*.md"
- "the agent proposed this plan, does it look right?"
- "any issues with this plan?"
- "second pair of eyes on the plan?"

Action: run the proportional loop above using `references/plan-review-protocol.md`. Apply only fixes that meet the canonical blocking predicate; do not open another round for cosmetic prose or optional instrumentation. Write each round's review to `docs/reviews/plan-review-NN.md`.

### Mode 2 — Round report review

Triggered when the user brings a completed implementation round for review:

- "agent just delivered round X, review?"
- "round B done, what do you think?"
- "anything wrong with this round?"

Action: dispatch the ensemble against the round (report end-to-end + diff + relevant plan §s), using `references/round-report-review-patterns.md` §"Round X review" as the check framework. Return findings first, graded blocker / non-blocker / nice-to-have and each carrying its mark, ending with `BOTTOM LINE: SHIP | FIX-THEN-SHIP | RETHINK | BLOCK` read off `auto-review-mode.md` §"Marks and the verdict matrix" — the same matrix as Mode 1, never re-derived here. **Do not auto-apply code fixes** — present obvious code fixes as recommendations for `sdi-mode` to apply, and decisions as options + a recommendation. (Code findings during implementation are normally handled by `sdi-mode`'s own auto-review; an `sdi-review` round pass is an extra, independent read.)

### Mode 3 — Fork decision

Triggered when the agent surfaces a fork and asks the user to pick:

- "agent is asking whether to do A or B — which?"
- "the implementer proposed two approaches"

Action (advisory — a judgment call, not an iterative fix loop): read both options, pick based on planning context (PRD/ARCHITECTURE/DECISIONS), explain. Don't say "I trust your judgment" — the user came here precisely because they want a second opinion. The coordinator may consult one ensemble pass for a second read, but does not loop. See `references/round-report-review-patterns.md` §"A or B fork".

### Mode 4 — Bug or divergence found

Triggered mid-round when the agent (or user) finds something that breaks an assumption:

- "agent found this bug in the plan"
- "agent says X doesn't match the repo"
- "the implementer caught a divergence"

Action (advisory — single pass, not a fix loop): acknowledge fairly (if the plan was wrong, own it), decide fix direction (plan update? DECISIONS entry? revision note?), ensure paper trail. A plan-level fix may be applied to the plan doc; a code-level fix is `sdi-mode`'s. See `references/round-report-review-patterns.md` §"Bug found".

## How to drive a review

Regardless of mode, the **coordinator** owns these steps — running the ensemble loop above for Modes 1-2, or a single advisory pass for Modes 3-4. The dispatched reviewers apply the checks against their target; the coordinator reconciles, decides, and records:

1. **Read the SDI bundle** — `AGENTS.md`, `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/KNOWN_ISSUES.md`, `docs/DECISIONS.md`, `docs/PROJECT_STRUCTURE.md`, the relevant plan, the relevant round report (if any). Mode 1 reads the plan deeply; Mode 2 reads the round report deeply; all modes need the bundle context.
2. **Apply the active checks** in the mode reference. Cross-file consistency, plan-vs-repo grounding, plan-vs-DECISIONS, vague gates, missing prerequisites, stack-specific architecture mistakes, DECISIONS-worthy choices not flagged.
3. **Return findings first** — class, location, what is wrong, why it bites, suggested fix.
4. **End with the bottom line** — `SHIP` / `FIX-THEN-SHIP` / `RETHINK` / `BLOCK`, the form the dispatched prompt returns, per the mode's rules.
5. **Save the artifact** to `docs/reviews/` (Mode 1: `plan-review-NN.md`; Mode 2: discussion with the user, optional `docs/reviews/round-XN-review.md` if persistent record matters). The repo gets the audit trail; the user reads the live response.

The coordinator **never edits source code** — that's `sdi-mode`'s job (its Engineers, dispatched by the PM). It MAY edit planning/review artifacts when applying an obvious fix during a plan review: the plan under review, files under `docs/reviews/`, and (when the review uncovers an out-of-scope known issue with concrete evidence) `docs/KNOWN_ISSUES.md`. For code findings it returns recommendations, not edits; otherwise include a ready-to-paste KI entry in the report.

## Tone in review

- **Direct.** Have a position, defend it, revise it.
- **Specific over generic.** "Looks good" helps nobody — point at file:line.
- **Don't rubber-stamp.** Tests passing doesn't mean design is right.
- **Don't defend prior planner output out of ego.** If the plan was wrong and the agent caught it, good. Update and move on.
- **Don't improvise architecture mid-round.** If a real architectural issue surfaces, pause, discuss, decide. Don't fold it silently into the current round.

## Pausing for the user — use the structured ask tool

You are the review coordinator (the session the user invoked), and the only role that talks to the user. Whenever you need them — a fork to decide (Mode 3), a `needs-decision` or `judgment-required` finding, a scope question (pulling planning back open), a genuine doubt, or you've finished the review and are handing back — surface it through the host's **structured question tool** (`AskUserQuestion` under Claude Code), not as plain prose. Use it every time you stop and wait, so the pause is explicit, actionable, and reliably delivered — a question buried in text is easy to miss, and going idle silently leaves the user unaware you need them. Dispatched reviewers never ask the user; they return findings to you. (On a host without a structured ask tool, end with an explicit, clearly-labelled question.)

## When to use vs not

**Use this skill when:**
- Implementation is in flight and the user wants a review of an artifact (plan, round, decision).
- The project already has an SDI bundle (PRD, ARCHITECTURE, DECISIONS, etc.) — review needs that context.

**Don't use this skill when:**
- The user is scoping a new product from scratch — that's `mvp-architect`.
- The current work item is closing and the user wants the *next* plan generated — that's `sdi-next-plan`.
- The user wants implementation done — that's `sdi-mode`.
- The user wants converting an existing repo to SDI — that's `convert-to-sdi`.

## Combining with other models

**The coordinator dispatches the persistent review profile itself**, handing every reviewer the same filled prompt and reconciling the outputs. The framework recommends independent cross-vendor perspectives but does not require or label a particular roster.

A user *may* still open a fully separate session in another tool and load `sdi-review` there to act as an independent second coordinator — that's a deliberate user choice. But within one coordination run, **dispatched reviewers receive the prompt, never the skill** (see the guardrail at the top).

For mid-round implementation reviews scheduled when checkpoint risk or contract justifies independent review, see [`sdi-mode/references/auto-review-mode.md`](../sdi-mode/references/auto-review-mode.md) and [`sdi-mode/references/roles-and-orchestration.md`](../sdi-mode/references/roles-and-orchestration.md) — same loop and ensemble, but triggered by the `sdi-mode` **PM/orchestrator** rather than user-invoked through this skill. There too, the PM hands each dispatched reviewer the **filled adversarial prompt, never a skill** — the same prompt-not-skill rule as the guardrail at the top of this file.

## When to pull planning back open

Occasionally mid-implementation, something the user learns forces a scope change. Signals:

- A customer has changed a key requirement.
- A technical surprise invalidates a load-bearing assumption.
- A feature turns out to be much bigger or smaller than estimated.

In these cases, don't just patch the current phase — step back to scope. Ask: does ROADMAP need to change? PRD? ARCHITECTURE? A short scope reopening is cheap; a scope reopening that wasn't done and causes cascading rework later is expensive. See `round-report-review-patterns.md` §"When to pull planning back open".

## References

- `references/plan-review-protocol.md` — plan review framework (Mode 1). Steps to read, things to actively check, bug classes, output format.
- `references/round-report-review-patterns.md` — patterns for Modes 2, 3, 4. Tone, what NOT to do, when to pull planning back open.
- `references/known-issues-review.md` — how reviews should use or update `KNOWN_ISSUES.md` without duplicating issues.
- `references/adversarial-review-prompt-template.md` — the self-contained adversarial prompt handed to each profiled reviewer; also usable ad-hoc. Vendor-specific CLI recipes live in `sdi-mode/references/roles-and-orchestration.md`. Reviewers get the prompt, never the skill.
