# Expected Artifacts

What the spec bundle should contain when you receive it. If it's incomplete, flag that before starting.

## The bundle

Under `docs/` (or equivalent), at minimum:

- `README.md` (index), `PRD.md` (requirements), `ARCHITECTURE.md` (stack, structural model, flows, trade-offs), `ROADMAP.md` (phases, acceptance criteria), `PROJECT_STRUCTURE.md` (layout and conventions).
- `DECISIONS.md` and `KNOWN_ISSUES.md` — the two append-only paper trails. New bundles create both even when empty.
- `MEMORY.md` + `memory/YYYY-MM-DD.md` — datable session memory. New bundles create the index and an initial handoff entry.
- `WORK_LOG.md` — verbose per-work-item narrative, one section per item, written at close. Its index is the fact sheet's **Work tracker** where the project has one; where it doesn't, the index is the `docs/plans/` directory. Read on demand.
- `IMPLEMENTATION_PLAN_*.md` — the spec for the current item, suffixed `PHASE_N` or `<slug>`; the framework treats both uniformly.

At the repo root, `AGENTS.md` and/or `CLAUDE.md` — the fact sheet: stack, document map, conventions, and optionally a work tracker. New bundles generate both with the same content; the user keeps whichever their agents read. **These files do not carry the SDI discipline.** `DESIGN_SYSTEM.md` only if the project has a UI.

## Mode discipline carrier

| Tool | Discipline carrier |
|---|---|
| Claude Code | `sdi-mode` skill; `CLAUDE.md` at repo root carries project facts |
| Codex | `sdi-mode` skill; `AGENTS.md` at repo root carries project facts |
| Roo Code / Kilo Code / OpenCode | Custom mode `sdi-mode` per `installation-guides/{tool}.md`; Kilo/OpenCode may also read `AGENTS.md` for facts |

If the skill or configured mode is not active, the discipline isn't loaded — ask the user to activate it. If **both** fact sheets are missing, route to `convert-to-sdi` for an existing repo or `mvp-architect` for greenfield.

## How to recognize a complete handoff

1. **An `IMPLEMENTATION_PLAN_*.md` exists** for the work item asked about — if not, stop and ask; don't infer one from the roadmap or from prose.
2. **The plan has concrete sections**, not placeholders: schema or structural sketches, contracts with status codes, test requirements, acceptance criteria. Mostly-TODO means the handoff is incomplete.
3. **`PROJECT_STRUCTURE.md` matches the repo** — drift means the docs weren't updated after recent work.
4. **The PRD's out-of-scope section is explicit.** Without it you will over-build.
5. **`sdi-mode` is active and at least one fact sheet exists.**

## When artifacts are missing or thin

**No plan for the work item:** don't improvise. It needs a plan first — `sdi-next-plan` when the bundle exists, `convert-to-sdi` for a codebase without one, `mvp-architect` Phase 0-C for greenfield — and you implement after. A small contained task can be done outside SDI if the user explicitly asks, but that is not an SDI run.

**Plan has gaps:** list them as **open questions** in the audit; don't fill them in silently. **`PROJECT_STRUCTURE.md` outdated:** flag it and offer to update it at housekeeping — don't let "docs are wrong" become "docs stay wrong".

**`DECISIONS.md`, `KNOWN_ISSUES.md`, `MEMORY.md`/`docs/memory/` or `WORK_LOG.md` missing:** an older bundle, not a reason to route back through planning. Create each scaffold from its reference file when first needed — before the first decision, before the first round report, at the end of the first session, at the first close. Never invent a decision or fabricate a past daily entry to fill a file. In a bundle whose Work tracker has verbose `Notes` cells, slim those into per-item `WORK_LOG.md` sections at the same time, and start the narrative from the next close rather than backfilling.

**Fact sheet sparse or divergent:** a bare template means filling in stack and conventions during the audit and proposing them; both files missing means routing to `convert-to-sdi` or `mvp-architect`. A fact sheet carrying **discipline rules** (an 8-step list, "audit before coding", checkpoint behaviour, tone, precedence) is an older format — suggest `convert-to-sdi` Phase 1.5 Strategy B. If both files exist and differ, flag the drift and propose syncing at housekeeping.

## Reading order for a new phase

1. **AGENTS.md / CLAUDE.md** (both if both exist — compare for drift): stack and project conventions.
2. **docs/MEMORY.md** + the last two or three daily entries: where the work is, what's blocked, what's pending.
3. **README.md** for product and stack context; then **the current `IMPLEMENTATION_PLAN_*.md`** top to bottom, your primary spec.
4. **ARCHITECTURE.md** — the structural section plus the flows this phase touches; **PROJECT_STRUCTURE.md** — skim for conventions.
5. **KNOWN_ISSUES.md** — the index and open entries; note what this item fixes, worsens, or must avoid duplicating. **DECISIONS.md** — skim headers, read what applies.
6. **The repo files the phase will touch** — schemas, helpers, modules.

