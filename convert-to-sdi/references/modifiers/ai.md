# Modifier — AI / LLM components

A cross-cutting modifier that applies when the project has significant LLM/AI features. Activated automatically when the user answered "yes" to the AI modifier prompt in Phase 0 — and *always* loaded for `ai-agent` project type.

This modifier supplements the core skill flow with extra discovery questions, architectural concerns, project-structure additions, design-system notes, and implementation-plan considerations. It does **not** replace any artifact — it adds sections to existing ones.

## When this modifier applies

Load it whenever any of the following are true:
- Project type is `ai-agent` (always)
- User answered "yes" to the AI modifier prompt regardless of project type
- During Phase B/C the user introduces an LLM-driven feature (chat assistant, summarization, classification, retrieval, generation) — load even if it wasn't flagged in Phase 0

## Discovery additions

Pull these into the conversation alongside the type-specific discovery themes. Keep batches small (2–3 questions per turn).

### A. Use case shape

- What does the AI actually do — generate text, classify input, extract structure, retrieve and synthesize, agent that takes actions?
- Is this user-facing (chat, suggestion) or backend (categorize incoming records, route tickets)?
- Latency expectations — interactive (<2s response) or background (seconds-to-minutes acceptable)?
- Streaming expected on the user surface?

### B. Model and provider

- Provider preference (Anthropic, OpenAI, Google, open-weight via Bedrock/Vertex/local)?
- Specific tier — frontier-quality or fast/low-cost? Record the exact provider/model selected for the product.
- Multi-model strategy — primary + fallback, or single?
- Budget per request / per user / per month — set explicitly, not implied?
- Context window needs — fits in 8k, needs 100k+?

### C. Retrieval / RAG

- Is retrieval needed (knowledge base, docs, prior conversations)?
- Source corpus — size, update frequency, ownership?
- Retrieval approach — vector (which embedding model + store), full-text, hybrid, BM25?
- Chunking strategy — fixed-size, semantic, document-structure-aware?
- Re-ranking — yes/no, with what model?

### D. Prompts and management

- Prompt source of truth — strings in code, markdown files, prompt management tool (Helicone, PromptLayer, Langfuse, Latitude)?
- Versioning strategy — git-tracked, run-time switchable, A/B'd?
- Variable interpolation — explicit templating, no hidden mutation?
- Prompt review process — who approves changes?

### E. Evaluation

- Eval surface — exact match, LLM-as-judge, structured output validation, trajectory eval, human review?
- Golden set — hand-curated, sampled from logs, synthetic? Size?
- Cadence — every PR, nightly, weekly, manual?
- Regression policy — block merge on score drop, warn, or override-required?
- Cost per eval run?

### F. Cost and performance

- Token budget per turn / per session?
- Caching strategy — provider prompt caching, response caching, semantic cache?
- Batching opportunities — can multiple requests share a system prompt context?
- Hard kill switch — what happens at cost ceiling (degrade, fail, queue)?

### G. Guardrails and safety

- Prompt-injection defenses — input validation, response checking, tool gating?
- Refusal policy — does the model refuse certain categories?
- PII handling — what's allowed in prompts, what's redacted at log boundary?
- Human-in-the-loop — for which actions, with what approval flow?
- Output validation — JSON schema check, content filter, sanity ranges?

### H. Observability

- What's logged per LLM call (provider, model, tokens, cost, latency, request id)?
- Sampling — log everything or sample at rate N?
- Trace propagation — request id flows through tool calls, retrieval calls, model calls?
- Cost dashboard surface — per-user, per-feature, per-model?

## Architecture additions

Select only the sections below that are tied to the approved AI flow, a production constraint or a material risk. Omit the rest.

### §X.1 LLM provider layer

- State whether a provider wrapper is justified by multiple call sites or a shared auth/contract boundary
- If justified, keep only the required concerns there; retry, fallback, cost accounting, prompt cache and observability are separate opt-ins
- Unify streaming and non-streaming only when both modes exist and share a contract

### §X.2 Prompt management (when prompts need an independent lifecycle)

- Where prompts live (`src/prompts/`, file-based, versioned)
- Prompt versioning convention (`system.v1.md`, switch via env var)
- Variable interpolation pattern (explicit `{{var}}`, no hidden mutation)
- Diff/eval workflow when a prompt changes

