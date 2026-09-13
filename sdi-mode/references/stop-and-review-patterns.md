# Stop-and-Review Patterns

Checkpoints exist at independent boundaries of risk, decision or reviewable
delivery. They are not a fixed ceremony. Audit-first and housekeeping remain
responsibilities on every item, but a small, low-risk item may combine their
reports with implementation in one round.

## Binary, proportional gates

A gate is binary and must prove an acceptance criterion, a real production
constraint or a required project/CI check. Do not add a gate to prove an
optional instrument, and do not keep an empty checkpoint. A generic request for
more coverage, robustness or evidence is not a gate until tied to reachable
behavior or a named constraint.

User gates apply to open product/architecture/scope decisions, irreversible or
production actions, migrations with material risk and other concrete material
risk. Audit findings that contain none of these may proceed under the approved
plan; audit must still finish before writing. Combining reports never bypasses a
required user gate.

Independent review is selected for a unit whose risk or contract warrants it;
it does not fire solely because a checkpoint number exists. When selected, use
`auto-review-mode.md`. The review cap remains canonical there.

## Adaptable checkpoint map

Use only the rows that represent real boundaries and rename the middle rows to
fit the work item.

### Foundation / audit

**Deliver:** plan-vs-repo audit, resolved blockers, explicit open decisions,
material divergences and concrete out-of-scope known issues.

**Possible gates (include only when applicable):**

- [ ] Every blocker resolved or explicitly waived by the PO.
- [ ] Every open decision answered before dependent work.
- [ ] Risky migration/dependency/production action explicitly approved.
- [ ] Material divergence recorded in the correct canonical artifact.

### Core behavior

**Deliver:** the smallest domain behavior needed by the plan. Types, schemas,
tests and validation are included only when required by the behavior, a material
silent-harm path or an approved acceptance criterion.

**Possible gates:**

- [ ] In-scope behavior works against its real contract.
- [ ] Authorized checks pass with exact command/result evidence.
- [ ] No reachable security, tenant, data-integrity or compatibility regression.

### Integration / external effects

Use when the item crosses an API, queue, datastore or third-party boundary.

**Possible gates:**

- [ ] The in-scope handler or worker satisfies the named contract.
- [ ] Required retry/idempotency/migration safety is preserved.
- [ ] Existing mandatory CI checks and targeted smoke pass.
- [ ] Observability required for a reachable silent failure exists.

### UI

Use only when the work item has a user-facing surface.

**Possible gates:**

- [ ] The in-scope flow is reachable and matches the approved behavior.
- [ ] Material loading/error/accessibility states for that flow work.
- [ ] The scoped walkthrough or existing regression check passes.

### Housekeeping / close

**Deliver:** factual evidence links, required canonical-doc updates, known-issue
lifecycle changes, short `WORK_LOG` close and the next pointer.

**Possible gates:**

- [ ] Every acceptance criterion links to sufficient evidence.
- [ ] Changed project facts and structures match the repo.
- [ ] Decisions and known issues touched by the item have honest status.
- [ ] Relevant mandatory CI gates and scoped checks pass.
- [ ] Required independent review passes under the production-first matrix.
- [ ] Required live smoke passes before the PM opens a PR.

## Emergency stop

Stop immediately for evidence of a security breach, data loss/corruption,
cross-tenant exposure, irreversible migration hazard or regression of a working
critical path. Preserve the worktree and report fact, evidence and consequence.

## Report shape

Use `round-report-template.md`. Reports link to checks and reviewer artifacts;
they do not paste reviews, retell the implementation or require test-count
inventories. Record what was not done only when a reasonable reader could
otherwise mistake scope or risk.
