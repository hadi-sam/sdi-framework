# Kickoff Prompt Template

At the end of Phase C the user takes the spec bundle and hands it to a coding agent. The kickoff prompt sets the tone: read first, audit before code, stop at checkpoints. There is **one consolidated template**, with a single conditional line for how `sdi-mode` is loaded — as a skill (Claude Code / Codex) or as a custom mode (Roo Code / Kilo Code / OpenCode).

## The template

Paste this at the start of the user's first implementation session, replacing the placeholders.

```
Implementing [Phase 1 / <slug>] of this project per docs/IMPLEMENTATION_PLAN_[PHASE_1 | <slug>].md.

[For Claude Code / Codex:] Use the `sdi-mode` skill for this work.
[For Roo Code / Kilo Code / OpenCode:] Activate the `sdi-mode` custom mode for this work.

Read in this order before writing any code:
1. README.md to get context.
2. AGENTS.md or CLAUDE.md (project facts — stack, doc map, conventions, work tracker).
3. docs/MEMORY.md + the latest docs/memory/YYYY-MM-DD.md entry to see handoff state.
4. docs/IMPLEMENTATION_PLAN_[PHASE_1 | <slug>].md fully.
5. docs/PROJECT_STRUCTURE.md for conventions.
6. docs/ARCHITECTURE.md — at minimum the type-specific section and the critical flows.
7. docs/KNOWN_ISSUES.md — confirm whether any known issue is in scope or must stay deferred.
8. docs/DECISIONS.md — skim existing decisions before making new ones.

Then audit the plan against the actual repo state. Produce an audit report covering:
- Blockers (things preventing start)
- Plan-repo divergences (where plan and repo disagree — the repo wins)
- Open questions for me
- Aligned / no action items

After the audit, propose the first deliverable — usually [foundation: schema/migration/dependencies for types with a database; project scaffolding for fresh repos] — and stop for review. Don't start on subsequent scope items until I approve the foundation.
```

The prompt is short because the SDI discipline (8-step loop, audit-first, stop-and-review, DECISIONS, memory, document precedence, tone) is loaded by the `sdi-mode` skill or custom mode. The kickoff just signals "we're starting this work item — proceed with audit".

Substitute `[Phase 1 / <slug>]` with whichever naming applies — `PHASE_N` for discrete phases (greenfield/migrations) or `<slug>` for free-form work (features/maintenance in ongoing projects). Drop the line that doesn't match the user's tool.

## When generating the kickoff for a specific user

The Phase C output to the user includes the kickoff prompt with the right line picked, not both. Decide based on what the user said about their tool:

- User mentioned Claude Code or Codex → keep the **skill** line.
- User mentioned Roo, Kilo, or OpenCode → keep the **custom mode** line.
- User didn't say → present both inline (so they can pick) or ask which they're using before generating the final prompt.

## Variations for mid-project prompts

### Starting Phase N (where N > 1)

```
Phase N-1 is shipped (see DECISIONS.md, KNOWN_ISSUES.md, and PROJECT_STRUCTURE.md for what was delivered, deferred, or fixed).

Now implementing Phase N per docs/IMPLEMENTATION_PLAN_PHASE_N.md.

[For Claude Code / Codex:] Use the `sdi-mode` skill for this work.
[For Roo Code / Kilo Code / OpenCode:] Activate the `sdi-mode` custom mode for this work.

Follow the same SDI discipline as Phase 1:
1. Read the plan fully.
2. Audit against the current repo.
3. Produce an audit report before writing code.
4. Stop at natural checkpoints for review.
5. Write tests alongside code.
6. DECISIONS.md for non-obvious choices; KNOWN_ISSUES.md for pre-existing bugs/tech debt/security gaps that stay out of scope.

Start with the audit.
```

### Continuing within a work item (phase or slug)

```
Continuing [Phase N / <slug>] from where we stopped. Last round delivered [X]; next suggested round is [Y].

[For Claude Code / Codex:] Use the `sdi-mode` skill (it should already be loaded if you're in the same session — re-invoke if needed).
[For Roo Code / Kilo Code / OpenCode:] Stay in the `sdi-mode` custom mode.

Before starting, verify:
- Round [X] is fully merged and tests are green.
- Audit state from the start of the phase is still valid (no new divergences).
- Plan §[section] for round [Y] has what you need, or needs a revision note.

Propose the first deliverable of this round and stop for review.
```

## What the prompts do

- **Force context loading before code.** The agent reads before writing.
- **Prime the audit discipline.** The audit is the highest-leverage step; make it explicit.
- **Establish repo-wins rule.** Prevents the agent from being hostage to a stale plan.
- **Pre-announce stop-and-review.** The user isn't surprised when the agent stops; it's expected.
- **Normalize DECISIONS.md, KNOWN_ISSUES.md, and MEMORY.md.** Makes the decision trail, known-issue catalog, and handoff memory defaults, not afterthoughts.
- **Set tone for revision notes.** Plans evolve; the agent knows how to mark that.

The skill / custom-mode mechanism differs per tool, but the behaviors expected from the agent are identical.

## When NOT to use the kickoff prompt

- If the project is a simple one-off task (script, single component, throwaway prototype), this is overkill.
- If the user is pair-coding interactively and doesn't want the audit-first discipline (short tasks, exploratory work), respect that — neither the skill nor the mode is meant to be coercive.
