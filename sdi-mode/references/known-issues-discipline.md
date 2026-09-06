# KNOWN_ISSUES.md Discipline

`docs/KNOWN_ISSUES.md` is the append-only catalog of known bugs, security gaps, technical debt, and deferred fixes. It answers: "what do we know is wrong, but are not fixing in the current scope?"

Keep it separate from `docs/DECISIONS.md` (why a non-obvious choice was made), `docs/memory/YYYY-MM-DD.md` (what happened today), and the plan (what this work item will do). If an external issue tracker holds the execution queue, link it from `Status` or `Suggested fix scope`; this file stays the repo-local source of known problems.

## When to add an entry

Add a `KI-NNN` entry when all are true:

1. The issue is real enough to cite evidence (`file:line`, failing scenario, incident, review finding, reproducible behavior).
2. It pre-exists the round, or is outside the current work item's accepted scope.
3. It is a bug, security gap, data-correctness issue, production risk, documentation drift, or debt worth rediscovering later.
4. It is not already represented by an existing `KI-NNN`.

Vague suspicion goes in today's memory and is promoted here once evidence exists. IDs are a **global namespace across live branches**: measure the next free number when you write, never pre-allocate one in a plan.

## When to update an entry

- Starting a fix: `Status: **Scheduled**`, with the work item on a `Nota de status` line.
- Shipping a fix: `Status: **Resolved**`, with the commit and date on a note line.
- Partial fix: `Status: **Partially Mitigated**`, with what remains on a note line.
- Premise measured and false: `Status: **Invalid**`, with the measurement on a note line.
- More impact found: update `Blast radius` and cite the new evidence.

Never delete or renumber. An entry leaves the hot file only by being **archived with a stub**.

## Entry format

The **anchor comes immediately before the header**, the header is `### KI-NNN — title` with the ` — ` separator, and `Status` and `Severity` carry **only** the enum value. Those shapes are what tooling parses, so they are literal.

```markdown
<a id="ki-NNN"></a>
### KI-NNN — [short title, one line]
- **Status**: **Open**
- **Severity**: **P2**
- **Discovered**: YYYY-MM-DD, who/what surfaced it (work item / review / incident)
- **Blast radius**: who/what is affected and under what conditions
- **Repro**: `file:line` or a concrete reproducible scenario
- **Why deferred**: why it is not being fixed now
- **Fix trigger**: the condition that makes the fix urgent (incident, customer report, threshold, audit)
- **Suggested fix scope**: rough scope and estimate (minutes / hours / days / weeks)
```

`Status` takes **one** value: `Open`, `Scheduled`, `Partially Mitigated`, `Resolved`, `Invalid` (the entry's premise was measured and is false), or `Arquivada` (the text lives in the archive). `Severity` takes **only** `P0`, `P1`, `P2`, or `P3`. Anything that would qualify the value on the same line goes on a line of its own: `- **Nota de status**: …` or `- **Nota de severidade**: …`. That is what keeps a strict parser working over a file people write by hand.

**Size.** Per-entry character and line ceilings live in the project's doc lint (`scripts/docs_bounds.py` where the project has one). The numbers live there and are repeated in no document.

**Stub** — the second canonical form, written when the entry moves to `KNOWN_ISSUES_ARCHIVE.md`. Exactly these four contiguous lines, and nothing else:

```markdown
<a id="ki-NNN"></a>
### KI-NNN — [title, byte-identical to the archived one]
- **Status**: **Arquivada**
- **Arquivo**: status Open P3 em AAAA-MM-DD, texto completo em [KI-NNN](KNOWN_ISSUES_ARCHIVE.md#ki-NNN)
```

The stub's `status` repeats what the entry carried when it left, and severity appears only in the forms that require it.

## Archive policy

Archiving is **moving with a stub, never deleting** — the stub keeps the anchor, so every link from outside still resolves, and append-only stays true while the hot file stays readable.

- What leaves: entries whose `Status` is `Resolved` or `Invalid`, and `P3` entries whose `Status` is `Open`. What stays hot: `Scheduled`, `Partially Mitigated`, and `Open` from `P0` to `P2`.
- The entry moves whole, with the same anchor. Links inside it are rewritten to wherever the target lives after the move; links from outside keep working through the stub.
- An `## Index` line for the entry is **updated** to point at the archive; if there was none, none is created.
- Running it twice changes nothing, because a stub is skipped.

The framework states the policy; the project supplies the script that enforces it (`scripts/archive_known_issues.py` and its sibling for `DECISIONS.md` in a project that has them). The script is strict on purpose: an entry outside either canonical form stops it, by name, instead of being silently reshaped.

## Severity guide

- **P0** — system unavailable for users, or active data loss.
- **P1** — silent data corruption, security regression, credential leak, tenant/data isolation leak.
- **P2** — degraded UX, performance, or a correctness issue with a workaround or limited blast radius.
- **P3** — cleanup, documentation drift, refactor, low-impact debt.

## Bootstrap if missing

Older bundles may not have the file. Create it before the first round report with a header that states the append-only-with-lifecycle rule and the `Status` / `Severity` vocabularies, an `## Index` section (`No known issues yet.`), and an `## Entries` section. Do not restate the entry format in the file — it is here, and two copies drift.

When the first issue is added: assign the next sequential ID, replace the index placeholder with category headings linking to each entry, and keep resolved entries in the index — status lives inside the entry.

## Round behavior

- A KI added or updated during a round appears in the round report under "Known issues / technical debt updates" **and** as one line in `## Decisões desta rodada`.
- A review that surfaces a KI-worthy issue outside scope: add it before closing the checkpoint, or list the proposed entry and let the user judge severity/status.
- A work item that fixes a KI marks it `Scheduled` at kickoff and `Resolved` only once verification and commit evidence exist.
