---
name: mvp-architect
description: Plan a product from a rough idea to an initial spec bundle (PRD, ARCHITECTURE, ROADMAP, PROJECT_STRUCTURE, IMPLEMENTATION_PLAN, DECISIONS, KNOWN_ISSUES, MEMORY, WORK_LOG, AGENTS.md, CLAUDE.md). Covers 8 project types (web SaaS, landing page, dashboard, web API, mobile, data pipeline, AI agent/MCP, automation) via Phase 0 router, with optional AI/LLM modifier. USE when starting greenfield work — "I have an idea for X", "want to start a project", "help me scope a product", "need a PRD for Y", "we want to build Z from scratch". DO NOT USE for mid-implementation review (use sdi-review), planning the next work item after a phase closes (use sdi-next-plan), executing implementation (use sdi-mode), or onboarding existing code without an SDI bundle (use convert-to-sdi).
---

# MVP Architect

This skill captures a way of going from a rough product idea to a spec bundle a coding agent can execute on. It optimizes for **catching bad decisions early**, when changing them is cheap.

The skill works across multiple project types via a Phase 0 router: web SaaS multi-tenant, landing pages, dashboards, web APIs, mobile apps, data pipelines, AI agents/MCP servers, integration/automation workflows. An optional AI/LLM modifier supplements any project type with cross-cutting LLM concerns (prompts, eval, cost, guardrails).

## When to enter

Initial scoping (Phase 0 → A → B → C) is this skill's only entry mode. Triggers — go straight to Phase 0:

- "I have an idea for X" / "want to start a project" / "help me scope a product"
- "need a PRD for Y" / "we want to build Z from scratch"
- The user has a rough product idea and wants help shaping it before any code is written.

If the request is something else, route the user out:

- Mid-implementation review (a plan, round report, fork decision, or bug found): use the `sdi-review` skill.
- Planning the next work item after a phase or feature closes: use the `sdi-next-plan` skill.
- Adopting an existing codebase to SDI: use the `convert-to-sdi` skill.
- Executing an existing implementation plan: use the `sdi-mode` skill.

If the user's message is ambiguous (e.g., "use mvp-architect" with no context), ask once:

> Before we start: are you scoping a brand-new product (greenfield)? If you're mid-implementation and want a review, use `sdi-review`. If your last phase just closed and you want the next plan, use `sdi-next-plan`. Reply with which one fits.

## When to use

