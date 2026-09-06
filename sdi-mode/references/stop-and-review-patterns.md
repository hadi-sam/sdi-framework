# Stop-and-Review Patterns

Each phase has checkpoints where you deliver partial work and wait for review: they catch drift cheaply and let a correction land before more code sits on it.

## Gates: pass or fail, no in-between

Each checkpoint has a **gate checklist** where every item must be ✓ before the round closes. Gates are not aspirational: an unchecked gate means the checkpoint isn't complete. Skipping one "because it's just one item" is exactly when the discipline matters — complete it, or surface the blocker and ask for an explicit waiver.

## Standard checkpoints per phase

**CP1 (Foundation) and CP5 (Housekeeping) are fixed and non-negotiable.** What adapts is the middle: CP2 to CP4 are shaped to the phase, and a phase runs **2 to 5 checkpoints in total** — no UI, no CP4; a maintenance pass may be CP1 + CP5 alone. Nothing removes CP1 or CP5.

### Roles at each checkpoint

The gate checklists are the same whoever runs them; the PM / Engineer / Reviewer split ([`roles-and-orchestration.md`](roles-and-orchestration.md)) only decides *who*. **CP1** is PM-direct and user-gated, no Engineer. **CP2 / CP3 / CP4** are Engineer(s) + review, with an obvious code finding routed to a **fix-Engineer** and a paper-trail one applied by the PM. **CP5** is PM-direct doc work plus two closing gates: no Engineer produces CP5's own deliverables, but **CP5 does have a fix-Engineer** for any `[code]` finding the review raises — the same routing as everywhere else. The PM never runs a suite or a smoke, and **opening the PR** is the PM's (`gh pr create`), only after **both** the review PASSes **and** the smoke passes.

### Auto-review eligibility

⚠️ **CP5 consumes the paper-trail backlog.** CP2/3/4 do **not** fail on unpromoted `[docs]` findings — they PASS and defer them. **CP5 pays that debt**, and there the promotion applies: everything CP5 delivers is the paper trail, so a `[docs]` finding at CP5 is `[code]` and blocks. A CP5 closing with an unconsumed backlog has not closed. Marks and matrix: `auto-review-mode.md` §"Marks and the verdict matrix".

**Auto-review is the default for Checkpoints 2, 3, 4 and 5** — CPs 2-4 per round, CP5 comprehensive over the whole phase. The ensemble, the Decision Bundle, the cap (§"Loop cap") and the opt-out live in `auto-review-mode.md`, not restated here. **Checkpoint 1 stays user-gated regardless**, because audit findings routinely trigger always-escalate; at CP5 a PASS stops **before** the PR.

A round that hits a blocker, an emergency deviation, a plan revision or any other always-escalate trigger stays user-gated even inside an eligible checkpoint. **Writing a `DECISIONS.md` or `KNOWN_ISSUES.md` entry does not stop the round** — it is recorded in `## Decisões desta rodada` and repeated in the stop message at the next user-gated point. A product, design or architecture choice still **open** is a different thing: class 5, ESCALATE, and not the PM's to take.

### Checkpoint 1: Foundation (after audit) **(user-gated)**

**Deliver:** the audit report of plan vs repo (`audit-first-protocol.md`); the proposed schema / migration / dependencies (or whatever foundation the project type needs); revision notes from the audit; any `KNOWN_ISSUES.md` entries it surfaced outside scope. **Do not** write endpoints, routes, business logic or UI, and do not install a package before approval.

**Gates:**
- [ ] Audit report posted in canonical format
- [ ] Every Blocker resolved or explicitly waived, every Open Question answered
- [ ] Each **material** divergence has a `DECISIONS.md` entry; mechanical ones only the round report (`decisions-log-format.md`)
- [ ] Each concrete out-of-scope bug / security gap / debt has a `KNOWN_ISSUES.md` entry, or the audit states none were found
- [ ] Plan has a revision note (`rN`) for the audit changes, if any landed
- [ ] User gave explicit go ("yes", "go", "proceed") — silence is **not** consent
- [ ] Today's memory entry mentions the checkpoint passing

**Stop phrase:** "Stopping here and waiting for your review before proceeding to [next deliverable]."

### Checkpoint 2: Core domain logic **(auto-review eligible)**

**Deliver:** the pure functions (mapping, validation, signing, normalization, state transitions, prompt rendering), the domain types and schemas, and unit tests for both. **Do not** write route handlers, endpoints or UI yet.

**Gates:**
- [ ] Every pure function in scope implemented
- [ ] Unit tests cover the edge cases the plan lists and all pass — real count from the runner's generated block
- [ ] No TODO/FIXME left without a DECISIONS, KNOWN_ISSUES or memory entry
- [ ] Round report posted; today's memory entry summarizes the round; auto-review merged PASS **OR** explicit go after opt-out

### Checkpoint 3: Wire up integrations **(auto-review eligible)**

