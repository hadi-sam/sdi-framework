# Artifact Bundle

The standard set of artifacts produced at the end of Phase C. Each has a specific purpose — they don't duplicate each other. The bundle adapts based on the project type chosen in Phase 0.

## The artifacts

1. **README.md** — index. Links to the others. One-paragraph product summary. Stack at a glance. Project type + AI modifier flag. Open questions deferred to production.

2. **PRD.md** — what's being built and why. Users, roles, features in scope, features explicitly out of scope, success metrics. Universal across project types.

3. **ARCHITECTURE.md** — how the system is designed. Universal sections (stack, critical flows, security, observability, trade-offs) **plus** type-specific sections inserted from `project-types/{type}/architecture-appendix.md` (multi-tenancy + data model + RLS for SaaS, rendering strategy for landing pages, data sources + caching for dashboards, etc.).

4. **ROADMAP.md** — phased delivery plan. Each phase gets a goal, deliverables, and acceptance criterion ("done when..."). Includes a fast-track option if relevant. Universal across project types.

5. **PROJECT_STRUCTURE.md** — repo layout (directory tree with file roles), coding conventions, environment variables, kickoff prompt template at the bottom. Comes from `project-types/{type}/project-structure-template.md` (heavily type-specific).

6. **DESIGN_SYSTEM.md** — typography, color tokens, spacing, motion, component patterns, accessibility targets. Comes from `project-types/{type}/design-system-template.md`. **Only generated for project types with UI** (web-saas, landing-page, dashboard, mobile). Skip entirely for headless types (api-service, data-pipeline, automation-workflow, ai-agent without UI).

7. **IMPLEMENTATION_PLAN_PHASE_1.md** (or `IMPLEMENTATION_PLAN_<slug>.md`) — detailed implementation spec for the first work item. This is the artifact the coding agent consumes most directly. Much more prescriptive than the others. Universal core (`core-templates/implementation-plan-template.md`) merged with type-specific sections.

   **Naming:** the framework treats `IMPLEMENTATION_PLAN_*.md` uniformly. Use `PHASE_N` for projects with a discrete linear roadmap (greenfield, structured migrations) and `<slug>` for free-form work in ongoing projects (features, maintenance, perf passes). The `sdi-next-plan` skill (and the `convert-to-sdi` skill for legacy projects) generate plans for subsequent work items, picking the appropriate naming.

   **ROADMAP coupling:** `ROADMAP.md` uses "Phase 0/1/2..." structure and is generated when a project has discrete planned phases. Continuous-feature or maintenance-mode projects may skip ROADMAP entirely or keep it minimal — work items are scoped one at a time via the `sdi-next-plan` skill.

8. **DECISIONS.md** — append-only paper trail of non-obvious decisions. Generated from `references/core-templates/decisions-template.md` as an empty scaffold for greenfield projects. Do **not** invent decisions at project birth; the file exists so implementation can append decisions without first creating the container.

9. **KNOWN_ISSUES.md** — append-only catalog of known bugs, security gaps, tech debt, and deferred fixes. Generated from `references/core-templates/known-issues-template.md` as an empty scaffold for greenfield projects. Do **not** invent issues at project birth; the file exists so future audits/reviews have a durable place to put out-of-scope problems.

10. **MEMORY.md** + **memory/YYYY-MM-DD.md** — datable execution memory. Generated from `references/core-templates/memory-template.md` with an index and today's Phase C handoff entry. This records that the bundle was created and what the next implementation step is.

11. **WORK_LOG.md** — verbose per-work-item narrative. Generated from `references/core-templates/work-log-template.md` as a near-empty living doc (header + Phase C section). It is the verbose counterpart to the one-line **Work tracker** in `AGENTS.md` / `CLAUDE.md`: the tracker is the index, `WORK_LOG.md` is the story. It grows one `## <work item>` section per work item, written at close. Not loaded every session and not the canonical source of detail — it consolidates and points into the plan, `DECISIONS.md`, `KNOWN_ISSUES.md`, and `docs/memory/`.

