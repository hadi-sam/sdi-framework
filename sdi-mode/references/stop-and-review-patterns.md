# Stop-and-Review Patterns

Implementation rounds aren't straight lines. Each phase has natural checkpoints where you deliver partial work and wait for review before continuing.

## Why checkpoints exist

- **Catching drift cheaply.** Errors compound; catching them at checkpoint N is 10x cheaper than catching at checkpoint N+3.
- **Keeping the user in the loop.** A long silent implementation arrives as one big thing the user can't easily review. Small, regular deliveries = continuous review.
- **Preserving your own context.** Stopping lets you receive corrections before you've built more code that needs reworking.

## Gates: pass or fail, no in-between

Each checkpoint has a **gate checklist** — a binary list of items that must all be ✓ before the round closes and you proceed to the next checkpoint. Gates are not aspirational. If a gate is unchecked, the checkpoint isn't complete; do not silently move on.

If you're tempted to skip a gate "because it's just one item", that's exactly when the discipline matters. Either complete the gate, or surface the blocker explicitly to the user and ask for an explicit waiver.

## Standard checkpoints per phase

These are typical — adapt to the specific phase.

### Auto-review eligibility

**Auto-review is the default for Checkpoints 2, 3, 4, and 5** (CPs 2-4 per-round; CP5 comprehensive phase-wide). Verification is delegated to a different-model reviewer ensemble unless the user asks for a different schedule: **every attempt (1-5)** runs Opus subagent + Sonnet subagent + `codex exec` (typically gpt-5.5 with reasoning effort `xhigh`) in parallel; if Codex is unavailable, a Haiku subagent substitutes for it. Different models find partially-disjoint bugs; the union catches more than any one reviewer alone. The checkpoint gate is closed by a structured Decision Bundle (per `auto-review-mode.md` §"Decision Bundle format"): obvious-fix findings are auto-applied (and the next round fires when no decisions remain), needs-decision and judgment-required findings are presented with options + a recommendation (the latter never auto-applied). The user can opt out per session — see `auto-review-mode.md`.

**Checkpoint 1 (Foundation) stays user-gated regardless** — audit findings routinely trigger always-escalate (DECISIONS material divergences, KI entries, blockers), making auto-review CP1-eligibility a near no-op. User gates the audit directly.

**Checkpoint 5 (Housekeeping) has comprehensive auto-review** running the **same up-to-5-attempt fix loop** as CPs 2-4. Reviewers look at the entire phase (diff between `PHASE_BASE_SHA` and `HEAD`), per-CP packet split by default. Obvious fixes auto-apply and the review re-runs; structural findings classify as needs-decision/judgment-required and are presented for the user. On PASS, stop **before opening the PR**; after 5 attempts still FAIL, escalate for the user to decide. See `auto-review-mode.md` §"CP5 comprehensive review".

Any round that produces a `DECISIONS.md` entry, adds/updates a `KNOWN_ISSUES.md` entry, hits any blocker, any emergency deviation, any plan revision, and any always-escalate trigger from `auto-review-mode.md` also stays user-gated even within an eligible checkpoint.

Each checkpoint header below carries an eligibility tag. Auto-eligible checkpoints have a single gate that accommodates both default auto-review and opt-out user-gated modes.

### Checkpoint 1: Foundation (after audit) **(user-gated)**

**Deliver:**
- Audit report of plan vs repo (see `audit-first-protocol.md`).
- Proposed schema / migration / dependencies (or scaffolding for fresh repos; provider wrappers + initial prompts for AI agents; trigger handlers + first integration wrapper for workflows).
- Any revision notes to the plan based on audit findings.
- Any `KNOWN_ISSUES.md` entries discovered during the audit that are outside current scope.

**Do not:**
- Write any endpoint, route, business logic, or UI code.
- Run package-install commands before approval.

**Gates (all ✓ before next checkpoint):**
- [ ] Audit report posted in canonical format
- [ ] All Blockers from the audit are either resolved or explicitly waived by the user
- [ ] All Open Questions from the audit are answered
- [ ] Each **material** plan-vs-repo Divergence has a corresponding `DECISIONS.md` entry; mechanical divergences are noted in the round report only (see `decisions-log-format.md` for the material vs mechanical distinction)
- [ ] Each concrete out-of-scope bug/security gap/tech debt finding has a `KNOWN_ISSUES.md` entry, or the audit states no new known issues were found
- [ ] Plan has a revision note (`rN`) summarizing audit changes (if any landed)
- [ ] User has given explicit go ("yes", "go", "proceed") — silence is **not** consent
- [ ] Today's `docs/memory/YYYY-MM-DD.md` entry mentions this checkpoint passing

**Stop phrase:**
> "Stopping here and waiting for your review before proceeding to [next deliverable]."

---