### §X.3 Retrieval layer (if RAG)

- Embedding model + dimensions, vector store (Pinecone/Qdrant/Weaviate/pgvector/Chroma)
- Chunking strategy with rationale
- Index update pipeline (when corpus changes, how indexes refresh)
- Re-ranking pipeline (if applicable)

### §X.4 Eval pipeline (when an approved quality criterion needs scored behavior)

- Golden set location (`evals/`)
- Runner architecture (sync, async, batched)
- Scoring strategy (exact, LLM-judge with rubric, structured validation)
- Reporting (per-PR check, dashboard, alerts on regression)

### §X.5 Cost controls (when measured or contractually bounded spend requires them)

- Token budget enforcement points
- Per-tier or per-user limits
- Degradation strategy (fall back to cheaper model, cache more aggressively, fail-closed)
- Cost dashboard (per-feature, per-tier, per-period)

### §X.6 Safety

- Input validation chain (sanitization, classification of dangerous patterns, allowlist of intents)
- Output validation chain (schema, content filter, post-hoc judge)
- Tool gating (high-blast tools require explicit approval)
- Refusal logging (track refusal rate by category)

## Project structure additions

Add only directories selected by the architecture; do not scaffold wrappers, retrieval, eval or safety subsystems speculatively:

```
src/
├── llm/               # provider boundary, only if architecture justifies one
├── prompts/           # versioned system prompts and reusable fragments
├── retrieval/         # embedding, indexing, search, re-rank (if RAG)
├── evals/             # eval harness, only for an approved scored criterion
└── safety/            # guardrails — input validation, output validation, refusal handlers

evals/                 # golden sets (jsonl/yaml), at repo root or under docs/
prompts/               # markdown prompts in version control (alternative to src/prompts)
```

Conventions:

- When a provider boundary is justified, route the call sites covered by that boundary through it
- Version prompts when they have a release/review lifecycle independent from application code
- Review golden-set changes only when an approved eval contract uses that set
- Add tests or evals only under the framework's proportional evidence threshold

## Design system additions

If the project has a UI, add to DESIGN_SYSTEM.md:

### AI states

- **Loading / thinking:** indicator that LLM is working (different from network spinner — communicates "agent is processing")
- **Streaming:** in-progress text rendering with cursor; defer final formatting until complete
- **Tool call in progress:** if user-visible, show what tool is running
- **Error / fallback:** surface failure, and fallback only when the approved flow has one
- **Refusal:** model declined; show user-friendly message
- **Citation / source:** when output references retrieved sources, render cleanly

### Trust signals

- AI-generated content marker (when policy or law requires)
- "Why did the model say this?" affordance — explanation, sources, confidence
- Edit/regenerate controls

## Implementation plan additions

When generating IMPLEMENTATION_PLAN_PHASE_1.md, select only items required by the approved AI flow, contract or measured risk:

- **§ Provider boundary** — add a wrapper only when shared call-site or provider contracts justify it
- **§ Prompt skeleton** — initial system prompt committed; structure for future prompts in place
- **§ Eval evidence** — add a golden set/runner only for an approved scored quality criterion
- **§ Cost controls** — add only the limit or signal needed for a measured budget exposure
- **§ Safety basics** — input length cap, output validation for structured outputs, kill switch for runaway loops (if agent)

## Tone notes

When discussing AI projects:

- **Be honest about what LLMs can and can't do.** Many users overestimate capability.
- **Evidence follows the AI contract.** Use evals when product quality is expressed as scored behavior; use other targeted evidence for deterministic boundaries.
- **Cost controls follow exposure.** Raise ceilings or kill switches when usage, agent loops or a budget contract can materially overrun.
- **Prompt injection is real.** Especially for agent projects with tools, the threat model deserves attention.

## Common failure modes

- **Uncontrolled provider boundary.** Centralize only when repeated call sites or shared auth/contract behavior would otherwise drift.
- **Prompts as string literals.** No versioning, no diff, no eval — just changes appear in commits with no signal.
- **No evidence for an approved quality criterion.** Use the smallest test or eval capable of proving that criterion.
- **Unbounded material spend.** Add the narrowest control that enforces the approved budget.
- **Tool gating skipped.** High-blast tools (delete, send, charge) wired to the agent loop with no approval; eventually fires wrongly.