12. **AGENTS.md** and **CLAUDE.md** *(at repo root, not in `docs/`)* — project-specific **fact sheets** for the SDI workflow. Both are generated from the same customized `references/agents-template.md` content with the project's type, AI modifier flag, stack, and known conventions. They carry only project facts (stack, doc map, conventions, work tracker) — **never** the SDI discipline itself. The discipline lives in the `sdi-mode` skill (Claude Code / Codex) or the configured `sdi-mode` custom mode (Roo Code / Kilo Code / OpenCode). Generate both so the user can keep whichever file(s) their coding agents read.

## Conditional generation

| Artifact | Always generate? | Notes |
|---|---|---|
| README, PRD, ARCHITECTURE, ROADMAP, PROJECT_STRUCTURE, IMPLEMENTATION_PLAN_PHASE_1, DECISIONS, KNOWN_ISSUES, MEMORY, WORK_LOG, AGENTS.md, CLAUDE.md | Yes | Universal |
| DESIGN_SYSTEM | Only if UI | Skip for api-service, data-pipeline, automation-workflow, ai-agent (without UI) |
| AI-modifier additions | Only if modifier active | Adds sections to ARCHITECTURE, PROJECT_STRUCTURE, DESIGN_SYSTEM, IMPLEMENTATION_PLAN_PHASE_1 |

## Order and dependencies

Generate in this order — each builds on the previous:

```
PRD → ARCHITECTURE → ROADMAP → PROJECT_STRUCTURE → DESIGN_SYSTEM (if UI) → IMPLEMENTATION_PLAN_PHASE_1 → DECISIONS → KNOWN_ISSUES → MEMORY → WORK_LOG → AGENTS.md + CLAUDE.md → README
```

README is last because it's an index — it can't index documents that don't exist yet. DECISIONS and KNOWN_ISSUES are generated near-last because they need no planning input beyond product name and date. MEMORY follows them so the first daily entry can point at the initialized logs and the Phase 1 handoff. WORK_LOG follows MEMORY: it ships with only the header and the Phase C section, and the Work tracker in AGENTS.md / CLAUDE.md is its one-line index. AGENTS.md and CLAUDE.md are generated near-last because they benefit from knowing the stack/structure decisions from PROJECT_STRUCTURE and the Phase 1 prerequisites from IMPLEMENTATION_PLAN.

## Relationships

- **PRD** introduces the roles, features, and out-of-scope items. Everything else refers back.
- **ARCHITECTURE** operationalizes PRD features into stack and flows. Type appendix fills the structural model (multi-tenancy, data sources, ingestion pipeline, etc.).
- **ROADMAP** sequences the features from ARCHITECTURE into deliverable phases.
- **PROJECT_STRUCTURE** tells the coding agent where things live. Used by every subsequent plan.
- **DESIGN_SYSTEM** is consumed by UI-producing tasks; non-UI phases can ignore it.
- **IMPLEMENTATION_PLAN_PHASE_1** is the first "how" doc. Subsequent phases get their own plans later, not all at once.
- **DECISIONS** is the durable "why did we choose this?" log. It starts empty in greenfield projects and later receives numbered entries for non-obvious implementation choices, accepted trade-offs, deferrals, and material plan-vs-repo divergences.
- **KNOWN_ISSUES** is the durable "what we know is wrong" catalog. It starts empty in greenfield projects and later receives `KI-NNN` entries for out-of-scope bugs, security gaps, tech debt, and deferred fixes discovered during audits, implementation, reviews, or incidents.
- **MEMORY** is the dated breadcrumb trail. It starts with the Phase C handoff entry and later gets one entry per meaningful working day.
- **WORK_LOG** is the verbose per-work-item narrative. It starts with the Phase C section and gets one `## <work item>` section appended at each work item's close. The Work tracker in AGENTS.md / CLAUDE.md is its one-line index; the narrative that used to bloat the tracker's Notes cells lives here, pointing into DECISIONS / KNOWN_ISSUES / the plan / memory rather than duplicating them.
- **AGENTS.md / CLAUDE.md** sit at repo root and contain the same project fact sheet — they tell coding agents the project's stack, where to find docs, what conventions apply, and which work items are tracked. They evolve as the project proceeds (the coding agent enriches them with discovered repo conventions). The discipline (how to operate) lives in the `sdi-mode` skill or custom mode, not in these files.
- **README** indexes everything for human readers.