### Checkpoint 2: Core domain logic (pure functions, services, types) **(auto-review eligible)**

**Deliver:**
- Pure functions (mapping, validation, hashing/signing, normalization, state transitions, prompt rendering, etc.).
- Types / interfaces / schemas for the domain.
- Unit tests for everything above.

**Do not:**
- Write route handlers, API endpoints, or UI yet.

**Gates:**
- [ ] All pure functions in scope for this checkpoint are implemented
- [ ] Unit tests cover the edge cases called out in the plan (count vs plan list)
- [ ] All unit tests pass (real count from the runner, not approximation)
- [ ] No TODO/FIXME left in the code without a corresponding `DECISIONS.md`, `KNOWN_ISSUES.md`, or memory entry
- [ ] Round report posted in canonical format
- [ ] Auto-review (default) — reviewer ensemble returned merged PASS with all gates ✓ **OR** user opted out of auto-review and gave explicit go to move into integrations (see `auto-review-mode.md`)
- [ ] Today's `docs/memory/YYYY-MM-DD.md` entry summarizes the round

---

### Checkpoint 3: Wire up integrations **(auto-review eligible)**

**Deliver:**
- Route handlers / API endpoints / background workers / pipeline stages / agent loop wiring.
- Integration tests proving end-to-end behavior against local services (DB, job runner, LLM provider in mock mode, etc.).
- Observability hooks (Sentry, OTel, structured logs).

**Do not:**
- Build UI yet (if applicable).

**Gates:**
- [ ] All endpoints/handlers/workers in scope for this checkpoint exist and respond
- [ ] Integration tests cover the canonical happy path + at least one failure mode per surface
- [ ] All integration tests pass against a real local instance (not mocks-only)
- [ ] Observability is wired (logs, metrics, tracing) per `ARCHITECTURE.md` requirements
- [ ] Manual smoke command attempted (curl/httpie/CLI) and result documented
- [ ] Round report posted
- [ ] Auto-review (default) — reviewer ensemble returned merged PASS with all gates ✓ **OR** user opted out and gave explicit go (see `auto-review-mode.md`)

---

### Checkpoint 4: UI (only if the phase includes it) **(auto-review eligible)**

**Deliver:**
- Pages, screens, forms, tables, dialogs, navigation.
- Components used (Radix wrappers, shadcn, framework-native primitives, or equivalent per `DESIGN_SYSTEM.md`).
- State management, form validation, error handling, loading states.

**Do not:**
- Defer accessibility "for later" — empty/loading/error states and basic a11y are part of this checkpoint.

**Gates:**
- [ ] Every page/screen in scope is reachable from navigation
- [ ] Forms validate per the schemas defined in Checkpoint 2
- [ ] Loading, empty, and error states exist for each data-driven surface
- [ ] Manual walkthrough of the primary flow completed; screenshots in the round report
- [ ] No console errors or accessibility warnings on the primary flow
- [ ] Round report posted
- [ ] Auto-review (default) — reviewer ensemble returned merged PASS with all gates ✓ **OR** user opted out and gave explicit go (see `auto-review-mode.md`)

---

### Checkpoint 5: Housekeeping (end of phase) **(auto-review comprehensive — same fix loop; PASS stops before PR)**

**Deliver:**
- Acceptance criteria mapped to evidence (test file + line, or smoke step).
- Updated `PROJECT_STRUCTURE.md` if layout changed.
- Updated `DESIGN_SYSTEM.md` if tokens or components drifted (UI types only).
- Updated `AGENTS.md` / `CLAUDE.md` with newly discovered project conventions; if both exist, kept them in sync.
- Closing work item's verbose narrative written as a `## <work item>` section in `docs/WORK_LOG.md`; its Work tracker row reduced to one line (status + pointers).
- `DECISIONS.md` entries complete (all decisions taken during the phase recorded).
- `KNOWN_ISSUES.md` sweep complete (new issues cataloged; fixed issues marked resolved with commit/date; scheduled issues linked to work item).
- Manual smoke test run and results documented.
- Lint + typecheck + test suites green.

