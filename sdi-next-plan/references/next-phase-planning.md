# Next-phase planning

This skill generates the `IMPLEMENTATION_PLAN_*.md` for the **next** work item in an ongoing project. It runs after a review of the current item (typically via the `sdi-review` skill) and before the user kicks off the next round of implementation. Together review and next-plan form a continuous loop while the project is being built.

This is **not** the initial bundle (handled by `mvp-architect` Phase 0–C). It generates a single artifact (one new implementation plan, optionally a ROADMAP revision) using context already established. Don't re-derive scope, stack, or conventions — they live in the existing artifacts.

## When to enter

Strong signals — proactive offer or user-initiated:

- The current `IMPLEMENTATION_PLAN_*` has had its end-of-phase housekeeping done (per sdi-mode Step 8): all gates green, AC mapped to evidence, AGENTS.md / CLAUDE.md tracker updated where present.
- The user says: "phase X closed — let's plan the next", "what's the next plan?", "let's scope feature [Y]", "let's plan maintenance for [W]".
- ROADMAP.md indicates the next phase and its pre-requisites are met.

Soft signals — this skill may be appropriate but verify with user first:

- A round (not full phase) just closed and the user is clearly thinking ahead about the next phase.
- The user shows a memory entry that mentions next-phase pre-work.

Don't enter if:

- The current work item is mid-flight (incomplete rounds, pending blockers). Stay in `sdi-review`.
- The user is asking for review of the current plan, not generation of the next. Stay in `sdi-review`.
- The project is so early that there's no `IMPLEMENTATION_PLAN_*` closed yet — that's still mvp-architect Phase C territory or initial work.

## Reading order before generating

Load context from the **current state of the repo**, not from your memory of earlier conversations:

1. **`AGENTS.md` / `CLAUDE.md`** (root) — current stack, conventions, work tracker. If both exist, they should carry the same project facts; note any drift before planning.
2. **`docs/MEMORY.md` index + last 2–3 daily entries from `docs/memory/`** — what's been happening, blockers, observations the user made, open questions still pending.
3. **`docs/DECISIONS.md`** — what's been decided. The next plan must respect these, not contradict them. Skim headers; read entries that relate to the area of the next work item.
4. **`docs/KNOWN_ISSUES.md`** — known bugs, security gaps, tech debt, and deferred fixes. If the next work item fixes a `KI-NNN`, reference it explicitly; if it does not, keep relevant KIs out of scope.
5. **The most recent `docs/IMPLEMENTATION_PLAN_*.md`** — what was just delivered (or is closing). Look for §13 Known divergences (resolved? deferred?), §12 Decisions Log items (all materialized?), and any deferred scope that must carry over.
6. **`docs/ROADMAP.md`** — what was originally planned next. May still be accurate; may have shifted.
7. **`docs/PRD.md` §Out of scope** — what was explicitly deferred. The next work item may be unlocking one of these; verify before assuming.
8. **Code areas the next work item will touch** — directories, helpers, schemas. Saves the user from repeating "this lives at X" later.

This is ~10–20 minutes of reading before generating. Don't skip it.

## Calibration questions (≤4)

Before generating the plan, verify alignment with current reality. Batch in one message; user answers in one reply:

1. **Confirm the next work item.** "ROADMAP says next is [X], and the most recent memory mentions [Y]. Is the next work item [X], [Y], something else, or both?"
2. **Carryovers / known issues.** "Anything from the previous work item or `KNOWN_ISSUES.md` that needs rework before moving on? Pending blockers, deferred scope items, regressions, KI entries to schedule?"
3. **New constraints.** "Anything that's surfaced since the original ROADMAP that changes the shape of this — customer feedback, perf data, new compliance requirement, integration availability?"
4. **Naming preference.** "Should this be `IMPLEMENTATION_PLAN_PHASE_N.md` (next discrete phase) or `IMPLEMENTATION_PLAN_<slug>.md` (free-form work — feature, maintenance, refactor)? See naming guidance below if unsure."

If the user already answered these implicitly (e.g., the trigger phrase already named the work item), skip those questions.

## Naming choice

| Use `PHASE_N` | Use `<slug>` |
|---|---|
| Project follows a discrete linear ROADMAP (greenfield, structured migrations) | Free-form feature work, bugfixes, maintenance batches, perf passes in ongoing projects |
| The work item maps cleanly to "next phase" in ROADMAP | The work item is one of many concurrent or unordered streams |
| User started with `mvp-architect` Phase 0–C | User started with `convert-to-sdi` (legacy adoption) or has been using slugs |
| Examples: `PHASE_2`, `PHASE_3` | Examples: `billing-portal`, `q1-perf-pass`, `customer-x-bugfix`, `auth-refactor` |

The framework treats `IMPLEMENTATION_PLAN_*.md` uniformly — both styles work. Pick what fits the project's mental model.

## Generation rules

Use `core-templates/implementation-plan-template.md` for the universal structure + `project-types/{type}/architecture-appendix.md` for type-specific guidance. The type was chosen during initial scoping at mvp-architect Phase 0 and doesn't change between phases of the same project; pick the appendix matching the project's recorded type. For repo layout, conventions, and UI details, read the target project's live `docs/PROJECT_STRUCTURE.md` and `docs/DESIGN_SYSTEM.md` (when present) rather than looking for type templates inside this skill.

