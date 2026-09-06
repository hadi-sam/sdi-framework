# KNOWN_ISSUES.md Discipline

`docs/KNOWN_ISSUES.md` is the append-only catalog of known bugs, security gaps, debt and deferred fixes: "what do we know is wrong but are not fixing now?" Keep it apart from `docs/DECISIONS.md` (why a choice was made), `docs/memory/` (what happened today) and the plan (what this item will do). If an external issue tracker holds the execution queue, link it from `Status` or `Suggested fix scope`; this file stays the repo-local source of known problems.

## When to add, when to update

Add a `KI-NNN` when all four hold: citable evidence exists (`file:line`, failing scenario, incident, review finding); it pre-exists the round or falls outside scope; it is a bug, security gap, correctness issue, production risk, doc drift or debt worth rediscovering; and no entry covers it. Vague suspicion stays in today's memory until evidence exists. IDs are a **global namespace across live branches**: measure the next free number at write time, never pre-allocate one in a plan.

Starting a fix → `**Scheduled**`, work item on a `Nota de status` line; shipping → `**Resolved**`, commit and date; partial → `**Partially Mitigated**`, what remains; premise measured false → `**Invalid**`, the measurement. More impact found → `Blast radius` gets the new evidence. **Never delete or renumber**; an entry leaves the hot file only archived with a stub.

## Entry format

The **anchor comes immediately before the header**, the header is `### KI-NNN — title` with the ` — ` separator, and `Status` and `Severity` carry **only** the enum value — the shapes tooling parses, so they are literal.

```markdown
<a id="ki-NNN"></a>
### KI-NNN — [short title, one line]
- **Status**: **Open**
- **Severity**: **P2**
- **Discovered**: YYYY-MM-DD, who/what surfaced it (work item / review / incident)
- **Blast radius**: who/what is affected and under what conditions
- **Repro**: `file:line` or a concrete reproducible scenario
- **Why deferred**: why it is not being fixed now
- **Fix trigger**: what makes the fix urgent (incident, customer report, threshold, audit)
- **Suggested fix scope**: rough scope and estimate (minutes / hours / days / weeks)
```

`Status` takes **one** of `Open`, `Scheduled`, `Partially Mitigated`, `Resolved`, `Invalid` (premise measured false), `Arquivada` (text in the archive); `Severity` takes **only** `P0`–`P3`. Anything qualifying a value goes on its own line — `- **Nota de status**: …`, `- **Nota de severidade**: …` — which keeps a strict parser working over a hand-written file. **Size:** the per-entry character and line ceilings live in the project's doc lint (`scripts/docs_bounds.py`), repeated in no document.

**Stub** — the second canonical form, written when the entry moves to `KNOWN_ISSUES_ARCHIVE.md`. Exactly these four contiguous lines:

```markdown
<a id="ki-NNN"></a>
### KI-NNN — [title, byte-identical to the archived one]
- **Status**: **Arquivada**
- **Arquivo**: status Open P3 em AAAA-MM-DD, texto completo em [KI-NNN](KNOWN_ISSUES_ARCHIVE.md#ki-NNN)
```

The stub's `Arquivo` line repeats the status the entry carried when it left.

## Archive policy

Archiving is **moving with a stub, never deleting** — the stub keeps the anchor, so outside links resolve and append-only stays true while the hot file stays readable. **Leaves:** `Resolved`, `Invalid`, `Open` `P3`. **Stays hot:** `Scheduled`, `Partially Mitigated`, `Open` `P0`–`P2`. The entry moves whole with the same anchor; links inside it are rewritten to wherever the target now lives, and an existing `## Index` line is **updated** to point at the archive (none is created if there was none). Running the archiver twice changes nothing, because a stub is skipped.

The framework states the policy; the project supplies the script (`scripts/archive_known_issues.py` and its `DECISIONS.md` sibling), strict on purpose: an entry outside either canonical form stops it by name instead of being silently reshaped.

## Severity guide

**P0** system down or active data loss · **P1** silent corruption, security regression, credential or tenant-isolation leak · **P2** degraded UX or performance, or a correctness issue with a workaround or limited blast radius · **P3** cleanup, doc drift, refactor, low-impact debt.

## Bootstrap, and round behaviour

Older bundles may lack the file. Create it before the first round report with a header stating the append-only-with-lifecycle rule and the two vocabularies, an `## Index` (`No known issues yet.`) and an `## Entries` section. **Do not restate the entry format in it** — it is here, and two copies drift. With the first issue, assign the next ID and replace the placeholder with category headings; resolved entries stay indexed, because status lives in the entry.

A KI added or updated in a round appears in the round report under "Known issues / technical debt updates" **and** as one line in `## Decisões desta rodada`. A review that surfaces one outside scope: add it before closing the checkpoint, or propose it and let the user judge severity and status. A work item fixing a KI marks it `Scheduled` at kickoff and `Resolved` only once verification and commit evidence exist.
