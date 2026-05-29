# First work item (Phase 3)

After Phase 2 generates the artifact bundle, Phase 3 generates the **first** `IMPLEMENTATION_PLAN_*.md` and hands the project off to `sdi-mode`. This is the moment the project transitions from "running without framework" to "running under framework".

## Why this phase exists

Without Phase 3, the user has artifacts but no plan to start working from. They'd have to either:
- Run the `sdi-next-plan` skill manually (works, but it expects a previous IMPLEMENTATION_PLAN to read for context — there isn't one yet).
- Improvise the first plan themselves (defeats the framework's purpose).

Phase 3 bridges this. It's a specialized variant of `sdi-next-plan` that knows:
- This is the first plan in the project's framework history.
- §0 Pre-requisites references "current production state" or "current repo state", not "Phase N-1 delivered".
- The plan is grounded in code reality, not in a previous framework-managed phase.

## The single question

After Phase 2 is complete, ask:

```
**Phase 3 — first work item.**

What's the next concrete work?
(a) New feature
(b) Bugfix / hotfix
(c) Migration / structured refactor
(d) Performance / observability pass
(e) Maintenance (upkeep tasks, dependency updates, etc.)
(f) Other — describe

And what short name (slug or Phase N) do you want for this plan?
E.g.: `billing-portal-fix`, `q1-perf-pass`, `customer-x-bug`, `Phase 1`, etc.
```

The user answers. From there:

## Naming logic

| User's answer | Suggested name |
|---|---|
| (c) Migration / structured refactor, AND user gave a "Phase N" style name | `IMPLEMENTATION_PLAN_PHASE_N.md` |
| (c) Migration / refactor without phase numbering | `IMPLEMENTATION_PLAN_<slug>.md` (e.g. `IMPLEMENTATION_PLAN_auth-refactor.md`) |
| (a) (b) (d) (e) (f) | `IMPLEMENTATION_PLAN_<slug>.md` |

If the project Q4 said "discrete phases planned", lean toward `PHASE_N`. Otherwise lean toward `<slug>`. When in doubt, ask the user once: *"Naming preference for this plan: `PHASE_N` or `<slug>`?"*

Don't ask multiple naming questions — pick a default and confirm.

## Generating the plan

Use the templates carried by this skill (duplicated from `mvp-architect` so this skill is self-contained):

- Core: `core-templates/implementation-plan-template.md`
- Type appendix (for type-specific sections referenced by the plan): `project-types/{type}/architecture-appendix.md`

But adapt §0 (Pre-requisites):

```markdown
## 0. Pre-requisites

> Source: code analysis (current repo state). This work item starts from the live production state, not from a previous framework-managed phase.

- Repo at commit [SHA or branch + recent state] — convert-to-sdi run completed; framework artifacts in place.
- `AGENTS.md` / `CLAUDE.md` at root reflect current stack and conventions; if both exist, they carry the same facts.
- DECISIONS.md seed entries reviewed by team (or pending review).
- KNOWN_ISSUES.md exists; any known issue in scope for this work item is referenced by `KI-NNN`.
- [If stage = production] No incidents in flight; deploy window applicable.
- [Other pre-reqs the user mentioned during Phase 1 Q5 if relevant.]
```

For the rest of the plan (§1 Scope, §2+ type-specific, §10 Acceptance Criteria, etc.), follow the standard template. Where the user can supply specifics, ask **focused, narrow** questions:

- "What's the acceptance criterion for this work? How will you know it's done?"
- "Which files/areas of the repo does this touch?"
- "Any specific approach you want — or open?"

Keep questions concrete. Aim for 2–4 questions max. Each accepts "don't know — you propose" — in that case, propose with rationale and let the user accept or revise.

## Plan length

Target same as Phase C / `sdi-next-plan` plans: 400–600 lines. For a small bugfix or single-file feature, OK to be shorter (200–300). Don't pad.

## Update the work tracker

After the plan is generated, add a one-line index row to the `Work tracker` in `AGENTS.md` and `CLAUDE.md` when both exist:

```markdown
| [name] | [type] | pending — plan generated | YYYY-MM-DD | docs/IMPLEMENTATION_PLAN_[name].md |
```

Keep the row to one line. The verbose narrative for this item is written to `docs/WORK_LOG.md` (a new `## <work item>` section) when it **closes** — at sdi-mode Step 8 housekeeping — not now.

Update today's `docs/memory/YYYY-MM-DD.md` to mention the plan was generated and the user is about to start work.

## Handoff to sdi-mode

After plan generation, instruct the user how to start. The kickoff prompt has one consolidated shape with a single conditional line for how `sdi-mode` is loaded (skill vs custom mode).

```
Plan generated at `docs/IMPLEMENTATION_PLAN_[name].md`.

`AGENTS.md` and `CLAUDE.md` are at the project root with the same project facts (stack, doc map, conventions, work tracker). The SDI discipline itself comes from the `sdi-mode` skill (Claude Code / Codex) or the configured `sdi-mode` custom mode (Roo Code / Kilo Code / OpenCode). The user may keep whichever file(s) their coding agents read.

To start, paste:

> Implementing [name] of this project per docs/IMPLEMENTATION_PLAN_[name].md.
>
> [For Claude Code / Codex:] Use the `sdi-mode` skill for this work.
> [For Roo Code / Kilo Code / OpenCode:] Activate the `sdi-mode` custom mode for this work.
>
> Read in this order before writing any code:
> 1. README.md to get context.
> 2. AGENTS.md or CLAUDE.md (project facts — stack, doc map, conventions, work tracker).
> 3. docs/IMPLEMENTATION_PLAN_[name].md fully.
> 4. docs/PROJECT_STRUCTURE.md for conventions.
> 5. docs/ARCHITECTURE.md — at minimum the type-specific section and the critical flows.
> 6. docs/KNOWN_ISSUES.md — confirm whether any known issue is in scope or must stay deferred.
>
> Then audit the plan against the actual repo state. Produce an audit report covering:
> - Blockers
> - Plan-repo divergences (where plan and repo disagree — the repo wins)
> - Open questions for me
> - Aligned / no action items
>
> After the audit, propose the first deliverable and stop for review.
```

When generating the user-facing kickoff, drop the line that doesn't match their tool. If they haven't said which tool, leave both lines so they can pick, or ask before generating.

For tool-specific setup (installing the `sdi-mode` skill or registering the custom mode), point the user to the relevant guide in their local copy of `sdi-framework/installation-guides/`.

## Closing message

After the plan is delivered and the handoff instructions are given:

> "**Setup complete.** The project is now under the framework.
>
> Next work items: after this one closes, **don't** run convert-to-sdi again. Use the `sdi-next-plan` skill (just say "phase X closed — let's plan the next" or similar). It reads the current repo state + DECISIONS + memory and generates the next plan without redoing the full discovery."

## What NOT to do in Phase 3

- ❌ **Don't generate multiple plans at once.** First work item only. The framework wants one plan per work item, generated when the previous closes (or for the first one, now).
- ❌ **Don't skip §0 Pre-requisites.** It's how the plan grounds itself in current reality. Without it, the audit phase of sdi-mode has nothing to compare against.
- ❌ **Don't ask the user to define the entire roadmap.** The user only needs to define this *one* work item now. Future items are scoped via the `sdi-next-plan` skill later.
- ❌ **Don't skip the handoff instructions.** Even an experienced user benefits from the explicit kickoff prompt — it activates the framework's audit-first discipline cleanly.

## When the user doesn't have a "next work item" in mind

Sometimes the user runs convert-to-sdi to "set up the framework" but doesn't have a concrete next thing to work on yet. That's fine. In that case, skip the plan generation:

> "No concrete work item right now, so I won't generate a plan. When you know what's next (feature, fix, migration, etc.), use the `sdi-next-plan` skill to generate the plan. AGENTS.md / CLAUDE.md, DECISIONS, KNOWN_ISSUES, and MEMORY are already in place to receive the work when it arrives."

Then close the convert-to-sdi run with a partial completion note in `docs/memory/YYYY-MM-DD.md`.