Inside the plan:

- **§0 Pre-requisites** — list what from the previous work item must be green before starting this one. Reference round reports or commits where applicable. Examples: "Phase 1 housekeeping complete (smoke test green)", "DECISIONS #28-#31 materialized in code", "Migration `0007_add_billing_tables` applied".
- **§1 Scope** — concrete in-scope and out-of-scope. The PRD §Out-of-scope and `KNOWN_ISSUES.md` are your guides for what's deferred; if the work item fixes `KI-NNN`, list it in scope and require status update during housekeeping.
- **§2 Type-specific (database / API / UI / etc.)** — reference DECISIONS already taken (link `DECISIONS.md #N`), don't duplicate. New schema/contracts get sketched here.
- **§11 Implementation checkpoints** — map §2–§9 work units to the standard 5 checkpoints (Foundation, Core, Integrations, UI, Housekeeping). Drop checkpoints not applicable to this work item (e.g., no UI → drop Checkpoint 4). The standard gates per checkpoint are inlined in the plan template (mirrored from sdi-mode for self-containment). Add phase-specific gates only when the phase has constraints unique to it.
- **§12 Decisions Log** — only the decisions you anticipate this work item will memorialize. Don't pre-record decisions from earlier work items.
- **§13 Known divergences** — pre-populate with anything the audit of recent memory dailies surfaced.

Plan length: same target as initial-bundle plans (400–600 lines). Don't pad.

## Optional ROADMAP update

If subsequent phases shifted in priority or content as a result of this work item, update `ROADMAP.md` with a revision note at the top. Pattern:

```markdown
> **Revision note (r2 — 2026-04-25):** Phase 3 (analytics) reordered after Phase 2 (billing) per customer prioritization. Phase 4 unchanged.
```

Don't rewrite ROADMAP wholesale. If the change is large enough to warrant a rewrite, that's a re-scoping conversation — exit this skill and propose returning to `mvp-architect` for scope refresh.

## Update the work tracker in AGENTS.md / CLAUDE.md

After generating the plan, add (or update) a row in the `Work tracker` section of `AGENTS.md` and `CLAUDE.md` when both exist. If only one exists, update that one and mention the missing companion as a housekeeping note:

```markdown
| billing-portal | feature | pending — plan generated | 2026-04-25 | docs/IMPLEMENTATION_PLAN_billing-portal.md |
```

Mark the previous work item as ✓ if it isn't already.

## Handoff to sdi-mode

After the plan is generated, the user starts implementation. Provide the consolidated kickoff prompt from `references/kickoff-prompt-template.md`, selecting the single tool-specific line: `sdi-mode` skill for Claude Code/Codex, or `sdi-mode` custom mode for Roo/Kilo/OpenCode.

Closing message pattern:

> "Plan generated at `docs/IMPLEMENTATION_PLAN_<name>.md`. Pre-requisites: [list from §0]. To start, use the kickoff prompt for your tool, with the `sdi-mode` skill/custom-mode line selected. When you need review during execution, use `sdi-review`. When this work item closes, come back here for the next plan."

## Common failure modes

- **Re-running Phase A.** Tempting to "verify the universal themes again" — don't. mvp-architect Phase 0/A/B/C established type, modifier, stack, scope, conventions. This skill only asks about what's specific to the next work item.
- **Generating plan divorced from current repo state.** If you skip the reading order (especially DECISIONS and recent memory), the plan ignores constraints already established. Always read first.
- **Speculating about phase N+2.** The plan is for the **next** work item, not the one after that. Future phases stay in ROADMAP, not in the next plan.
- **Ignoring DECISIONS already taken.** A DECISIONS entry that says "we use approach X for [area]" is binding — the next plan must follow it or explicitly supersede with a new entry. Never silently ignore.
- **Ignoring KNOWN_ISSUES.** If the next work item is a bugfix/maintenance pass, scan `KNOWN_ISSUES.md` before scoping. Don't create duplicate work for an existing `KI-NNN`, and don't leave fixed KIs without a status-update gate.
- **Naming inconsistency.** Mixing `PHASE_N` and `<slug>` in the same project causes confusion in tracking. If the project started with phases, prefer to continue with phases unless a clear shift happens (e.g., MVP launched, now in continuous-feature mode). Document the shift in DECISIONS.
- **Skipping the work tracker update.** AGENTS.md / CLAUDE.md are the operating truth for project facts. If the tracker doesn't reflect the new work item, sdi-mode Step 1 reads stale state.

## Difference from initial bundle

| | mvp-architect Phase C (initial bundle) | sdi-next-plan (next plan) |
|---|---|---|
| When | Once, at project birth | Repeatedly, between work items |
| Reads | Phase 0/A/B context (in-session) | The repo itself (post-implementation reality, including DECISIONS, KNOWN_ISSUES, and memory) |
| Outputs | 8–9 artifacts (full bundle, including KNOWN_ISSUES) | 1 artifact (one IMPLEMENTATION_PLAN), optionally 1 ROADMAP revision |
| Discovery | Full universal + type-specific | Light — only what's specific to the next item |
| Follows | mvp-architect Phase B (scope agreed) | sdi-review (review of current item) |
| Precedes | sdi-mode (implementation begins) | sdi-mode + sdi-review (next item begins) |
