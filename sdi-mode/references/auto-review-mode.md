# Auto-Review Mode

Use independent review when a work unit's reachable risk, production contract
or acceptance criterion warrants it. A checkpoint number alone does not. The
PM reads the work-item profile in plan §0, dispatches every scheduled reviewer
in parallel with the same packet, reconciles only after all finish, and owns the
final classification. Reviewers are fresh, read-only and non-persistent.

The canonical implementation/test proportionality rule is in `../SKILL.md`
§"Proportionality rule". This file projects the minimum review rubric needed by
a reviewer that cannot load the skill.

## Profile and failure handling

The PO chooses reviewer models, vendors, efforts and quantity once per work
item. Reuse that profile across attempts and resumes. Independent reviewers from
different vendors are recommended, never required and never a gate label.

If a scheduled reviewer cannot be invoked, hits a rate limit, times out or
returns unusable output, stop and give the PO the measured failure. The PO may
pause or select a replacement. Persist that replacement for the item unless the
PO limits it to one occurrence. Never substitute or shrink the profile silently.

Success for each reviewer requires an exit-zero run, a non-empty final artifact
and evidence that the target was read or grepped. A short well-formed PASS is
valid. A malformed/missing verdict is unusable output.

## Per-round commit convention

- Capture `BASE_SHA` before the round. Keep it fixed for every attempt.
- Engineer commit A is code-only: `round X/CN: <summary>`.
- PM commit B is report-only and names A's literal SHA:
  `round X/CN report: at HEAD <short-SHA>`.
- Fixes use new code/report commits; do not amend or squash.
- Loop close commits reviewer outputs and the final report as
  `round X/CN review artifacts: <verdict>`.

Before dispatch, `HEAD` contains A+B and the tree is clean except for the prompt
scratch file and this round's prior reviewer outputs. If unrelated/user-owned
changes exist, stop with the file list; do not review an ambiguous tree.

## Evidence policy

The Engineer runs the scoped existing tests/build/lint/typecheck and targeted
smoke justified by the change. The report records exact commands and results;
counts are required only when a runner or acceptance criterion makes them
meaningful. Reviewers judge whether that evidence proves the named contract and
may run targeted read-only-compatible checks. They do not demand a new test,
harness, census, gate or observability merely for symmetry or confidence.

A new automated test is justified only by an approved acceptance criterion or
a reachable path capable of silent material harm to data/access: loss,
overwrite, corruption, wrong association, disclosure or isolation failure.
Existing mandatory CI gates remain mandatory.

Binary-gate control example: `Verify tests pass` is not evidenceable. `Run
<existing command>; exit 0 and the named tenant-isolation scenario passes` is
binary and tied to a material contract. The example does not authorize a new
test or a count requirement.

## Always-escalate before dispatch

Stop for the PO before review when the round contains an unresolved blocker,
open product/architecture/scope choice, irreversible or production action,
lossy migration risk, unplanned external dependency, out-of-scope security
change, or required PRD/ARCHITECTURE deviation. A mechanical plan revision or a
routine decision/KI record does not create a gate by itself; the underlying
consequence decides.

## The loop

1. Confirm the Engineer evidence and commit pair; run the clean-state preflight.
2. Build one fixed packet and dispatch the profiled reviewers in parallel.
3. Validate every process/output, then merge the returned findings.
4. Deduplicate by consequence: same defect/risk at the same symbol or boundary
   is one finding even when reviewers cite nearby lines.
5. The PM measures reach and assigns the final mark using the matrix below.
6. Route a reachable mechanical code fix to the profiled Fix Engineer; the PM
   may correct its own factual paper trail. Re-review fixes with the same packet
   baseline and profile.
7. Stop for the PO on a decision, failed reviewer, failed fix, repeated root
   cause, or the cap. On PASS, link artifacts in the report and advance.

Do not open a new attempt solely to improve prose, a test instrument or optional
evidence. A non-blocking observation may be recorded with a concrete future
trigger; vague suspicion is omitted.

## Decision Bundle

For every finding record: final mark, class, location, concrete evidence,
measured reach, consequence and action. Group as mechanical fix, PO decision or
non-blocking recommendation. Apply independent mechanical fixes before pausing
on a coexisting decision when doing so cannot prejudge it.

## Marks and the verdict matrix

This is the framework's single normative verdict predicate. Plan review and
review prompts cite or copy this block; they do not invent a different rule.

<!-- marks-inline:start -->
**Mark each finding `[code]`, `[gate]` or `[docs]`; the reviewer proposes and the coordinator assigns the final mark after measuring reach.**

- `[code]` — a reachable defect in shipped behavior or the implementation contract, including security, tenant isolation, data integrity, API compatibility or migration safety.
- `[gate]` — a test, CI rule, lint, fixture or other verification instrument.
- `[docs]` — documentation or paper trail that describes the work.

A `[gate]` or `[docs]` finding blocks only when concrete evidence shows that it reveals a reachable product defect or material silent harm, breaks an existing mandatory gate, or invalidates the only evidence for an approved acceptance criterion. In the first case classify the underlying defect as `[code]`. Being a deliverable, template, plan or housekeeping text does not by itself promote the finding. Cosmetic prose, speculative defense and meta-instrumentation never block.

| Finding | Effect |
|---|---|
| Reachable `[code]` defect with a mechanical fix | **FAIL** |
| Open non-obvious product/architecture/scope decision | **ESCALATE** |
| Urgent material risk requiring PO action | **BLOCK** |
| `[gate]` / `[docs]` meeting the blocking predicate above | **FAIL** or **ESCALATE**, according to whether judgment is needed |
| Other instrumental/documental/advisory finding | Non-blocking; record only when it has a useful consequence or trigger |

