# IMPLEMENTATION_PLAN Template (Core)

The coding agent consumes the generated plan directly, so ambiguity here causes rework. Type-specific sections live in `project-types/{type}/` and are inserted at the marked locations below.

## Naming convention

The framework treats `IMPLEMENTATION_PLAN_*.md` uniformly. Use `IMPLEMENTATION_PLAN_PHASE_N.md` for discrete numbered phases (greenfield ROADMAPs, structured migrations) and `IMPLEMENTATION_PLAN_<slug>.md` for free-form work (features, bugfixes, maintenance batches, perf passes). Headers below say "Phase N"; substitute the slug when the plan uses one.

## Size and stability

The ceiling is in **bytes**, not lines: the limit configured in the project's docs lint (`scripts/docs_bounds.py` where the project carries one), and **60 KB** when the project has no lint. A line cap is not used — one line can hold a whole section, so it bounds nothing.

**Once approved, the plan is a stable specification.** What grows round by round — findings, divergences, narrative — goes to the round report, to `docs/WORK_LOG.md` and to `docs/reviews/`, never into the plan; §12 and §13 stay one-line slug lists. A plan that outgrows its ceiling is therefore accumulating revision archeology (see §"Revision notes"), restating itself across sections (see §"Writing tips"), or carrying more than one work item.

**A plan written at more than about 80% of the ceiling is already too big for one work item.** `sdi-next-plan` splits it into `PHASE_N` phases, each with its own plan under the ceiling, indexed by a short `BRIEF_<slug>.md` that names the phases and their order. **The ceiling is never raised by exception.**

## Structure

