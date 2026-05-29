# Memory Discipline

Spec-driven projects accumulate four distinct kinds of knowledge during implementation:

1. **Atemporal decisions** — non-obvious choices that hold until something changes them (library X over Y, deferred feature, accepted trade-off). These live in `DECISIONS.md`, append-only, numbered.

2. **Known wrongness** — bugs, security gaps, technical debt, and deferred fixes with concrete evidence. These live in `KNOWN_ISSUES.md`, append-only with lifecycle status.

3. **Datable session memory** — what was actually worked on, when, blockers active, next step, open questions still pending. These live in dated files under `docs/memory/`, indexed by `docs/MEMORY.md`.

4. **Per-work-item narrative** — the consolidated story of each *completed* work item: what was built, the checkpoints/rounds, review outcomes, test-count deltas, cross-references. This lives in `docs/WORK_LOG.md`, one `## <work item>` section per item, written at close. The **Work tracker** in `AGENTS.md` / `CLAUDE.md` is its one-line index.

Mixing these into a single file is a common failure pattern: durable rationale, known bugs, daily status, and per-item history blur together, and none stay searchable. Splitting them keeps each file useful — and keeps the Work tracker (read every session) from bloating into a wall of narrative.

## File layout

```
docs/
├── DECISIONS.md              # atemporal, append-only, numbered
├── KNOWN_ISSUES.md           # append-only issue/debt lifecycle catalog
├── WORK_LOG.md               # verbose per-work-item narrative; one ## section per item, at close
├── MEMORY.md                 # index — one line per dated entry
└── memory/
    ├── 2026-04-25.md         # one file per working day
    ├── 2026-04-26.md
    └── ...
```

(The Work tracker in `AGENTS.md` / `CLAUDE.md` at the repo root is the one-line index into `WORK_LOG.md` — see "What goes in `WORK_LOG.md`" below.)

`docs/memory/` and `docs/MEMORY.md` are the default. If a project deliberately keeps canonical docs at the repo root, keep `MEMORY.md` and `memory/` next to `DECISIONS.md` and `KNOWN_ISSUES.md` for symmetry.

## What goes in `DECISIONS.md`

(Already covered in [`decisions-log-format.md`](./decisions-log-format.md). Brief reminder:)

- Choosing one library / framework / service over another with non-obvious reasons.
- Deferring a feature to a later phase.
- Accepting a trade-off.
- Resolving a plan-vs-repo divergence.
- Deviating from a convention.

**Atemporal.** A DECISIONS entry stands until explicitly superseded by a later entry. It does not date with time alone.

## What goes in `KNOWN_ISSUES.md`

Concrete known problems that are not being fixed in the current scope:

- Production bugs, data correctness risks, security gaps, credential leaks, tenant isolation risks.
- Tech debt with evidence and a reason to defer.
- Documentation drift or architecture/repo mismatch that is real but not worth fixing in this work item.
- Status lifecycle when a known issue becomes scheduled, partially mitigated, or resolved.

Use `KI-NNN` IDs. Never delete or renumber. See `known-issues-discipline.md`.

## What goes in `docs/memory/YYYY-MM-DD.md`

A daily memory file captures the **state** of work on that day:

- **Date and active context** — phase, current round, last completed checkpoint
- **What was worked on** — round reports posted, files touched, commits/PRs (link if useful)
- **Blockers** — anything currently preventing progress, with the question or action needed to unblock
- **Open questions for the user** — questions waiting for an answer
- **Next planned step** — what you intend to do next
- **Notable observations** — things you noticed but didn't act on (potential follow-ups, suspected bugs, code smells)

**Datable.** A memory entry is a snapshot of *that moment*. It does not get edited later; subsequent days get their own files.

### Format

```markdown
# Memory — 2026-04-25

**Phase:** 1 — Sources & ingestion
**Current round:** Round B (Sources CRUD, API only)
**Last checkpoint passed:** Checkpoint 2 (Core domain logic)

## Worked on today

- Round B opened: `src/lib/sources/service.ts`, `validation.ts`, route handlers under `src/app/api/sources/`.
- 25 unit tests + 23 integration tests added; all passing.
- DECISIONS entries #28, #29, #30, #31 written.
- KNOWN_ISSUES KI-004 updated to `Resolved` after commit `[sha]`.

## Blockers

(none active)

## Open questions for user

1. `test-webhook` standalone vs sharing `defaultIngestDeps` — recommended standalone, awaiting confirmation.

## Next planned step

Checkpoint 3 review, then propose Round C (UI for Sources + Leads list).

## Notable observations

- `AGENTS.md` lacks the `requireRoleApi()` vs `requireRole()` distinction — propose adding to project-specific conventions during housekeeping.
- Smoke test against [local DB service] uncovered a possible race in dedup; gather evidence next session, then either add `KNOWN_ISSUES.md` entry or dismiss.
```

Length: 30–80 lines per day. Longer means you're putting decisions in here that should be in DECISIONS.md.

## What goes in `docs/MEMORY.md`

A flat **index** of dated entries. One line per file, ~150 chars max. Newest at the top.

