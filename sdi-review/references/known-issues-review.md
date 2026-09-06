# Known Issues Review Rules

`docs/KNOWN_ISSUES.md` is the append-only catalog for known bugs, security gaps, technical debt, and deferred fixes. During review, use it to avoid rediscovering the same out-of-scope problem and to preserve issues that are real but not part of the current fix.

## What to check

- If the plan or round claims to fix `KI-NNN`, verify the entry status is updated or the plan explicitly says it will update status during housekeeping.
- If you find a pre-existing bug/security gap/tech debt item outside the reviewed scope, check whether it is already listed.
- If it is not listed, add a finding that includes a ready-to-paste KI entry. If the review session is allowed to edit docs, append the entry to `docs/KNOWN_ISSUES.md` and mention the new ID in the review report.
- Do not duplicate an existing issue. Update blast radius/severity/status instead.

## Entry format

Canonical form — the anchor immediately before the header, `### KI-NNN — title` with the ` — ` separator, `Status` and `Severity` carrying **only** the enum value, and any qualifier on its own `Nota de status` / `Nota de severidade` line — in [`sdi-mode/references/known-issues-discipline.md`](../../sdi-mode/references/known-issues-discipline.md) §"Entry format". This file is a review reference, not a seed: it points at the form instead of keeping a second copy that drifts. A ready-to-paste entry proposed by a review uses that form; an entry-like header outside it is sliced by nobody — neither the project's doc lint nor the archiver.

## Verdict guidance

- A plan/round that forgets to update a `KI-NNN` it claims to fix is a normal finding.
- A newly discovered P0/P1 issue, or any decision to defer a high-severity issue, should usually be `RETHINK`.
- A P2/P3 out-of-scope issue can be `SHIP` only if it is cataloged in `KNOWN_ISSUES.md` or included as an exact proposed KI entry in the review report.