```markdown
# Implementation Plan — Phase N: [Phase Title]
# (or: Implementation Plan — <slug>: [Title] — for free-form work)

> Detailed spec for this work item. Companion to PRD.md, ARCHITECTURE.md, PROJECT_STRUCTURE.md, DECISIONS.md, and KNOWN_ISSUES.md. Prescriptive where ambiguity would cause rework.
>
> **Revision note (rN, AAAA-MM-DD):** [only after an implementation-time audit reshapes the plan; see §"Revision notes" for the bound.]

## 0. Pre-requisites

- [Previous phase N-1 completed]
- [Required env vars / external accounts / setup steps]

### Work-item operating profile

- **PM:** main session
- **Engineer / Fix / Merge:** Pendente — definir modelo, vendor e effort antes do primeiro dispatch
- **Reviewers:** Pendente — definir modelos, vendors, efforts e quantidade antes do primeiro dispatch

The PO defines each pending function once. Persist the answer here and reuse it
for every round/resume. Never infer a missing selection. Invocation failure,
rate limit or unusable output returns to the PO for pause or explicit replacement;
persist the replacement unless the PO limits it to one occurrence. Independent
cross-vendor reviewers are recommended, not a gate.

## 1. Scope

[What this phase produces — 2-3 sentences max.]

> **In-scope items are SECTION POINTERS, not restatements.** Each bullet names a deliverable in ≤1 line and references the canonical section. Do NOT restate shapes, contracts, status codes, or behavior here; that drifts against §2–§9 every time a fact is updated. §1 is the table of contents, not the story.

In scope:
- `[deliverable]` — see §[N]
- ...

Out of scope for this phase:
- [bullets — explicit deferrals; OK to be brief, no section pointer needed]

## 1.5 Runtime Dependencies to Install

- `package-name` — purpose (why chosen)

Explicitly NOT installing:
- `deferred-package` — deferred per DECISIONS.md #N

## 2. [Type-specific changes]

[Insert the type-specific implementation sections here — which ones they are is defined per type in the appendix, not repeated in this template.

Load only the context needed for this work item:
- Always start with `project-types/{type}/architecture-appendix.md` for the type-specific implementation concerns.
- For repo layout, conventions and UI, read the target project's live `docs/PROJECT_STRUCTURE.md` and `docs/DESIGN_SYSTEM.md` when the repo already exists; fall back to this skill's `project-types/{type}/project-structure-template.md` and `design-system-template.md` when generating the initial bundle. If a UI-bearing project has no design system, flag that as a pre-requisite instead of inventing one.]

## 3. [Domain-specific algorithm or verification]

[E.g. HMAC verification, mapping engine, state machine, retrieval ranking, scraping resilience — depth proportional to the subtlety of the thing.]

## 4. ...

[More sections as the domain dictates.]

## 5. Rate Limiting / Resource Protection (or equivalent)

[If deferred, say so and document the stub pattern + env flag that activates the real implementation later.]

## 6. UI Surfaces (if applicable)

[Pages/screens, who can access, key interactions. Skip entirely for non-UI projects.]

## 7. Background jobs / async work

[Which event/trigger, what the handler does, retry policy, idempotency.]

## 8. Tests and evidence (proportional)

- Existing relevant checks: [commands and the contract/risk each proves]
- New automated test only for material silent harm to data/access or an acceptance criterion explicitly approved by the PO: [if applicable]
- Targeted smoke/eval: [only when a named acceptance criterion or reachable risk requires it]
- Existing mandatory CI gates: [list; never waive through proportionality]

Do not create a test harness, census, mutation gate or coverage target merely to
strengthen the instrument. A functional bug is still fixed when it does not meet
the threshold for a permanent new test.

## 9. Observability (only when required)

- [Reachable silent failure or production constraint that requires a log/metric]
- [PII/security rule already binding the changed path]

Omit this section when the change creates no material observability need.

## 10. Acceptance Criteria

Phase N is done when:

> **Criterion format:** each criterion is ONE LINE — `<N>. Per §X.Y, <testable invariant>`. Commands, queries, fixtures and escalation trees live in §8, in §11 phase-specific gates, or in the section that defines the invariant.

1. [Testable criterion]
2. ...

## 11. Implementation checkpoints (for sdi-mode)

Standard gates per checkpoint are canonical in `sdi-mode/references/stop-and-review-patterns.md`; follow them there and do not mirror them here.

Map §2–§9 to independent risk, decision or reviewable-delivery boundaries. Audit-first and housekeeping responsibilities are required, but small items may combine their reports with implementation when no user gate is needed. Drop empty checkpoints. Independent review is selected by risk/contract, not by checkpoint number.

### Checkpoint 1 — Foundation / audit **(user-gated only if §0 or audit exposes a real gate)**
**Covers:** §0, §1 (audit framing), §1.5, §2 schema/migrations/types — foundation only, no business logic.

> **Gate format:** phase-specific gates are ONE LINE — `- [ ] Per §X.Y[, §Z.W], <testable clause in ≤15 words>`. Details live in the referenced section.

- [ ] [optional, e.g. "Per §2.1, migration 0008_billing_tables applied to local DB"]

### Checkpoint 2 — Core domain logic **(include/review only when independently justified)**
**Covers:** §3, §4+ pure logic, and any §8 evidence justified for those paths.
- [ ] [optional]

### Checkpoint 3 — Wire up integrations **(include/review only when independently justified)**
**Covers:** §2 endpoints/handlers, §5, §7, applicable §9, and justified §8 evidence.
- [ ] [optional]

### Checkpoint 4 — UI **(skip if no §6; review only when independently justified)**
**Covers:** §6.
- [ ] [optional]

### Checkpoint 5 — Housekeeping **(may share the final round; review/smoke only when justified)**
**Covers:** §10 evidence mapping, §12, §13, known-issues lifecycle, doc updates, work-item close in `docs/WORK_LOG.md`.
- [ ] [optional]

## 12. Decisions Log (for DECISIONS.md)

Slugs only, one line each; the number is assigned when the entry is written, against every live ref. Never pre-allocate a number here.

- `[decision-slug]` — [what it settles, one clause]

## 13. Known divergences from earlier docs

One line per divergence, no restatement of the docs it diverges from.

- PROJECT_STRUCTURE.md says `[old path]`; repo uses `[new path]`. Repo wins; doc updated at phase close.

## How to feed this to the coding agent

[End-of-doc kickoff prompt, so the reader knows how to start execution.]

> "Implement Phase N per `docs/IMPLEMENTATION_PLAN_PHASE_N.md` (rN). Follow `docs/PROJECT_STRUCTURE.md` for file locations and `AGENTS.md` / `CLAUDE.md` for stack/conventions. Read `docs/KNOWN_ISSUES.md` before audit. When the plan disagrees with the actual repo, the repo wins — note material divergences in `DECISIONS.md`; catalog pre-existing out-of-scope bugs/debt/security gaps in `KNOWN_ISSUES.md`.
>
> Implement proportionally per §11 and `sdi-mode/references/stop-and-review-patterns.md`. Audit before writing. Stop only if the audit exposes a required user gate; otherwise proceed with the smallest approved change. Start with:
> 1. [First deliverable — usually Checkpoint 1 Foundation: schema + deps + audit]
> 2. [Second — Checkpoint 1 audit findings]
> 3. [Third — narrow confirmation question about conventions]
>
> If one of these raises a product/architecture/scope decision, irreversible action, production action or material risk, stop for the PO before dependent work."
```