```markdown
# MEMORY

Index of `docs/memory/` daily entries. Newest first. Links inside `docs/MEMORY.md` are relative to `docs/`, so they point to dated files like `memory/2026-04-26.md`.

- [2026-04-26](memory/2026-04-26.md) — Round B closed; Round C UI started; pricing copy still pending from PO
- [2026-04-25](memory/2026-04-25.md) — Round B opened, Sources CRUD + tests; DECISIONS #28-#31 written
- [2026-04-24](memory/2026-04-24.md) — Phase 1 audit + revision note r2; Checkpoint 1 passed
- [2026-04-23](memory/2026-04-23.md) — Phase 0 scaffolding closed; project fact sheet initial fill-in
```

`docs/MEMORY.md` itself stays under ~200 lines (with truncation when older entries roll off into archives if needed). It's a finder, not the full content.

## What goes in `WORK_LOG.md`

The consolidated narrative of each **completed work item** — one `## <work item>` section, written at end-of-phase housekeeping (sdi-mode Step 8), in the same order as the Work tracker rows (chronological, newest appended at the end). Each section holds what used to bloat the tracker's `Notes` cell:

- What was built (modules, behavior), the checkpoints/rounds, adversarial-review outcomes.
- Test-count deltas, smoke results, PR links, fix commit SHAs.
- Cross-references: `DECISIONS #N`, `KI-NNN`, plan revision notes — pointing into them, not pasting their content.

**Per-item and consolidated-at-close**, not per-day. That is the difference from `docs/memory/`: memory is the running daily breadcrumb ("today I closed omie-integration; see WORK_LOG"); the `WORK_LOG.md` section is the durable, consolidated story of that item, written once it closes.

**Not the canonical source of detail, and not loaded every session.** The authoritative record stays in the plan, `DECISIONS.md`, `KNOWN_ISSUES.md`, and `docs/memory/`; `WORK_LOG.md` consolidates and points into them. It is read on demand, not in the standard pre-phase reading order. Keep each section's `Type` / `Status` / `Date` matching its Work tracker row so the index and the narrative never disagree.

Format and seed structure: `../../mvp-architect/references/core-templates/work-log-template.md`.

## When to write a memory entry

Write a daily memory entry **at the end of each working session** on the project:

- After a round report ships.
- After resolving blockers that previously held you up.
- After end-of-phase housekeeping closes a phase.
- Before stopping for the day or handing off context.

If a working day produces multiple meaningful events, **append** to that day's file (don't create a new one). The file represents the day, not a single session.

If a working day produces no meaningful events (all spent on review of someone else's work, no implementation), skip the file. Empty memory is worse than no memory.

## What NOT to write here

- **Decisions** — those go in `DECISIONS.md`.
- **Known bugs/debt/security gaps with evidence** — those go in `KNOWN_ISSUES.md`.
- **Consolidated per-work-item narrative** — the full story of a closed item goes in `WORK_LOG.md` (one section per item), not duplicated into daily memory. Memory just points: "omie-integration closed; see WORK_LOG".
- **Plan changes** — those go as revision notes in the plan itself.
- **Detailed code commentary** — the code and round report cover that.
- **Apologies, hedging, or self-narration** — be matter-of-fact.
- **Framework-level disciplines** like verify-before-claim or plan-writing patterns — those live in the skill files (`auto-review-mode.md`, `next-phase-planning.md`, etc.), not in project memory. Memory captures project-specific facts; disciplines are skill-level conventions.

## Cross-references

Memory entries should reference, not duplicate, other docs:

- "DECISIONS #28 written" — don't paste the entry; link to it
- "KI-004 marked Resolved" — don't paste the known-issue entry; link to it
- "Round B report posted" — don't paste the report; reference the date or commit
- "Checkpoint 2 passed" — don't list every gate; reference the report

Memory is the **breadcrumb trail**, not the canonical record.

## Reading memory

When picking up a project after a break, read `docs/MEMORY.md` index first, then the most recent 2–3 daily entries. This re-establishes context faster than re-reading the full implementation plan, because memory captures *where things actually are*, not where the plan said they'd be.

When auditing whether the plan still matches reality, scan the past week of memory entries for `Notable observations` — those often surface drift that hasn't yet hit DECISIONS.md.

## End-of-phase memory housekeeping

At phase close, sweep memory:

- Are there `Open questions` from earlier days still pending? Either answer them now or convert to a Phase N+1 carry-over note in the plan.
- Are there `Notable observations` that became real (a suspected bug confirmed, a follow-up turned into work)? Convert to DECISIONS, KNOWN_ISSUES, or to a plan revision note.
- Should the older daily files be archived? If the `docs/memory/` directory has more than a few months of entries, consider archiving older years into `docs/memory/archive/YYYY/`. Only do this when it's actively cluttering navigation.

## Why this discipline matters

**Atemporal vs datable** is a real distinction:

- A reviewer reading `DECISIONS.md` 6 months from now wants to find "why did we choose Inngest over Temporal?" — they don't want to wade through "Tuesday, started Round B."
- A maintainer reading `KNOWN_ISSUES.md` wants "what do we know is broken?" — not a mix of rationale and daily notes.
- A new contributor reading `docs/MEMORY.md` wants to know what was actually happening last week, not search through 60 atemporal entries hoping the breadcrumb is in there.
- A user resuming after vacation wants to read the most recent 3 daily entries and instantly know what's next, what's blocked, what's pending — not infer it from the union of plan + decisions.

Without the split, all three surfaces degrade. With it, each stays useful.