- User arrives with a product idea (vague or partial is fine — that's the normal case).
- User asks to "refine this idea" or "help me figure out what to build".
- User asks for help preparing specs/docs for a coding agent to implement.
- The project has no `IMPLEMENTATION_PLAN_*` yet, no `AGENTS.md` / `CLAUDE.md`, and no `docs/` planning bundle.

If the project already has any of those artifacts, the user probably needs `sdi-review`, `sdi-next-plan`, or `sdi-mode` instead — see "When to enter" above.

## Scope of applicability

The skill covers 8 project types via Phase 0 routing. If the project doesn't fit any of them, ask whether to proceed adapting on the fly, or stop.

## Core principle

**Don't generate artifacts too early.** Premature artifacts crystallize half-baked decisions into documents, and then the document starts driving discussion instead of the actual thinking. First pin the project type, then get a solid scope through conversation, then produce the bundle.

The biggest risk in planning is **false sense of progress** — generating a PRD when fundamental trade-offs are still unresolved. A good PRD comes after the user has explicitly chosen a side on every critical axis (the type-specific axes plus universals like users, integrations, data, scale) and understands why.

## The flow

The skill operates in **four phases (0, A, B, C)** — the initial scoping flow, sequenced one-way with go-backs allowed.

```
Phase 0  →  Phase A  →  Phase B  →  Phase C
(triage)    (themes)    (refine)    (artifacts)
```

After Phase C generates the artifact bundle, the user hands off to `sdi-mode` for implementation. Mid-implementation review and next-phase planning are **separate skills** (`sdi-review` and `sdi-next-plan`), not phases of this skill. Don't try to handle them here.

### Phase 0 — Project type triage

Before any open discovery, fix the project type. Ask once, with concrete options:

> Before the discovery questions, which of these categories does your project fit? I'll pull the right playbook:
>
> 1. **Web app SaaS multi-tenant** (signup, multi-org, future billing)
> 2. **Landing page / marketing site** (focus on conversion and SEO)
> 3. **Dashboard / admin / internal tool** (data viz, ops)
> 4. **Web API / backend service** (no UI — REST/GraphQL/webhooks)
> 5. **Mobile app** (React Native, Flutter, or native)
> 6. **Data pipeline / scraper + reports** (ingestion and automated delivery)
> 7. **AI agent / MCP server / chatbot** (LLM-driven)
> 8. **Integration / automation workflow** (n8n/Zapier-style or Inngest/Temporal)
> 9. **Other** — describe and I'll adapt
>
> You can reply with just the number.

After the type is chosen, ask the AI modifier toggle:

> Does the product have a significant LLM/AI component (chat, classification, generation, agent)? Yes/no.

If type = `ai-agent` (option 7), the AI modifier is implicitly active — don't re-ask.

If user picks "Other" (option 9): listen, then either map to the closest existing type or proceed adapting (announce the limitation explicitly).

### Phase A — Initial reaction and first thematic questions

When the user describes their idea (after Phase 0), do three things in the first reply:

1. **Summarize what you heard in one line.** Confirm the product in a way they'd recognize ("a voice-based pre-qualification engine + funnel CRM"). This catches misunderstandings upfront and shows you're listening.
2. **Identify the critical decision axes.** Don't ask every possible question — identify the 6–10 that, once answered, would unlock the rest. The axes come from a combination of `references/discovery-themes.md` (universal) + `references/project-types/{type}/discovery.md` (type-specific) + `references/modifiers/ai.md` (if AI is in scope).
3. **Ask grouped by theme, not as a flat list.** Group related questions (all integration questions together, all multi-tenancy questions together, etc.). Don't ask more than 2–3 questions per theme at once.

Load these references in this order:
- `references/discovery-themes.md` — universal themes
- `references/project-types/{type}/discovery.md` — type-specific themes (specific to chosen type)
- `references/modifiers/ai.md` — AI/LLM modifier themes (if active)

The themes are a starting point; adapt based on the product.

Important: after asking, **stop and wait** for responses. Don't keep adding speculation or draft artifacts. The user's answers will reshape the questions you ask next.

### Phase B — Iterative refinement

The user responds. Now iterate:

- **React to each answer specifically**, not generically. If they made a decision you agree with, say so briefly and move on. If they made one that's risky, push back with reasoning. If they said "I don't know, suggest", propose with rationale.
- **Introduce trade-offs they may not have seen.** If they said "use framework X", and X has a known weakness for their case, surface it. This is the core value of the skill — the user often doesn't know what they don't know.
- **Keep asking the next layer of questions**, now more specific. Tool/library choices, UX specifics, edge cases.
- **Track what's decided vs open.** As decisions firm up, don't re-ask. Move on.
- **Modifier emergence:** if mid-conversation an AI/LLM feature surfaces in a project that didn't flag it in Phase 0, load the AI modifier now and integrate its themes.

Signs you're still in Phase B (keep asking):
- Major architectural choice still open (auth, isolation, primary data store, orchestration).
- User keeps saying "hmm, not sure" on fundamentals.
- You're discovering new requirements each turn.
- You haven't proposed a stack yet, or user hasn't agreed to one.

### Phase C — Ready for artifacts

Signs you're ready:
- Stack is chosen and agreed (with type-appropriate components).
- Type-specific structural model is decided (multi-tenancy for SaaS, refresh/cache for dashboards, sync model for mobile, workflow engine for automation, etc.).
- Primary user roles and flows are clear.
- Integrations are identified with enough detail to plan around.
- User is saying "let's build this" not "what if we...".
- You could write the PRD summary paragraph from memory and it would be correct.

When those signs are there, **announce the transition**: "Scope is locked on the critical axes. Generating the artifact bundle now." Then produce all artifacts in a single response.

Read `references/when-to-generate.md` for more detailed signals and common false positives (things that feel like readiness but aren't).

Read `references/artifact-bundle.md` for the canonical set of artifacts, their order, and how they relate. Then load templates narrowly as you generate each artifact:

- PRD → `references/core-templates/prd-template.md`
- ARCHITECTURE → `references/core-templates/architecture-template.md` + `references/project-types/{type}/architecture-appendix.md`
- ROADMAP → `references/core-templates/roadmap-template.md`
- PROJECT_STRUCTURE → `references/project-types/{type}/project-structure-template.md`
- DESIGN_SYSTEM → `references/project-types/{type}/design-system-template.md` only for UI-bearing types (web-saas, landing-page, dashboard, mobile, or ai-agent with UI)
- IMPLEMENTATION_PLAN → `references/core-templates/implementation-plan-template.md` + only the type references needed for the work item, starting with `references/project-types/{type}/architecture-appendix.md`
- DECISIONS → `references/core-templates/decisions-template.md` (empty scaffold; do not invent decisions for a greenfield project)
- KNOWN_ISSUES → `references/core-templates/known-issues-template.md` (empty scaffold; do not invent issues for a greenfield project)
- MEMORY → `references/core-templates/memory-template.md` (index + today's Phase C handoff entry)
- WORK_LOG → `references/core-templates/work-log-template.md` (header + Phase C section; verbose counterpart to the one-line Work tracker)
- AGENTS.md + CLAUDE.md → `references/agents-template.md` (same customized content in both files)
- README → `references/core-templates/readme-template.md`

Do not load all templates up front; load the next file only when you are about to generate that artifact.

The artifacts merge **core templates + type appendices** into single coherent documents (one ARCHITECTURE.md, one PROJECT_STRUCTURE.md, etc.), not stitched two-doc affairs. The README is the index. Every doc has a clear purpose and doesn't duplicate another.

End the bundle with two outputs:

1. The **AGENTS.md** and **CLAUDE.md** files for the project root, generated from the same customized template in `references/agents-template.md`. They carry only project facts (stack, doc map, conventions, work tracker) — they do **not** carry the SDI discipline. The discipline lives in the `sdi-mode` skill (Claude Code / Codex) or the configured `sdi-mode` custom mode (Roo Code / Kilo Code / OpenCode). Never inject behavioral instructions into either generated file. Generate both with identical content so the user can keep the file(s) their coding agents read.

2. The **kickoff prompt** for the user to paste into their coding agent when they start implementation. Read `references/kickoff-prompt-template.md` for the consolidated template (one shape, with a single conditional line for "skill" vs "custom mode" depending on the tool).

After Phase C, hand off the bundle to a coding agent via the kickoff prompt. For mid-implementation review (plan reviews, round report reviews, fork decisions, bug findings), the user invokes the `sdi-review` skill. For planning the next work item after the current one closes, the user invokes the `sdi-next-plan` skill. Neither belongs in this skill anymore.

### Verify-before-claim discipline

Every concrete reference in the generated artifacts — method, class, hook, file:line, precedent ("mirrors pattern of X"), count ("N sites to change") — must be preceded by Grep/Read confirming existence and shape in the codebase (or, for greenfield, that the named thing is being created by this very plan). Cite output verbatim when useful.

**Anti-pattern explicitly to avoid:** assertions like "(already exists in code)" / "(method available)" / "(N sites to change)" without Grep evidence immediately before the assertion. For greenfield Phase C: assertions about "this will be at `service/auth/`" must specify creation in the plan, not pretend the path exists.

**Doesn't apply** to narrative text (motivation, rationale) — only to concrete claims that the coding agent will use as evidence during implementation. When in doubt: if an adversarial reviewer could flag the claim with Grep, you should have Grep'd first.

**Worked examples (narrative vs concrete boundary):**

| Claim in plan | Category | Grep required? |
|---|---|---|
| "Bling rate limit is 3 req/s (per Bling V3 docs)" | Narrative (motivation, external source) | No — doesn't cite repo code |
| "Bling rate limiter is in `RateLimitService.acquire`" | Concrete (cites repo symbol) | **YES** — Grep `RateLimitService.acquire` |
| "Mirror the `OmieClient` pattern" | Concrete-precedent (cites symbol) | **YES** — Grep/Read `OmieClient` to confirm pattern |
| "10 sites of `validateMembership` to migrate" | Concrete-count | **YES** — Grep and count literally |
| "Auth helpers live in `service/auth/`" | Concrete-path | **YES** — Glob `service/auth/**` to confirm directory exists |
| "Users expect latency < 200ms" | Narrative (UX rationale) | No — doesn't cite code |
| "RateLimitService drops requests above threshold" | Concrete-behavior (claim about code) | **YES** — Read `RateLimitService` to confirm behavior |
| "(method already exists in code)" with no name | Antipattern — vague concrete | **YES** — name the method AND grep; OR remove the parenthetical |

Rule of thumb: **if a reviewer could open the file and say "this is wrong"**, it's concrete and needs Grep. **If the only validation is "does this make conceptual sense"**, it's narrative.

## Tone and writing style

- **Direct, low on hedging.** The user is a technical decision-maker. They want your position, not a list of "on one hand / on the other hand" without a conclusion. Have a recommendation; give it; be ready to defend or revise.
- **Specific over generic.** "Use Inngest because durable execution + native retry scheduling matches our 10min/30min pattern" is useful. "Use a job queue" is not.
- **Comfortable saying 'I don't know, let me search'.** For current state of tools, libraries, APIs, search before answering. Your training data is stale for fast-moving spaces.
- **Conversational language.** Reply in the user's conversational language. The English message templates in this skill and its references are authoring shells — render them in the user's language when speaking to them. Generated artifacts default to English (better alignment with code, easier i18n later); say so and offer to switch if the user asks.

## What not to do

- **Don't skip Phase 0.** Routing to the wrong type playbook means the wrong discovery questions and the wrong artifacts. If the user's idea is too vague to classify, ask one clarifying question, then offer the type list.
- **Don't generate artifacts in the first 2-3 turns.** Phase A/B first.
- **Don't dump every question at once.** Thematic batches of 2-3.
- **Don't rubber-stamp.** If the user proposes something risky, say so.
- **Don't pretend you know current tool versions.** Search.
- **Don't produce overly long artifacts.** The PRD isn't an encyclopedia — it's a decision record. Brief and precise beats comprehensive and vague.
- **Don't let the user skip Phase A.** If they say "just write me a PRD for X", run Phase 0 → ask the thematic questions. A PRD without scope work is a lottery ticket.

## References

Load these as needed (don't preemptively read all of them):

- `references/discovery-themes.md` — universal themes for Phase A/B questions
- `references/project-types/{type}/discovery.md` — type-specific themes (load after Phase 0)
- `references/modifiers/ai.md` — AI/LLM cross-cutting themes (load when modifier is active)
- `references/when-to-generate.md` — signals that scope is ready for artifacts
- `references/artifact-bundle.md` — canonical set, order, relationships
- `references/core-templates/prd-template.md` — PRD structure with section rationale
- `references/core-templates/architecture-template.md` — universal ARCHITECTURE structure
- `references/core-templates/roadmap-template.md` — phased roadmap format
- `references/core-templates/readme-template.md` — README index template
- `references/core-templates/implementation-plan-template.md` — universal implementation plan structure
- `references/core-templates/decisions-template.md` — empty decisions log scaffold generated at project birth
- `references/core-templates/known-issues-template.md` — empty known-issues catalog scaffold generated at project birth
- `references/core-templates/memory-template.md` — initial memory index and Phase C handoff entry
- `references/project-types/{type}/architecture-appendix.md` — type-specific architecture sections
- `references/project-types/{type}/project-structure-template.md` — repo layout per type
- `references/project-types/{type}/design-system-template.md` — visual language (only types with UI)
- `references/kickoff-prompt-template.md` — prompt the user pastes into the coding agent
- `references/agents-template.md` — canonical AGENTS.md / CLAUDE.md template (project facts only) used by Phase C
