# ARCHITECTURE Template (Core)

The ARCHITECTURE doc operationalizes the PRD. Stack, flows, security, observability, trade-offs. It's the reference doc the coding agent returns to most often outside of the per-phase implementation plans.

This template covers **universal sections** that apply to any project type. The `project-types/{type}/architecture-appendix.md` companion file fills in type-specific concerns: data model + persistence patterns for types with a database, multi-tenancy + RLS for SaaS, ingestion pipelines for data products, agent loop patterns for AI agents, etc.

When generating ARCHITECTURE.md, **merge the core sections below with the appendix sections from the chosen type**. Numbering is suggested but adjust as needed — the goal is one coherent doc, not two stitched together.

Target length: 500–700 lines (longer for complex types). Dense is fine; repetitive is not.

## Structure

```markdown
# [Product] — Architecture

> Companion to `PRD.md`. Describes technical decisions, stack, integrations, and critical flows.

## 1. Tech Stack

[Table: Layer, Choice, Rationale. Layers vary by project type — see appendix for type-specific layers. Universal layers usually include: language/runtime, primary framework, validation, observability, deployment, testing. For each, one-line rationale tied to the specific project, not a generic "it's popular".]

## 2. Type-specific architecture

[Insert content from `project-types/{type}/architecture-appendix.md` here. For SaaS this is the multi-tenancy model + data model + RLS. For landing pages this is static-gen strategy + CMS + edge config. For data pipelines this is ingestion → process → deliver. Etc.]

## 3. Critical Flows

[For each major flow (a key user action, a background workflow, an ingestion pass, an agent loop), a walkthrough:]

### 3.1 [Flow name]

```
[Start event]
  │
  ├─ [Service 1]
  │    1. [step]
  │    2. [step]
  │    ...
  │
  └─ [Service 2 / async job / next agent step]
       1. [step]
       2. [step]
       ...
```

[Or equivalent representation. The goal is: someone reading can answer "what happens when X?" in under 2 minutes.]

## 4. Security Considerations

[Stack-appropriate security concerns: webhook signature verification, secret handling, rate limiting, CSRF, PII scrubbing, query parameterization, prompt injection defenses (if AI), CSP for static sites, input validation at boundaries, etc. Reference appendix for type-specific isolation/access concerns.]

## 5. Observability & Operations

[Error tracking, product analytics, feature flags, job monitoring, alerting surfaces, log destinations. For AI projects also: eval pipeline, prompt version tracking, cost dashboards.]

## 6. [Integration-Specific Section]

[If there's one especially central integration — e.g. ElevenLabs, Stripe, Twilio, an LLM provider — a dedicated section covering: what we call, what we receive back, storage decisions (do we mirror their data or just reference?), error/retry posture, cost posture.]

## 7. Known Trade-offs & Risks

[Short list. Each item: what the trade-off is, why it's acceptable now, and the signal that would make it unacceptable later.]
```

## Writing tips

- **Schemas, infra diagrams, and policy fragments are sketches, not final.** Use language-appropriate shorthand (TypeScript types, Python dataclasses, SQL pseudo-schema, YAML pipeline). Indexes, policies, and scaling configs mentioned in text, not formalized.
- **Flows are walkthroughs, not pseudocode.** The purpose is understanding, not auto-generation.
- **Trade-offs section is real estate for honesty.** Every system has them. Hiding them now causes pain later. List 3–6 with escape hatches ("revisit when X").
- **Don't duplicate the PRD.** PRD says *what*; ARCHITECTURE says *how*. If you find yourself restating user roles or features in ARCHITECTURE, you're duplicating — trim.
- **Stack choices need rationale.** "We use [framework]." Why? A rationale sentence makes ARCHITECTURE defensible when someone questions it months later.

## Common failure modes

- **All decisions, no rationale.** "We use [tool]." Without rationale, the doc is undefendable.
- **Flows that are too abstract.** "Webhook arrives, we handle it." Useless. Concrete steps with data transforms.
- **Missing trade-offs section.** Every system trades something. If this section is empty, the doc is lying.
- **Speculative flows for Phase 3+ features.** Keep ARCHITECTURE focused on what Phase 1–2 need. Don't try to draw the whole endgame.
- **Skipping the type-specific appendix.** Without it, the doc lacks the prescription that makes it actionable for the chosen project type.

## Relation to other artifacts

- Feeds **ROADMAP** — flows here become phase deliverables there.
- Feeds **PROJECT_STRUCTURE** — type-specific patterns here hint at file/folder organization there.
- Feeds **IMPLEMENTATION_PLAN** — per-phase plans reference specific flows from here.
- Feeds **AGENTS.md / CLAUDE.md** — once implementation begins, the project-specific stack identified here gets recorded in the project fact sheet(s) so the coding agent always has the live truth.