That is 15-30 minutes before any code. Don't skip it. `docs/WORK_LOG.md` is deliberately **not** in the list: it is the verbose archive, read on demand — which section to open is told by the fact sheet's Work tracker where there is one, and by `docs/plans/` where there isn't.

## What the planner artifacts mean

- **`§ Decisions Log` in the plan** — a checklist of decisions the plan anticipates; each becomes a real `DECISIONS.md` entry by end of phase.
- **`§ Known divergences`** — where the plan admits it disagrees with the repo or another doc; at close, mark each ✓ resolved or ⏸ deferred.
- **`KI-NNN` entries** — known wrongness not necessarily in the plan. A plan that fixes one references it and updates its status; one that *discovers* one adds an entry instead of burying it in `§ Known divergences`.
- **`Revision note (rN, AAAA-MM-DD)`** — the plan changed during implementation. Always read these.
- **`Out of scope` in the PRD** — not features to sneak in because they are easy; point at the list and ask whether to escalate or defer.
- **`Not done in this round (and why)`** — real items the previous round deferred. Carry them forward.

## Document precedence

Docs disagree, and without a rule the agent silently picks the wrong source. Highest authority first; when two conflict the higher wins, and the lower gets a revision note or an end-of-phase update.

| Priority | Source | Authority |
|---|---|---|
| 1 | **Live repo state** (committed code) | Wins over every doc. Reality is canonical. |
| 2 | **AGENTS.md** / mode metadata | **Wins on facts** — stack, paths, helper names, conventions, current state — because it is kept in step with the repo. It does **not** win on scope: what is in and out of the product is the PRD's, one row down. |
| 3 | **PRD.md** | What and why. Scope and intent; changing it implies a re-scope. |
| 4 | **ARCHITECTURE.md** | How — stack, structural model, critical flows. The technical contract. |
| 5 | **ROADMAP.md** | When — phases and acceptance criteria. |
| 6 | **PROJECT_STRUCTURE.md** | Where — file conventions, repo layout. |
| 7 | **IMPLEMENTATION_PLAN_*.md** | Detailed how, item-scoped. A translation: if it disagrees with ARCHITECTURE, the plan is wrong. |
| 8 | **DESIGN_SYSTEM.md** | Visual language (UI only). Design serves product, not the reverse. |
| 9 | **README.md** | Index. Never source of truth. |
| – | **DECISIONS.md**, **KNOWN_ISSUES.md**, **docs/memory/**, **WORK_LOG.md** | *Patches*, *known wrongness*, *breadcrumb* and *per-item history* — none of them authority. If they disagree with the docs above, the docs win. |

**`DECISIONS.md` is overlay, not override.** An entry records an exception or a concretization; it does not outrank a higher doc. A *local exception* ("RLS bypass intentional here") is logged for traceability while ARCHITECTURE still states the rule. A *contradiction* ("Postgres to MongoDB") means ARCHITECTURE is now wrong: revert the decision or update ARCHITECTURE, with a revision note if mid-phase. Don't hide contradictions there — surface them.

**`KNOWN_ISSUES.md` is catalog, not scope.** An entry overrides nothing and forces no fix; a KI contradicting ARCHITECTURE means ARCHITECTURE is the intended design and the KI is evidence the repo doesn't meet it. **Memory is breadcrumb, not authority**: if it says "Round B done" and `PROJECT_STRUCTURE.md` shows no such directory, the doc needs updating, not the memory.

### Applying the rule

Identify the higher doc, use it as truth, and align the lower one — a revision note now, or an end-of-phase alignment if not blocking; if the lower doc is the plan, the audit already handles it. Add a `DECISIONS.md` entry when the resolution took a non-obvious choice.

Two cases worth naming. **Live repo vs ARCHITECTURE:** the repo wins by definition, but ask whether it drifted accidentally (fix the repo) or deliberately (update ARCHITECTURE with a decision entry). **Two docs disagree and one is higher in the table** (ARCHITECTURE against PROJECT_STRUCTURE on paths): the table decides — here ARCHITECTURE. If the repo follows the lower doc, that is priority 1 winning over both, and the fix is to update ARCHITECTURE, not to invert the table.

## Talking to the planner or reviewer agent

The user may pair you with `sdi-review` (consultative review during implementation) or invoke `sdi-next-plan` at phase close; fresh-project planning is `mvp-architect`. A relayed question or an audit suggestion taken back to one of those is a good-faith review loop.

Execution under `sdi-mode` is itself multi-agent: you are the **PM/orchestrator**, dispatching **Engineer** subagents and a three-model **Reviewer** ensemble, and you own the paper trail ([`roles-and-orchestration.md`](roles-and-orchestration.md)). That is distinct from the `sdi-review` consultant, which never executes code work: a code finding there becomes a recommendation, while the PM routes one to a fix-Engineer. Either way, only the PM edits docs.
