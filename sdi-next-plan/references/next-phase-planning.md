# Next-phase planning

Generates the `IMPLEMENTATION_PLAN_*.md` for the **next** work item in an ongoing project, after a review of the current one (typically via `sdi-review`) and before implementation starts.

This is **not** the initial bundle (`mvp-architect` Phase 0–C): it produces one plan, optionally a ROADMAP revision, from context already established. Don't re-derive scope, stack or conventions — they live in the existing artifacts.

## When to enter

Strong signals — offer proactively, or act when the user asks:

- The current `IMPLEMENTATION_PLAN_*` finished its end-of-phase housekeeping (sdi-mode Step 8): gates green, AC mapped to evidence, fact sheet updated.
- The user says "phase X closed, plan the next", "scope feature Y", "plan maintenance for W".
- ROADMAP.md names the next phase and its pre-requisites are met.

Soft signals — verify first: a round (not a full phase) just closed and the user is thinking ahead, or a memory entry mentions next-phase pre-work.

Don't enter if the current item is mid-flight (incomplete rounds, pending blockers), if the user wants the current plan reviewed rather than the next one generated — both are `sdi-review` — or if no `IMPLEMENTATION_PLAN_*` has closed yet, which is still mvp-architect Phase C territory.

## Reading order before generating

Load context from the **current state of the repo**, not from your memory of earlier conversations. It is ~15 minutes of reading; don't skip it.

1. **`AGENTS.md` / `CLAUDE.md`** — stack, conventions, and the work index if the fact sheet carries one. When both exist they should carry the same facts; note any drift first.
2. **`docs/MEMORY.md` + the last 2–3 entries in `docs/memory/`** — blockers, observations the user made, questions still open.
3. **`docs/DECISIONS.md`** — binding. Skim headers; read the entries touching the area of the next item.
4. **`docs/KNOWN_ISSUES.md`** — if the item fixes a `KI-NNN`, reference it explicitly; if not, keep the relevant KIs out of scope.
5. **The most recent `docs/plans/IMPLEMENTATION_PLAN_*.md`** — its §13 (resolved or deferred?), its §12 (all materialized?), and scope that carries over.
6. **`docs/ROADMAP.md`** — what was planned next; it may have shifted.
7. **`docs/PRD.md` §Out of scope** — the item may be unlocking one of these; verify before assuming.
8. **Code areas the item will touch** — directories, helpers, schemas.

## Calibration questions (≤4)

Batch them in one message; the user answers in one reply. Skip any already answered implicitly (e.g. the trigger phrase named the work item).

1. **The next work item** — confirm it against ROADMAP and the recent memory entries, offering both when they disagree.
2. **Carryovers** — anything from the previous item or `KNOWN_ISSUES.md` needing rework first: blockers, deferred scope, regressions, KIs to schedule.
3. **New constraints** — anything since the original ROADMAP that changes the shape of this: customer feedback, perf data, compliance, integration availability.
4. **Naming** — `PHASE_N` or `<slug>`, per §"Naming choice" below.

## Naming choice

Both forms are defined in the plan template's §"Naming convention" and the framework treats them uniformly, so this is a choice of mental model. Use `PHASE_N` when the project follows a discrete linear ROADMAP, the item maps onto its next phase, and the project started at `mvp-architect` Phase 0–C. Use `<slug>` when the item is one of several concurrent or unordered streams, or the project came in through `convert-to-sdi`. Mixing both in one project is a failure mode; see below.

## Generation rules

Use `core-templates/implementation-plan-template.md` for the universal structure and `project-types/{type}/architecture-appendix.md` for the type-specific guidance; the type was chosen at mvp-architect Phase 0 and doesn't change between phases. For repo layout, conventions and UI, read the target project's live `docs/PROJECT_STRUCTURE.md` and `docs/DESIGN_SYSTEM.md` rather than this skill's type templates.

Inside the plan:

- **§0** — what from the previous work item must be green before this one starts, citing round reports or commits.
- **§1** — concrete in and out of scope, guided by PRD §Out of scope and `KNOWN_ISSUES.md`. If the work item fixes a `KI-NNN`, list it in scope and require the status update during housekeeping.
- **§2** — reference decisions already taken instead of duplicating them; new schema and contracts get sketched here.
- **§11–§13** follow the template's own rules for those sections; pre-populate §13 with whatever the audit of the recent memory dailies surfaced, and nothing else.

Plan length: the byte ceiling in `core-templates/implementation-plan-template.md` §Size, which is the project's docs lint when the project has one. Don't pad.

### Verify-before-claim discipline

Every symbol, class, hook or path the plan names must be confirmed by Grep/Read first: the plan asserts that a thing **exists** and has the shape it claims, never that there are N of them. Rule of thumb — **if a reviewer could open the file and say "this is wrong"**, it is concrete and needs Grep; if the only validation is "does this make conceptual sense", it is narrative (motivation, rationale, external sources) and does not.

**Anti-patterns:** `(already exists in code)` with no name to grep, and any count or `file:line` anchor in the plan. Those go stale silently and can't be revalidated from prose — put the command, the number and the date in `docs/reviews/` and point there.

## Optional ROADMAP update

If later phases shifted because of this work item, add a note at the top of `ROADMAP.md` in the form `> **Revision note (rN, YYYY-MM-DD):** <what moved, what stayed>`. Don't rewrite ROADMAP wholesale — a change that large is a re-scoping conversation: exit this skill and propose returning to `mvp-architect`.

## Index the new work item

**If the fact sheet (`AGENTS.md` / `CLAUDE.md`) has a Work tracker**, add or update the one-line row there — item, type, status, date, path to the plan — keeping both files in sync when both exist and flagging a missing companion as a housekeeping note. The row stays one line: the narrative goes to `docs/WORK_LOG.md` when the item closes (sdi-mode Step 8). Mark the previous item ✓ if it isn't; a missing `WORK_LOG.md` section for it is a gap for sdi-mode, not something this skill backfills.

**If the fact sheet has no Work tracker**, there is nothing to add and nothing to keep in sync: the index of work items is the `docs/plans/` folder and the history of closed items is `docs/WORK_LOG.md`. A project that has no tracker did that deliberately — don't reintroduce one.

## Handoff to sdi-mode

Provide the kickoff prompt from `references/kickoff-prompt-template.md` with the single tool-specific line already picked, and close by naming the plan's path, its §0 pre-requisites, and the two skills that follow: `sdi-review` during execution, this one again when the item closes.

## Common failure modes

- **Re-running Phase A.** Type, modifier, stack, scope and conventions were established at mvp-architect Phase 0/A/B/C. Ask only about what's specific to this item.
- **Planning against remembered state.** Skipping the reading order — DECISIONS and recent memory above all — produces a plan that ignores established constraints.
- **Speculating about phase N+2.** Future phases stay in ROADMAP.
- **Ignoring DECISIONS or KNOWN_ISSUES.** "We use approach X for [area]" is binding: follow it or supersede it with a new entry, never silently ignore it. Likewise scan the KI catalog before scoping a bugfix or maintenance pass — don't duplicate an existing `KI-NNN`, and don't leave a fixed one without a status-update gate.
- **Naming inconsistency.** Mixing `PHASE_N` and `<slug>` in one project confuses tracking; if the project started with phases, continue with phases unless a clear shift happens, and record the shift in DECISIONS.
- **Leaving the work item unindexed.** Where the index lives depends on the project (§"Index the new work item"), but the next `sdi-mode` session has to be able to find the plan.