## Writing tips

- **Each fact has ONE canonical section.** Tool shapes §2, contracts §3, signatures §4, UI §6, observability §9, criteria §10; other sections reference by §-number and never restate. **SSOT is a hard rule, not a guideline**: the fix for "add a gate restating spec" is always a pointer (`Per §X.Y`), never a copy. Review flags restatement as class 6.
- **§1 in-scope bullets, §10 criteria and §11 phase-specific gates are one line each**, in the `Per §X.Y, <clause>` form. A summary rots the moment the section it summarizes is revised. The anti-pattern is a gate that re-narrates the requirement, quotes the review findings that produced it, or carries a count.
- **No counts and no `file:line` anchors in the plan.** Verify-before-claim still holds for the **existence** of a symbol or path — grep before naming it — but the measurement itself (command, number, date) goes to `docs/reviews/`. A number in prose cannot be revalidated and goes stale silently; a recorded command can be re-run.
- **Type-specific schemas/contracts (§2) should be close to production-ready**, and API contracts should cover error cases, not just the happy path.
- **§13 is where the plan is honest about its own limitations**, usually empty at first draft.

> **Maintenance note (framework maintainers, not for generated plans):** the three copies of this file — under `mvp-architect/`, `convert-to-sdi/` and `sdi-next-plan/` — are **byte-identical on purpose**. Change one, copy it over the other two, and diff to confirm.

## Revision notes

Notes stack at the top of the plan, newest first, in **one** format:

> **Revision note (rN, AAAA-MM-DD):** plan review-N ([verdict]). Fixes applied; the substantive ones are DECISIONS entries [slugs]. Details in `docs/reviews/`.

Bounds — the project's docs lint (`scripts/docs_bounds.py`) where it has one, and otherwise **each note ≤ 1 KB** and **at most 6 notes**. Writing the 7th means first collapsing the previous ones into a single mandatory consolidation line:

> **Consolidated r2-r6, AAAA-MM-DD:** findings resolved; main decisions: [slugs]. Details in `docs/reviews/`.

Never delete a review file: the plan stays lean because the archive exists.

## Common failure modes

- **Too abstract.** A plan that reads like a PRD isn't detailed enough — §2 and §3 carry signature formats, status codes, prompt templates, schema fragments.
- **Too speculative.** Don't plan phase N+2 here; that's ROADMAP territory.
- **Missing out-of-scope, or missing acceptance criteria.** §1's deferral list prevents scope creep; §10 is the contract for "when are we done".
- **Empty §11.** A plan without checkpoint mapping forces the implementer to retrofit the discipline at execution time.
- **Sections beyond §13 + the kickoff.** Don't create §14. Resolved decisions → §12; surgical mitigations → §11 gates; review trajectory → `docs/reviews/`; operational pre-reqs → §0; lessons learned → memory entries; project-specific operational overrides (deploy command, env vars, build flags) → `AGENTS.md` / `CLAUDE.md`. Excess meta sections are accumulated archeology.
- **Editing the spec after implementation starts.** §2–§9 change only under an explicit `rN` note — in the CP1 audit or the CP5 sweep. A silent edit breaks the audit trail: the next reader can't tell the original spec from the corrected one.