**Deliver:** route handlers, workers, pipeline stages or agent-loop wiring; integration tests proving end-to-end behaviour against local services; observability hooks. **Do not** build UI yet.

**Gates:**
- [ ] Every endpoint/handler/worker in scope exists and responds
- [ ] Integration tests cover the happy path plus a failure mode per surface, passing against a real local instance (not mocks-only)
- [ ] Observability wired per `ARCHITECTURE.md`
- [ ] Manual smoke command **run by the Engineer**, exact output in the round report — the PM never runs it; the CP-final smoke, and only that one, is the user's
- [ ] Round report posted; auto-review merged PASS **OR** explicit go after opt-out

### Checkpoint 4: UI (only if the phase includes it) **(auto-review eligible)**

**Deliver:** pages, forms, tables, dialogs, navigation; components per `DESIGN_SYSTEM.md`; state management, validation, error handling, loading states. **Do not** defer accessibility — empty/loading/error states and basic a11y belong to this checkpoint.

**Gates:**
- [ ] Every page/screen in scope reachable from navigation
- [ ] Forms validate per the schemas from Checkpoint 2
- [ ] Loading, empty and error states exist for each data-driven surface
- [ ] Manual walkthrough of the primary flow **run by the Engineer**, screenshots and result in the round report — the PM never runs it; the CP-final smoke, and only that one, is the user's
- [ ] No console errors or accessibility warnings on the primary flow
- [ ] Round report posted; auto-review merged PASS **OR** explicit go after opt-out

### Checkpoint 5: Housekeeping **(comprehensive auto-review → user-run smoke → PM opens PR)**

**Gates:**
- [ ] Every acceptance criterion has linked evidence
- [ ] `PROJECT_STRUCTURE.md` reflects the actual repo, in both directions
- [ ] `AGENTS.md` / `CLAUDE.md` updates proposed and approved; if both exist, in sync
- [ ] `DESIGN_SYSTEM.md` audit complete (UI types only)
- [ ] `DECISIONS.md` swept — no orphan or contradictory entry
- [ ] `KNOWN_ISSUES.md` swept — nothing uncataloged, no stale status for what this phase fixed or scheduled
- [ ] Every revision note references a change that landed
- [ ] Lint, typecheck and all suites pass (Engineer-run evidence; the PM records it, never runs them)
- [ ] If the fact sheet has a Work tracker, the item's row is ✓ with the date and one line — otherwise skip this gate
- [ ] Closing item's narrative added as a `## <work item>` section in `docs/WORK_LOG.md`, with `Type` / `Status` / `Date` matching the tracker row where there is one
- [ ] Today's memory entry marks the phase closed
- [ ] CP5 comprehensive review ended in PASS (which **clears only the review gate**), OR reached the cap and was handed back, OR the user opted out and reviewed manually
- [ ] The **CP-final smoke** of the main acceptance criterion run live **after** that PASS — **user-run**, the PM interpreting — and documented
- [ ] PR opened by the PM via `gh pr create` only **after both** pass (never auto-opened or merged)

## What to do at each stop

**Post the round report** (`round-report-template.md`) and **walk the gates**, confirming each ✓ in it; a ✗ is surfaced with proposed remediation, not papered over. **State the gate mode explicitly** — "Stopping here for review. Next proposed: [X]." or "Merged PASS closed this gate." — and **proceed only when that mode allows**: a user-gated checkpoint needs an explicit go, and silence is not consent.

The stop message carries the deliverable finished, **gate status with every item ✓ or ✗**, test status with counts, observations, and the next suggested deliverable. **At a user-gated stop (CP1, the CP-final smoke, before the PR) it also repeats the report's `## Decisões desta rodada` block** — one line per entry written since the last gate. That repetition is what makes writing the entries in the round enough: mandatory to record, optional to read.

Deliver every stop that waits on the user through the host's **structured ask tool** (`AskUserQuestion` under Claude Code), never as plain prose (see [`../SKILL.md`](../SKILL.md) §"Pausing for the user").

Natural stopping points: the schema and migration are built; related files form a foundation-plus-service unit; pure logic and its tests for one module are done; an API surface is complete for one resource. "Might as well also do X while I'm here" is scope creep — put X in the report as next round.

## What NOT to do

Don't plow through several checkpoints, however confident you feel. Don't fake a gate tick: a ✓ that doesn't reflect reality is worse than an ✗, because it removes the user's ability to catch the problem. Don't over-ask — propose the obvious low-risk next step instead of a vague "what now?", and don't skip the stop message.

When the user pushes back, respond directly instead of defending out of inertia: if they are right, adjust; if not, say so with reasoning; then re-propose.

## Emergency deviation

A security bug, a data-loss risk or a regression of working functionality may override the pattern. Flag it at the top of the response, propose the fix, and recommend pausing the phase or rolling it into the next round. Log the deviation in today's memory, and add or update a `KNOWN_ISSUES.md` entry if the risk is deferred or only partly mitigated. Never do security or correctness work silently.