**Gates:**
- [ ] Every acceptance criterion in the current `IMPLEMENTATION_PLAN_*.md` §Acceptance Criteria has linked evidence
- [ ] `PROJECT_STRUCTURE.md` reflects the actual repo (no documented paths missing in code, no code paths missing in doc)
- [ ] `AGENTS.md` / `CLAUDE.md` updates proposed and approved by user; if both exist, kept in sync
- [ ] `DESIGN_SYSTEM.md` audit complete (UI types only) — tokens documented match tokens in code
- [ ] `DECISIONS.md` end-of-phase sweep done — no orphan/contradictory entries
- [ ] `KNOWN_ISSUES.md` end-of-phase sweep done — no uncataloged out-of-scope bugs/debt, no stale status for issues fixed or scheduled this phase
- [ ] All revision notes on the plan reference resolved changes
- [ ] Lint passes
- [ ] Typecheck passes
- [ ] All unit + integration test suites pass
- [ ] Manual smoke test of the main acceptance criterion completed live and documented
- [ ] Phase tracker in `AGENTS.md` / `CLAUDE.md` updated to ✓ with date, row kept to one line
- [ ] Closing work item's narrative added as a `## <work item>` section in `docs/WORK_LOG.md` (`Type` / `Status` / `Date` matching the tracker row)
- [ ] Today's `docs/memory/YYYY-MM-DD.md` entry marks the phase as closed
- [ ] CP5 comprehensive review run (auto-review default) — up-to-5-attempt fix loop on the phase-wide diff; obvious fixes auto-applied, decision findings presented with options + recommendation. Ended in PASS (then stop **before** opening the PR) OR, after 5 attempts still FAIL, escalated for the user to decide (continue manually, accept remaining findings as KNOWN_ISSUES, or open a follow-up work item). OR user opted out and reviewed manually.

---

## Not every phase has 5 checkpoints

Simple phases may have 2–3. Complex phases (lots of integration, many UI surfaces) may have 5–6. Use judgment, but **always include Checkpoint 1 (Foundation) and Checkpoint 5 (Housekeeping)** — those are non-negotiable.

## What to do at each stop

1. **Deliver the round report.** Same format every time. Read `round-report-template.md`.
2. **Walk through the gates.** Confirm each ✓ in the report. If any are ✗, surface them and propose remediation, do not pretend the checkpoint is complete.
3. **Explicitly state the gate mode.** User-gated: "Stopping here for review. Next proposed: [X]." Auto-reviewed PASS: "Merged PASS closed this gate. Next proposed: [X]."
4. **Proceed only when the gate mode allows it.** User-gated checkpoints require explicit user go; auto-reviewed checkpoints may proceed after merged PASS once the report is posted, unless the user interjects or an always-escalate trigger fired. Silence is not consent at user-gated checkpoints.
5. **Answer questions.** If the user raises concerns, address them before moving forward.

## How to know it's time to stop

Some common natural stopping points within a round:

- You've built the schema + migration. Stop.
- You've added 2–4 closely related files (service layer, types, schemas). Stop — these are often a natural "foundation + service" unit.
- You've built pure logic + tests for one module. Stop — UI that consumes it is a separate concern.
- You've finished an API surface (all routes for one resource). Stop — UI + integration tests are logical next units.
- You've done end-of-phase housekeeping. Stop — phase closure is itself a checkpoint.

If you catch yourself thinking "might as well also do X while I'm at it", stop — that's scope creep. Put X in the round report as "next round" and let the user decide.

## What to include in the stop message

- **Specific deliverable** you finished.
- **Gates status**: every gate item with ✓ or ✗.
- **Test status**: counts and pass/fail.
- **Observations**: anything noteworthy (a design choice, a small bug, a follow-up).
- **Next suggested deliverable** with rationale (why this, why now).
- **Explicit gate status** — "waiting for review" for user-gated checkpoints, or "merged PASS closed the gate" for auto-reviewed checkpoints.

## What NOT to do

- **Don't plow through multiple checkpoints.** Even if you feel confident, stop. The value of checkpoints is independent of your confidence.
- **Don't fake gate ticks.** A ✓ that doesn't reflect reality is worse than an ✗ — it removes the user's ability to catch a problem. If you're tempted to mark something done that isn't, don't.
- **Don't over-ask.** If the next step is obvious and low-risk, say so and propose it. Don't phrase it as a vague "what now?" — that wastes the user's time.
- **Don't skip the stop message.** Ending a round without explicit handoff makes reviews confusing.

## When the user pushes back at a checkpoint

The user might say:
- "Can you also add [X] before the next round?"
- "Please revise [Y] first."
- "The choice in [Z] isn't what I expected — why?"
- "Gate item N isn't actually true — show me the evidence."

Respond directly. Don't defend out of inertia. If they're right, acknowledge and adjust. If they're mistaken, say so with reasoning. If there's a real question, answer it.

Then, once resolved, re-propose the next deliverable and proceed.

## Emergency deviation

Occasionally something urgent needs to override the normal checkpoint pattern — a security bug, a data loss risk, a breakage of previously-working functionality. In that case:

1. Flag it loudly at the top of the response.
2. Propose the fix.
3. Recommend whether to pause the current phase to apply it, or to roll into the next round.
4. Even in emergency, log the deviation in today's `docs/memory/YYYY-MM-DD.md` so it isn't lost. If the emergency risk is deferred or only partially mitigated, add/update `KNOWN_ISSUES.md` too.

Don't silently do security or correctness work without surfacing it.
