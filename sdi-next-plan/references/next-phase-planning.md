# Next-phase planning

Generates the `IMPLEMENTATION_PLAN_*.md` for the **next** work item in an ongoing project, after a review of the current one (typically via `sdi-review`) and before implementation starts.

This is **not** the initial bundle (`mvp-architect` Phase 0–C): it produces one plan — or a split set, see §"Generation rules" — optionally with a ROADMAP revision, from context already established. Don't re-derive scope, stack or conventions; they live in the existing artifacts.

## When to enter

Strong signals — offer proactively, or act when the user asks:

- The current `IMPLEMENTATION_PLAN_*` finished its housekeeping (sdi-mode Step 8): gates green, AC mapped to evidence, fact sheet updated.
- The user says "phase X closed, plan the next", "scope feature Y", "plan maintenance for W".
- ROADMAP.md names the next phase and its pre-requisites are met.

Soft signals — verify first: a round (not a phase) closed and the user is thinking ahead, or a memory entry mentions next-phase pre-work.

Don't enter if the current item is mid-flight (incomplete rounds, pending blockers) or the user wants it reviewed rather than the next one generated — both are `sdi-review` — or if no `IMPLEMENTATION_PLAN_*` has closed yet, which is mvp-architect Phase C territory.

## Reading order before generating

Load context from the **current state of the repo**, not from memory of earlier conversations. ~15 min of reading; don't skip it.

1. **`AGENTS.md` / `CLAUDE.md`** — stack, conventions, and the work index if the fact sheet carries one. When both exist they carry the same facts; note drift first.
2. **`docs/MEMORY.md` + the last 2–3 `docs/memory/` entries** — blockers, observations, open questions.
3. **`docs/DECISIONS.md`** — binding. Skim headers; read the entries touching the next item's area.
4. **`docs/KNOWN_ISSUES.md`** — if the item fixes a `KI-NNN`, reference it; else keep the relevant KIs out of scope.
5. **The most recent `docs/plans/IMPLEMENTATION_PLAN_*.md`** — its §13 (resolved or deferred?), §12 (materialized?), and scope that carries over.
6. **`docs/ROADMAP.md`** — what was planned next; may have shifted.
7. **`docs/PRD.md` §Out of scope** — the item may unlock one; verify before assuming.
8. **Code the item will touch** — directories, helpers, schemas.

## Calibration questions (≤4)

Batch them in one message; the user answers in one reply. Skip any already answered implicitly (e.g. the trigger phrase named the item).

1. **The next work item** — confirm against ROADMAP and the recent memory entries, offering both when they disagree.
2. **Carryovers** — anything from the previous item or `KNOWN_ISSUES.md` needing rework first: blockers, deferred scope, regressions, KIs.
3. **New constraints** — anything since the ROADMAP that changes the shape: customer feedback, perf data, compliance, integration availability.
4. **Naming** — `PHASE_N` or `<slug>`, the two forms defined in `core-templates/implementation-plan-template.md` §"Naming convention". Prefer `PHASE_N` when the item maps onto the ROADMAP's next phase or had to be split; `<slug>` when it is one of several concurrent or unordered streams.

## Generation rules

Use `core-templates/implementation-plan-template.md` for the universal structure and `project-types/{type}/architecture-appendix.md` for the type-specific guidance; the type was chosen at mvp-architect Phase 0 and doesn't change. For repo layout, conventions and UI, read the target project's live `docs/PROJECT_STRUCTURE.md` and `docs/DESIGN_SYSTEM.md`, not this skill's type templates.

Inside the plan:

- **§0** — what from the previous item must be green before this one starts, citing round reports or commits.
- **§0 operating profile** — persist the PO's exact Engineer/Fix/Merge and reviewer models/vendors/efforts/quantity. If not supplied, keep the template's `Pendente` marker so `sdi-mode` asks once before first dispatch; never infer a default.
- **§1** — concrete in and out of scope, guided by PRD §Out of scope and `KNOWN_ISSUES.md`. If the item fixes a `KI-NNN`, list it in scope and require the status update at housekeeping.
- **§2** — reference decisions already taken instead of duplicating them; new schema and contracts get sketched here.
- **§11–§13** follow the template's rules; pre-populate §13 with what the audit of the memory dailies surfaced, and nothing else.

Apply the canonical proportionality rule by reference to `sdi-mode`: tests,
observability, gates, review and checkpoint splits appear only when linked to a
reachable flow, production constraint, approved acceptance criterion or
existing mandatory gate. Do not restate neutral examples merely for style.

Plan length follows the template's byte ceiling. Don't pad. The plan is a stable spec once approved; later facts and evidence link from the round report, short `WORK_LOG.md` close and reviews. If the draft already runs past about 80% of the ceiling, split the item into ordered plans rather than raising the limit.

### Verify-before-claim discipline

Every symbol, class, hook or path the plan names is confirmed by Grep/Read first: the plan asserts that a thing **exists** and has the shape it claims, never that there are N of them. Rule of thumb — **if a reviewer could open the file and say "this is wrong"**, it is concrete and needs Grep; if the only validation is "does this make conceptual sense", it is narrative and does not.

**Anti-patterns:** `(already exists in code)` with no name to grep, and any count or `file:line` anchor in the plan. Those go stale silently and can't be revalidated from prose — the command, the number and the date go to `docs/reviews/`.

## Optional ROADMAP update

If later phases shifted because of this item, add a note at the top of `ROADMAP.md` in the form `> **Revision note (rN, AAAA-MM-DD):** <what moved, what stayed>`. Don't rewrite it wholesale — a change that large is a re-scoping conversation: exit this skill and propose returning to `mvp-architect`.

## Index the new work item

**If the fact sheet (`AGENTS.md` / `CLAUDE.md`) has a Work tracker**, add or update its one-line row and keep both files in sync. The factual close goes to `docs/WORK_LOG.md`. Mark the previous item ✓ if needed; a missing close section is a gap for sdi-mode, not a backfill for this skill.

**If the fact sheet has no Work tracker**, there is nothing to add: the index of work items is the `docs/plans/` folder. A project without a tracker did that deliberately — don't reintroduce one.

## Handoff to sdi-mode

Provide the kickoff prompt from `references/kickoff-prompt-template.md` with the tool-specific line already picked, and close by naming the plan's path (or the `BRIEF_` index and the first phase, when the item was split), its §0 pre-requisites, and the skills that follow: `sdi-review` during execution, this one at close.

## Common failure modes

- **Re-running Phase A.** Type, stack, scope and conventions came from mvp-architect Phase 0/A/B/C. Ask only what's specific to this item.
- **Planning against remembered state.** Skipping the reading order — DECISIONS and recent memory above all — gives a plan that ignores established constraints.
- **Writing one huge plan instead of splitting**, or growing an approved one round by round.
- **Speculating about phase N+2.** Future phases stay in ROADMAP — a split item is the exception, and it gets one plan per phase.
- **Ignoring DECISIONS or KNOWN_ISSUES.** "We use approach X for [area]" is binding: follow it or supersede it, never ignore it. Scan the KI catalog before scoping a bugfix or maintenance pass — don't duplicate an existing `KI-NNN`, and don't leave a fixed one without a status-update gate.
- **Naming inconsistency.** Mixing `PHASE_N` and `<slug>` confuses tracking; if the project started with phases, continue unless a clear shift happens, and record it in DECISIONS.
- **Leaving the item unindexed.** Where the index lives depends on the project (§"Index the new work item"), but the next `sdi-mode` session has to find the plan.
