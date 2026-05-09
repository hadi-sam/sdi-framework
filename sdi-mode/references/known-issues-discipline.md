# KNOWN_ISSUES.md Discipline

`docs/KNOWN_ISSUES.md` is the append-only catalog for known bugs, security gaps, technical debt, and deferred fixes. It answers: "what do we know is wrong, but are not fixing in the current scope?"

Keep it separate from:

- `docs/DECISIONS.md` - why a non-obvious choice was made.
- `docs/memory/YYYY-MM-DD.md` - what happened today and what is blocked.
- `docs/IMPLEMENTATION_PLAN_*.md` - what this work item will do.

## When to add an entry

Add a `KI-NNN` entry when all are true:

1. The issue is real enough to cite evidence (`file:line`, failing scenario, incident, review finding, or reproducible behavior).
2. It pre-exists the current round or is outside the current work item's accepted scope.
3. It is a bug, security gap, data correctness issue, production risk, documentation drift, or tech debt worth rediscovering later.
4. It is not already represented by an existing `KI-NNN`.

Do not create entries for vague suspicion. Put weak observations in today's memory; promote them to `KNOWN_ISSUES.md` once evidence exists.

## When to update an entry

- Starting a fix: change or append `Status: Scheduled (work item ref)`.
- Shipping a fix: change or append `Status: Resolved (commit ref + YYYY-MM-DD)`.
- Finding more impact: update `Blast radius` and mention the new evidence.
- Partial fix: set `Status: Partially Mitigated (what remains)`.

Never delete or renumber entries. Resolved issues stay in the file.

## Entry format

```markdown
## KI-NNN - Short title

- **Discovered:** YYYY-MM-DD, who/what surfaced it (work item / review / incident)
- **Severity:** P0 (production-down) | P1 (silent data corruption / security) | P2 (degraded UX, scope-limited) | P3 (cleanup, low blast radius)
- **Blast radius:** who/what is affected and under what conditions
- **Repro / evidence:** file:line or concrete reproducible scenario
- **Why deferred:** why it is not fixed now
- **Fix trigger:** condition that makes the fix urgent (incident, customer report, threshold, audit)
- **Suggested fix scope:** rough scope and estimate (minutes / hours / days / weeks)
- **Status:** Open | Scheduled (work item ref) | Partially Mitigated (description) | Resolved (commit ref + date)
```

## Severity guide

- **P0** - system unavailable for users or active data loss.
- **P1** - silent data corruption, security regression, credential leak, tenant/data isolation leak.
- **P2** - degraded UX, performance issue, or correctness issue with known workaround or limited blast radius.
- **P3** - cleanup, documentation drift, refactor, or low-impact tech debt.

## Bootstrap if missing

Older SDI bundles may not have `docs/KNOWN_ISSUES.md`. If missing, create it before the first round report using this scaffold:

```markdown
# Known Issues & Technical Debt

> Append-only catalog of known production bugs, security gaps, technical debt, and deferred fixes. Single source of truth for "what we know is wrong".
>
> **Append-only with lifecycle:** entries are not deleted when fixed. Update the final `Status` line to `Resolved (commit X, YYYY-MM-DD)` or append a new status note so historical context remains.
>
> **When to create a new entry:** during any work, if you discover a pre-existing bug, technical debt item, security gap, or deferred fix that does not fit the current scope, add it here instead of leaving it in a plan, memory entry, or chat.
>
> **When to update an existing entry:** when a fix is scheduled (`Status: Scheduled (work item Y)`), when a fix ships (`Status: Resolved (commit Z, YYYY-MM-DD)`), or when new evidence changes severity/blast radius.
>
> **Do not duplicate with:**
> - `DECISIONS.md` - deliberate decisions and rationale. Decisions may reference `KI-NNN` when they defer or accept a known issue.
> - `ARCHITECTURE.md` - current intended architecture. If architecture says how the system should work but reality is broken, the issue lives here.
> - `MEMORY.md` and `memory/YYYY-MM-DD.md` - dated work state. Memory may mention that a KI was found or updated; the durable entry lives here.
> - Issue trackers - execution queues. If an external issue exists, link it from `Status` or `Suggested fix scope`; this file remains the repo-local source of known problems.

## Format per entry

## KI-NNN - Short title

- **Discovered:** YYYY-MM-DD, who/what surfaced it (work item / review / incident)
- **Severity:** P0 (production-down) | P1 (silent data corruption / security) | P2 (degraded UX, scope-limited) | P3 (cleanup, low blast radius)
- **Blast radius:** who/what is affected and under what conditions
- **Repro / evidence:** file:line or concrete reproducible scenario
- **Why deferred:** why it is not fixed now
- **Fix trigger:** condition that makes the fix urgent (incident, customer report, threshold, audit)
- **Suggested fix scope:** rough scope and estimate (minutes / hours / days / weeks)
- **Status:** Open | Scheduled (work item ref) | Partially Mitigated (description) | Resolved (commit ref + date)

## Status legend

- **Open** - known, no work scheduled.
- **Scheduled** - formal work item allocated; reference the plan or issue tracker.
- **Partially Mitigated** - partial fix in production; describe what remains.
- **Resolved** - fixed in production; keep the entry for history.

## Severity legend

- **P0** - system unavailable for users or active data loss.
- **P1** - silent data corruption, security regression, credential leak, tenant/data isolation leak.
- **P2** - degraded UX, performance issue, or correctness issue with known workaround or limited blast radius.
- **P3** - cleanup, documentation drift, refactor, or low-impact tech debt.

## Index

No known issues yet.

When the first issue is added:

1. Assign the next sequential ID (`KI-001`, `KI-002`, ...). Never reuse or renumber IDs.
2. Replace this placeholder with category headings and links to each entry.
3. Add the full entry below the relevant category section.
4. Keep resolved entries in the index; status lives inside the entry.

## Entries

(none yet)
```

## Round behavior

- If you add or update a KI entry during a round, mention it in the round report under "Known issues / technical debt updates".
- If a review surfaces a KI-worthy issue outside scope, add it before closing the checkpoint, or explicitly list the proposed entry and wait for user approval if severity/status requires judgment.
- If a work item fixes a KI, mark it `Scheduled` at kickoff/planning time and `Resolved` only after verification and commit evidence exist.
