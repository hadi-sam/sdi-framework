# Known Issues Review Rules

`docs/KNOWN_ISSUES.md` is the append-only catalog for known bugs, security gaps, technical debt, and deferred fixes. During review, use it to avoid rediscovering the same out-of-scope problem and to preserve issues that are real but not part of the current fix.

## What to check

- If the plan or round claims to fix `KI-NNN`, verify the entry status is updated or the plan explicitly says it will update status during housekeeping.
- If you find a pre-existing bug/security gap/tech debt item outside the reviewed scope, check whether it is already listed.
- If it is not listed, add a finding that includes a ready-to-paste KI entry. If the review session is allowed to edit docs, append the entry to `docs/KNOWN_ISSUES.md` and mention the new ID in the review report.
- Do not duplicate an existing issue. Update blast radius/severity/status instead.

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

## Verdict guidance

- A plan/round that forgets to update a `KI-NNN` it claims to fix is a normal finding.
- A newly discovered P0/P1 issue, or any decision to defer a high-severity issue, should usually be `ESCALATE`.
- A P2/P3 out-of-scope issue can be `PASS` only if it is cataloged in `KNOWN_ISSUES.md` or included as an exact proposed KI entry in the review report.
