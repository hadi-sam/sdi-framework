---
name: sdi-next-plan
description: Generate the next IMPLEMENTATION_PLAN_*.md for an ongoing project after a previous work item closes. Reads the current state of the repo (AGENTS, DECISIONS, KNOWN_ISSUES, MEMORY, ROADMAP, prior plan) and produces one new plan tailored to the next work item. USE when "phase X closed, plan the next", "scope feature Y", "plan maintenance for Z", "what's the next implementation plan?". DO NOT USE for initial product scoping (use mvp-architect), reviewing in-flight work (use sdi-review), or executing the plan (use sdi-mode).
---

# sdi-next-plan

Generates the next `IMPLEMENTATION_PLAN_*.md` for an ongoing project, after the user finishes a work item (or phase) and wants to plan the next one. It is **not** the initial bundle (`mvp-architect` Phase 0–C), **not** a review (`sdi-review`), and **not** implementation (`sdi-mode`).

Entry signals, soft signals and the "don't enter" list are in `references/next-phase-planning.md` §"When to enter" — read it before offering to run.

## How it works

1. **Read the current state of the repo** (NOT memory of earlier conversations). Reading order in `references/next-phase-planning.md` §"Reading order before generating".
2. **Calibrate** against ROADMAP with ≤4 focused questions.
3. **Light discovery** only on what's specific to this work item — do NOT re-run mvp-architect Phase A.
4. **Generate one new `IMPLEMENTATION_PLAN_*.md`** using the universal template + type appendix. Persist the PO's work-item role profile in §0, or the exact `Pendente` marker when it has not been chosen; never invent it.
5. **Index the new work item.** If the fact sheet (`AGENTS.md` / `CLAUDE.md`) has a Work tracker, add the one-line row, keeping both files in sync when both exist. If it has none, there is nothing to add: the index of work items is the `docs/plans/` folder and the history is `docs/WORK_LOG.md`.
6. **Optional:** ROADMAP revision note if subsequent phases shifted.
7. **Hand off to `sdi-mode`** via the kickoff prompt.

Full protocol, naming choice (`PHASE_N` vs `<slug>`) and the common failure modes are in `references/next-phase-planning.md`.

## References

Load these as needed:

- `references/next-phase-planning.md` — full protocol: when to enter, reading order, calibration questions, naming choice, generation rules, optional ROADMAP update, indexing the work item, kickoff handoff, common failure modes.
- `references/kickoff-prompt-template.md` — handoff prompt to `sdi-mode` after the plan is generated.
- `references/core-templates/implementation-plan-template.md` — universal plan structure used to generate the artifact, including the plan's byte ceiling.
- `references/project-types/{type}/architecture-appendix.md` — type-specific architecture sections. Use the same type the project chose at mvp-architect Phase 0.
