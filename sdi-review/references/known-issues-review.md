# Known Issues Review Rules

`docs/KNOWN_ISSUES.md` is the append-only catalog for known bugs, security gaps, technical debt, and deferred fixes. During review, use it to avoid rediscovering the same out-of-scope problem and to preserve issues that are real but not part of the current fix.

## What to check

- If the plan or round claims to fix `KI-NNN`, verify the entry status is updated or the plan explicitly says it will update status during housekeeping.
- If you find a pre-existing bug/security gap/tech debt item outside the reviewed scope, check whether it is already listed.
- If it is not listed, add a finding that includes a ready-to-paste KI entry. If the review session is allowed to edit docs, append the entry to `docs/KNOWN_ISSUES.md` and mention the new ID in the review report.
- Do not duplicate an existing issue. Update blast radius/severity/status instead.

## Entry format

Canonical form — the anchor immediately before the header, `### KI-NNN — title` with the ` — ` separator, `Status` and `Severity` carrying **only** the enum value, and any qualifier on its own `Nota de status` / `Nota de severidade` line — in [`sdi-mode/references/known-issues-discipline.md`](../../sdi-mode/references/known-issues-discipline.md) §"Entry format". This file is a review reference, not a seed: it points at the form instead of keeping a second copy that drifts. A ready-to-paste entry proposed by a review uses that form; an entry-like header outside it is sliced by nobody — neither the project's doc lint nor the archiver.

## What severity feeds into the verdict

These are **inputs to the matrix**, not verdicts: the bottom line is read off [`sdi-mode/references/auto-review-mode.md`](../../sdi-mode/references/auto-review-mode.md) §"Marks and the verdict matrix", never derived here.

- A plan/round that forgets to update a `KI-NNN` it claims to fix is a normal finding, classed like any other.
- A newly discovered P0/P1 issue, or a decision to defer a high-severity one, is the **urgent** class 7 the matrix routes — mark it urgent and let the matrix decide.
- A P2/P3 out-of-scope issue is non-urgent class 7: it never fails a round on its own. What the review owes is the entry — already catalogued in `KNOWN_ISSUES.md`, or an exact proposed one in the report.
