# Memory Discipline

Spec-driven projects accumulate four distinct kinds of knowledge:

1. **Atemporal decisions** — non-obvious choices that hold until something changes them: `docs/DECISIONS.md`, append-only, numbered. A decision stands until explicitly superseded; it does not age with time alone.
2. **Known wrongness** — bugs, security gaps, debt and deferred fixes with evidence: `docs/KNOWN_ISSUES.md`, append-only with a lifecycle status (`known-issues-discipline.md`).
3. **Datable session memory** — what was worked on, what is blocked, what is next: dated files under `docs/memory/`, indexed by `docs/MEMORY.md`.
4. **Per-work-item narrative** — the story of each *completed* item: `docs/WORK_LOG.md`, one `## <work item>` section, written at close. Its index is the fact sheet's **Work tracker** where the project has one; where it doesn't, the index is the `docs/plans/` directory.

Mixing them into one file is a common failure: rationale, bugs, daily status and per-item history blur together and none stay searchable. Splitting them keeps each useful — and keeps whatever is read every session from bloating into a wall of narrative.

The layout is `docs/DECISIONS.md`, `docs/KNOWN_ISSUES.md`, `docs/WORK_LOG.md`, `docs/MEMORY.md` and one file per working day under `docs/memory/`. A project that keeps canonical docs at the repo root keeps these beside `DECISIONS.md` and `KNOWN_ISSUES.md`.

## What goes in `docs/memory/YYYY-MM-DD.md`

The **state** of the work that day: active context (phase, round, last checkpoint passed); what was worked on (reports posted, files touched, commits/PRs); blockers with the question or action needed to clear each; open questions waiting on the user; the next planned step; and notable observations — what you noticed and did not act on, where a suspected bug lives until it earns a `KNOWN_ISSUES.md` entry.

**Datable.** An entry is a snapshot of that moment, not edited later; the next day gets its own file.

The format is a `# Memory — YYYY-MM-DD` title carrying phase, round and last checkpoint, then `Worked on today`, `Blockers`, `Open questions for user`, `Next planned step`, `Notable observations`.

**Length** is a per-day line ceiling in the project's doc lint (`scripts/docs_bounds.py`); the number lives there. Longer means you are putting decisions here that belong in `DECISIONS.md`.

## What goes in `docs/MEMORY.md`

A flat **index**: one line per file, newest at the top, with a per-line character ceiling in the project's doc lint (the number lives there). It is **hand-maintained** — nothing generates it — so a new entry means a new line, written the same day.

A line is `- [YYYY-MM-DD](memory/YYYY-MM-DD.md) — one-line hook of what changed`, links relative to `docs/`. It is a finder, not the content: when it outgrows being scannable, older entries move to an archive file kept verbatim and the index keeps only what is still worth finding.

## What goes in `WORK_LOG.md`

Seed: `../../mvp-architect/references/core-templates/work-log-template.md`.

The consolidated narrative of each **completed work item** — one `## <work item>` section, written at end-of-phase housekeeping (Step 8), chronological, newest at the end. Each holds the detail that has no business in a one-line index: what was built, the checkpoints and rounds, review outcomes, test-count deltas, smoke results, PR links, fix commit SHAs, and cross-references to `DECISIONS #N`, `KI-NNN` and revision notes — pointing into them, never pasting them.

**Per-item and consolidated at close**, not per-day: memory is the daily breadcrumb ("today I closed omie-integration; see WORK_LOG"), and this section is the durable story.

**Size.** Each section has a byte ceiling in the project's doc lint; the number lives there. What exceeds it does **not** go into another item's section and does not go back into the daily entry: it goes into a **new** `## <key> — adendo YYYY-MM-DD`, born under the normal ceiling. Overflow from a frozen target never lands on another frozen target.

**Not the canonical source of detail, and not loaded every session.** The authoritative record stays in the plan, `DECISIONS.md`, `KNOWN_ISSUES.md` and `docs/memory/`; this file consolidates and points into them, read on demand.

## When to write, and what not to write

Write a daily entry **at the end of each working session** — after a round report ships, after a blocker clears, after housekeeping closes a phase, or before handing off. A day with several events gets **appends to that day's file**, not a new one, and appending happens **within the day's ceiling**: when the day would overflow, the overflow goes into the closing item's `WORK_LOG.md` section, never into a second file for the same date — a ceiling a second file can dodge is not a ceiling. A day with nothing meaningful gets no file.

Not here: **decisions** (`DECISIONS.md`), **known wrongness with evidence** (`KNOWN_ISSUES.md`), the **per-item narrative** (`WORK_LOG.md` — memory just points at it), **plan changes** (revision notes), code commentary, apologies, and **framework-level disciplines** like verify-before-claim, which live in the skill files. Memory captures project facts; disciplines are skill conventions. And memory **references, never duplicates**: "DECISIONS #28 written", "KI-004 marked Resolved" — a breadcrumb trail, not the canonical record.

## Reading, and end-of-phase sweep

Picking a project back up: read the `docs/MEMORY.md` index, then the two or three most recent entries — faster than re-reading the plan, because memory captures where things *are*, not where the plan said they would be. Auditing the plan against reality: scan the past week's `Notable observations`, where drift surfaces before it reaches `DECISIONS.md`.

At phase close: answer or carry forward every pending `Open question`; convert every `Notable observation` that became real into a DECISIONS entry, a KNOWN_ISSUES entry or a revision note; archive older daily files into `docs/memory/archive/YYYY/` only when the directory clutters navigation.