## What NOT to include in the bundle

- **All implementation plans at once.** Only Phase 1 is detailed now. Plans for later phases are speculative and will go stale. Generate them just before each phase starts.

- **Full test specifications.** The plan mentions required tests by category. Fleshed-out test cases emerge during implementation.

- **API documentation.** Generate from code later (Swagger/TypeDoc). At planning time, API contracts live in ARCHITECTURE and IMPLEMENTATION_PLAN.

- **User manual / end-user docs.** MVP ships without these; if the user wants them, that's a separate task.

- **Infrastructure runbooks, monitoring playbooks, incident response.** Phase 6-ish concerns.

- **Invented decisions.** `DECISIONS.md` is generated upfront, but entries require real non-obvious choices. A greenfield bundle should ship it with an empty entries section and instructions only.

- **Invented known issues.** `KNOWN_ISSUES.md` is generated upfront, but entries require concrete evidence. A greenfield bundle should ship it with an empty index and instructions only.

## Language

Default to **English** for artifacts even if the conversation is in another language. Reasons:

- Code, comments, and UI will be in English anyway (easier i18n later).
- Coding agents (Claude Code, Codex, Roo Code, etc.) are measurably stronger on English-aligned docs.
- Future collaborators may not share the user's language.

Say so when announcing artifacts: "Generating artifacts in English because [reasons]. If you prefer another language, say so."

## Scope of applicability check

Before generating, confirm the project type chosen in Phase 0 still matches what was discovered in Phase A/B. If the user pivoted (e.g., started as "landing page" and grew into "web SaaS multi-tenant"), say so explicitly and re-route to the appropriate type playbook before generating.

## Length discipline

The artifacts are decision records, not encyclopedias. Rules of thumb:

- **PRD**: ~400–600 lines. Each section is crisp.
- **ARCHITECTURE**: ~500–700 lines including type appendix. Flows are walkthrough-style, not pseudocode.
- **ROADMAP**: ~200–300 lines. Phases are tight.
- **PROJECT_STRUCTURE**: ~250–450 lines (varies by type — landing pages tighter, web SaaS larger).
- **DESIGN_SYSTEM**: ~250–400 lines.
- **IMPLEMENTATION_PLAN_PHASE_1**: ~400–600 lines. This one is the most prescriptive; being longer is OK.
- **DECISIONS**: ~30–70 lines when empty. It grows append-only as decisions are made.
- **KNOWN_ISSUES**: ~80–140 lines when empty. It grows append-only as issues are discovered.
- **MEMORY**: ~25–60 lines at birth (`MEMORY.md` index + one daily entry). It grows one dated entry per meaningful working day.
- **WORK_LOG**: ~20–40 lines at birth (header + Phase C section). It grows one `## <work item>` section per work item (typically 5–30 lines each), written at close. No hard cap — it is the archive — but each section consolidates and points into the canonical artifacts rather than transcribing them.
- **AGENTS.md / CLAUDE.md**: ~80–160 lines each. Same project facts only (type, stack, doc map, conventions, work tracker).
- **README**: ~30–80 lines. Strictly an index.

If you're trending past these, ask yourself what can be cut. Over-long docs are ignored.

## Announcing completion

After the last artifact is generated, give the user:

1. **One-paragraph recap** of what was generated and how to read it.
2. **How to use with the coding agent** — point to the kickoff prompt template (`references/kickoff-prompt-template.md`). The template is consolidated; the only branch is whether the user's tool loads `sdi-mode` as a skill (Claude Code / Codex) or as a custom mode (Roo / Kilo / OpenCode).
3. **What's next** — typically Phase 0 scaffolding or, for projects with significant UI, a UI prototype (Claude Design or equivalent) before code.

Keep the follow-up short. The artifacts are the deliverable.
