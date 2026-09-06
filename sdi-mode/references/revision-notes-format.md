# Revision Notes Format

Revision notes mark a plan's evolution in the plan itself, so it stays current instead of becoming a stale snapshot of the original intent.

## When to add one

- The audit of the plan against the repo produced real changes.
- Mid-phase discovery showed a plan section is wrong or incomplete.
- Scope changed mid-phase (customer requirement, tech decision, trade-off reversal).

Not for typos or clarifications — just fix those. Not for a new `DECISIONS.md` or `KNOWN_ISSUES.md` entry that doesn't change the plan. Rule of thumb: if someone reading the plan in six months would be confused by the gap between what's written and what was built, add a note.

## Format

Notes live at the very top of the plan, above the first `##` section. They stack, newest on top. **Never delete a prior note.**

The header is `(rN, AAAA-MM-DD)` — number **and** date, one form only, no variants:

```markdown
# Implementation Plan — [Title]

> **Revision note (r3, 2026-04-28):** [trigger — audit / mid-phase discovery / scope change]. [N adjustments]:
> 1. §X.Y [the specific change, one line].
> 2. §A.B [the specific change, one line].
>
> **Revision note (r2, 2026-04-24):** [trigger]. [N adjustments]:
> 1. …
```

Each note is a **revision number and trigger**, then a **numbered list of specific one-line changes**. No personal justification; no redundancy with a `DECISIONS.md` entry that already explains the change — reference it; no speculation, because a change you are unsure of gets discussed before it enters the plan.

## Limits

- **At most 6 revision notes in a plan, each within the per-note byte ceiling** in the project's doc lint (`scripts/docs_bounds.py` where the project has one; the numbers live there and are repeated in no document).
- **On the seventh, consolidation is mandatory**: the earlier notes collapse into a single consolidation line saying what the plan absorbed and over which revisions, and the new note takes its place on top. Consolidating is not deleting — the detail of each change is already in the plan sections it changed, in `DECISIONS.md`, and in the round reports.
- A plan that keeps needing notes stopped describing the work; propose replanning rather than a seventh note.

## Example

> **Revision note (r2, 2026-04-24):** plan audited against the Phase 0 repo. 3 adjustments:
> 1. §2.1 removed the FK to a table that doesn't exist yet; plain id column instead, FK when the table lands.
> 2. §2 isolation examples switched from an invented helper to the real one in the repo.
> 3. §9.2 test-webhook UI switched from a heavy editor dependency to a plain textarea.

## Reading and housekeeping

Read the notes in order when starting a phase that touches the same area, when auditing the plan, or when onboarding someone — they are the timeline of how the plan evolved. At phase close, verify each note references a change that actually landed, not one discussed and dropped.
