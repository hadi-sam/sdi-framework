---
name: sdi-review
description: Consultative review during SDI implementation. Equips the loaded agent with SDI-aware review framework — read planning artifacts (PRD, ARCHITECTURE, DECISIONS, KNOWN_ISSUES, plan), apply adversarial checks, return findings with verdict. USE when the user brings implementation work back for a second pair of eyes — "review this plan", "round X delivered, look at this", "agent is asking A or B", "found this bug, what now", "is this decision risky?". DO NOT USE for product scoping (use mvp-architect), planning the next work item (use sdi-next-plan), or executing implementation (use sdi-mode).
---

# sdi-review

Second pair of eyes during SDI implementation. The coding agent has produced something — a plan, a round report, a fork decision, a bug — and the user wants it reviewed.

This skill is a **lens, not an orchestrator**. It teaches whichever agent loads it (Claude, Codex, or any other) how to do an SDI-aware adversarial review: read the planning bundle, apply explicit cross-checks, return findings + verdict. The user invokes the agent of their choice (Opus subagent, Codex CLI, separate session) and that agent loads this skill to drive the review.

The skill does NOT delegate. It does NOT call other models. The agent reading this skill IS the reviewer.

## Why a single skill instead of multiple

Different review entry points (plan, round, fork, bug) share the same SDI grounding: read PRD/ARCHITECTURE/DECISIONS/KNOWN_ISSUES/PLAN/AGENTS, apply the same 7 bug classes, ground every finding in evidence. The mode-specific differences (what artifacts to focus on, what to lead with) are small enough to live in one skill with mode references.

## Entry modes

### Mode 1 — Plan review

Triggered when the user asks for review of an implementation plan document:

- "review this plan" / "review docs/IMPLEMENTATION_PLAN_*.md"
- "the agent proposed this plan, does it look right?"
- "any issues with this plan?"
- "second pair of eyes on the plan?"

Action: load `references/plan-review-protocol.md`. That file documents the full plan review framework — what to read, the 9-step verification, the 7 bug classes, output format. Apply the framework yourself, write the review to `docs/reviews/plan-review-NN.md`, return findings to the user.

### Mode 2 — Round report review

Triggered when the user brings a completed implementation round for review:

- "agent just delivered round X, review?"
- "round B done, what do you think?"
- "anything wrong with this round?"

Action: read the round report end-to-end and the relevant plan §s, then follow `references/round-report-review-patterns.md` §"Round X review". Return findings first, list specific issues graded blocker / non-blocker / nice-to-have, and end with `VERDICT: PASS / FAIL / ESCALATE`.

### Mode 3 — Fork decision

Triggered when the agent surfaces a fork and asks the user to pick:

- "agent is asking whether to do A or B — which?"
- "the implementer proposed two approaches"

Action: read both options, pick based on planning context (PRD/ARCHITECTURE/DECISIONS), explain. Don't say "I trust your judgment" — the user came here precisely because they want a second opinion. See `references/round-report-review-patterns.md` §"A or B fork".

### Mode 4 — Bug or divergence found

Triggered mid-round when the agent (or user) finds something that breaks an assumption:

- "agent found this bug in the plan"
- "agent says X doesn't match the repo"
- "the implementer caught a divergence"

Action: acknowledge fairly (if the plan was wrong, own it), decide fix direction (plan update? DECISIONS entry? revision note?), ensure paper trail. See `references/round-report-review-patterns.md` §"Bug found".

## How to drive a review

Regardless of mode, the loaded agent runs the review itself:

1. **Read the SDI bundle** — `AGENTS.md`, `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/KNOWN_ISSUES.md`, `docs/DECISIONS.md`, `docs/PROJECT_STRUCTURE.md`, the relevant plan, the relevant round report (if any). Mode 1 reads the plan deeply; Mode 2 reads the round report deeply; all modes need the bundle context.
2. **Apply the active checks** in the mode reference. Cross-file consistency, plan-vs-repo grounding, plan-vs-DECISIONS, vague gates, missing prerequisites, stack-specific architecture mistakes, DECISIONS-worthy choices not flagged.
3. **Return findings first** — class, location, what is wrong, why it bites, suggested fix.
4. **End with verdict** — PASS / FAIL / ESCALATE per the mode's rules.
5. **Save the artifact** to `docs/reviews/` (Mode 1: `plan-review-NN.md`; Mode 2: discussion with the user, optional `docs/reviews/round-XN-review.md` if persistent record matters). The repo gets the audit trail; the user reads the live response.

The skill never edits source code. It returns review reports. It may edit review artifacts under `docs/reviews/` and, when the review uncovers an out-of-scope known issue with concrete evidence, `docs/KNOWN_ISSUES.md`; otherwise include a ready-to-paste KI entry in the report.

## Tone in review

- **Direct.** Have a position, defend it, revise it.
- **Specific over generic.** "Looks good" helps nobody — point at file:line.
- **Don't rubber-stamp.** Tests passing doesn't mean design is right.
- **Don't defend prior planner output out of ego.** If the plan was wrong and the agent caught it, good. Update and move on.
- **Don't improvise architecture mid-round.** If a real architectural issue surfaces, pause, discuss, decide. Don't fold it silently into the current round.

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

The user may run this skill **independently in multiple sessions** to get diverse perspectives on the same artifact (e.g., one Opus session, one Codex session, both loading this skill). That's a deliberate user choice, not something this skill orchestrates. Each session reads the same SDI bundle, applies the same framework, returns its findings; the user reconciles the outputs.

For mid-round implementation reviews where a reviewer ensemble runs automatically as part of `sdi-mode`'s Checkpoint gate, see `sdi-mode/references/auto-review-mode.md` — that's a different mechanism (orchestrated by `sdi-mode`, not by this skill).

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
