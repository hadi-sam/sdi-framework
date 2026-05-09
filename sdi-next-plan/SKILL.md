---
name: sdi-next-plan
description: Generate the next IMPLEMENTATION_PLAN_*.md for an ongoing project after a previous work item closes. Reads the current state of the repo (AGENTS, DECISIONS, KNOWN_ISSUES, MEMORY, ROADMAP, prior plan) and produces one new plan tailored to the next work item. USE when "phase X closed, plan the next", "scope feature Y", "plan maintenance for Z", "what's the next implementation plan?". DO NOT USE for initial product scoping (use mvp-architect), reviewing in-flight work (use sdi-review), or executing the plan (use sdi-mode).
---

# sdi-next-plan

This skill generates the next `IMPLEMENTATION_PLAN_*.md` for an ongoing project. It runs after the user finishes a work item (or phase) and wants to plan the next one.

## What this is not

- **Not the initial bundle.** Initial scoping (PRD, ARCHITECTURE, ROADMAP, etc.) is `mvp-architect` Phase 0–C. This skill assumes those exist.
- **Not a review.** If the user wants a second pair of eyes on a plan or round, that's `sdi-review`.
- **Not implementation.** Execution is `sdi-mode`.

## When to enter

**Strong signals — proactive offer or user-initiated:**

- The current `IMPLEMENTATION_PLAN_*` has had its end-of-phase housekeeping done (per sdi-mode Step 8): all gates green, AC mapped to evidence, AGENTS.md / CLAUDE.md tracker updated where present.
- The user says: "phase X closed — let's plan the next", "what's the next plan?", "let's scope feature [Y]", "let's plan maintenance for [W]".
- ROADMAP.md indicates the next phase and its pre-requisites are met.

**Soft signals — verify with user first:**

- A round (not full phase) just closed and the user is clearly thinking ahead about the next phase.
- The user shows a memory entry that mentions next-phase pre-work.

**Don't enter if:**

- The current work item is mid-flight (incomplete rounds, pending blockers). Use `sdi-review` instead.
- The user is asking for review of the current plan, not generation of the next. Use `sdi-review`.
- The project is so early there's no `IMPLEMENTATION_PLAN_*` closed yet — that's still mvp-architect Phase C territory.

## How it works

1. **Read the current state of the repo** (NOT memory of earlier conversations). Detailed reading order in `references/next-phase-planning.md` §"Reading order before generating".
2. **Calibrate** against ROADMAP with ≤4 focused questions.
3. **Light discovery** only on what's specific to this work item — do NOT re-run mvp-architect Phase A.
4. **Generate one new `IMPLEMENTATION_PLAN_*.md`** using the universal template + type appendix.
5. **Update AGENTS.md / CLAUDE.md work tracker** with the new row, keeping both files in sync when both exist.
6. **Optional:** ROADMAP revision note if subsequent phases shifted.
7. **Hand off to `sdi-mode`** via the kickoff prompt.

Full protocol in `references/next-phase-planning.md`.

## Naming choice

| Use `PHASE_N` | Use `<slug>` |
|---|---|
| Project follows a discrete linear ROADMAP (greenfield, structured migrations) | Free-form feature work, bugfixes, maintenance batches, perf passes |
| The work item maps cleanly to "next phase" in ROADMAP | The work item is one of many concurrent or unordered streams |
| User started with `mvp-architect` Phase 0–C | User started with `convert-to-sdi` (legacy adoption) or has been using slugs |
| Examples: `PHASE_2`, `PHASE_3` | Examples: `billing-portal`, `q1-perf-pass`, `customer-x-bugfix`, `auth-refactor` |

The framework treats `IMPLEMENTATION_PLAN_*.md` uniformly — both styles work. Pick what fits the project's mental model.

## Common failure modes

- **Re-running Phase A.** Tempting to "verify the universal themes again" — don't. mvp-architect Phase 0/A/B/C established type, modifier, stack, scope, conventions. This skill only asks about what's specific to the next work item.
- **Generating plan divorced from current repo state.** If you skip the reading order (especially DECISIONS and recent memory), the plan ignores constraints already established. Always read first.
- **Speculating about phase N+2.** The plan is for the **next** work item, not the one after that. Future phases stay in ROADMAP, not in the next plan.
- **Ignoring DECISIONS or KNOWN_ISSUES already recorded.** A DECISIONS entry that says "we use approach X for [area]" is binding; a `KI-NNN` entry may be the reason this work item exists or must stay out of scope. Never silently ignore either.

## References

Load these as needed:

- `references/next-phase-planning.md` — full protocol: when to enter, reading order, calibration questions, generation rules, optional ROADMAP update, work tracker update, kickoff handoff, common failure modes.
- `references/agents-template.md` — AGENTS.md / CLAUDE.md structure (this skill updates the work tracker row).
- `references/kickoff-prompt-template.md` — handoff prompt to `sdi-mode` after the plan is generated.
- `references/core-templates/implementation-plan-template.md` — universal plan structure used to generate the artifact.
- `references/project-types/{type}/architecture-appendix.md` — type-specific architecture sections (8 types). Use the same type the project chose at mvp-architect Phase 0.