An attempt is PASS when no finding meets a blocking row. Class labels organize findings; they do not override this predicate.
<!-- marks-inline:end -->

**Reach axis.** Measure an occurrence in the corpus, current execution or CI
path. Without a measurement, conservatively treat a plausible product defect as
reachable. A constructible anomaly outside canonical inputs is a future item
only when it has concrete evidence and a trigger.

## Loop cap

**Maximum 3 review attempts per round and 3 rounds of plan review.** This is the
only file that states those values. The cap and convergence rule also apply to
comprehensive closing review.

At the last allowed attempt without PASS, stop and hand the remaining findings
to the PO. Only the PO may authorize another attempt; record that authorization
and reason in `DECISIONS.md` first. If the same class and root cause at the same
symbol/boundary survives consecutive attempts, stop early: the fix is lazy or
the cause is misunderstood.

An attempt counts when it addresses a blocking reviewer finding or changes the
round's implementation. Correcting a typo/link/SHA in the PM report alone does
not consume an attempt.

## Round/diff reviewer prompt

Fill every placeholder and send this exact prompt to each profiled reviewer.

```text
You are an independent adversarial reviewer for [ROUND_ID].
Model/vendor/effort identity to report: [PROFILE_ENTRY].

Work read-only in [REPO_ROOT]. The reviewed baseline is [BASE_SHA] and HEAD is
the committed result. Read [ROUND_REPORT_PATH], [PLAN_PATH] §[PLAN_SECTIONS],
AGENTS.md or CLAUDE.md, and relevant DECISIONS/KNOWN_ISSUES entries. Prior
findings to verify: [PRIOR_FINDINGS].

Run `git diff [BASE_SHA]..HEAD`, `git status --short`, and targeted read/grep.
Verify report claims, real flow/contracts, unhappy paths and production
constraints. Prioritize: delivered functionality; silent material harm;
security/tenant/data/API/migration safety; reachable regression; report-vs-repo
misrepresentation. Verify every concrete symbol/path/count rather than trusting
the prose. You may run only read-only-compatible targeted checks.

Apply this proportionality projection: the implementation owes the smallest
change needed for the real flow and contracts. Do not demand abstraction,
refactor, instrumentation, hardening or a new test without a reachable defect,
material silent-harm path, approved acceptance criterion or existing mandatory
gate. Cosmetic, speculative and meta-instrument findings do not block.

Class findings as: 1 internal inconsistency; 2 contract mismatch; 3 missing
prerequisite; 4 unverifiable claim; 5 open decision; 6 architecture/convention;
7 other material risk; K fictitious concrete citation.

For each finding give mark, class, file:line/symbol, fact, evidence, consequence
and smallest fix. End with exactly:
TOTAL FINDINGS: N. By class: 1=a, 2=b, 3=c, 4=d, 5=e, 6=f, 7=g, K=k.
VERDICT: PASS | FAIL | ESCALATE | BLOCK

**Mark each finding `[code]`, `[gate]` or `[docs]`; the reviewer proposes and the coordinator assigns the final mark after measuring reach.**

- `[code]` — a reachable defect in shipped behavior or the implementation contract, including security, tenant isolation, data integrity, API compatibility or migration safety.
- `[gate]` — a test, CI rule, lint, fixture or other verification instrument.
- `[docs]` — documentation or paper trail that describes the work.

A `[gate]` or `[docs]` finding blocks only when concrete evidence shows that it reveals a reachable product defect or material silent harm, breaks an existing mandatory gate, or invalidates the only evidence for an approved acceptance criterion. In the first case classify the underlying defect as `[code]`. Being a deliverable, template, plan or housekeeping text does not by itself promote the finding. Cosmetic prose, speculative defense and meta-instrumentation never block.

| Finding | Effect |
|---|---|
| Reachable `[code]` defect with a mechanical fix | **FAIL** |
| Open non-obvious product/architecture/scope decision | **ESCALATE** |
| Urgent material risk requiring PO action | **BLOCK** |
| `[gate]` / `[docs]` meeting the blocking predicate above | **FAIL** or **ESCALATE**, according to whether judgment is needed |
| Other instrumental/documental/advisory finding | Non-blocking; record only when it has a useful consequence or trigger |

An attempt is PASS when no finding meets a blocking row. Class labels organize findings; they do not override this predicate.

Do not edit files or ask the PO. Your final response is the complete review
artifact and must not be empty.
```

## Dispatch mechanics

Use a native fresh subagent when it can honor the profile and read-only boundary.
Otherwise use the confirmed vendor-specific CLI recipes in
`roles-and-orchestration.md` §"Cross-tool recipes". The prompt is passed by
stdin, session persistence is disabled, model and effort are explicit, and
success is validated by exit code plus non-empty output. Do not infer success
from stderr and do not add a permission bypass.

## Comprehensive close

When the phase-wide risk or acceptance criteria justify it, review the full
phase from `PHASE_BASE_SHA`, splitting the packet by checkpoint if necessary.
The same profile, rubric, cap and blocking predicate apply. A PASS clears only
the review gate; any required live smoke still runs before the PM opens a PR.

## Report history

Link one row per scheduled reviewer/attempt to its artifact and record merged
outcome, blocking predicate, action and fix SHAs. Do not paste reviewer reports,
require a test-count census or call an authorized PO roster "degraded".
