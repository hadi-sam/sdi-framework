# Discovery — AI agent / MCP server / chatbot

Type-specific themes for projects whose primary deliverable is an LLM-driven agent, an MCP server exposing tools/resources, or a chatbot. Load alongside `references/discovery-themes.md` and `references/modifiers/ai.md` (the AI modifier should be active automatically for this type).

## ⚡ 1. Agent shape and surface

What kind of agent is this, and how do users interact with it?

Typical questions:
- Single-turn (one prompt → one response) or multi-turn conversation?
- Reactive (responds to user) or proactive (initiates, schedules, watches)?
- Autonomous loop (agent decides next action) or constrained workflow (fixed steps with LLM in the middle)?
- Surface — chat UI, CLI, MCP server consumed by another agent, embedded in another product, headless API?
- Identity — single shared agent, per-user agent, persona switching?

## ⚡ 2. Protocol and integration shape

How does the agent talk to the world?

Typical questions:
- MCP server (exposing tools/resources/prompts) or A2A or custom protocol?
- If MCP: stdio transport, HTTP, both?
- Tool surface — read-only tools, write tools, dangerous tools (deletes, irreversible ops)?
- Resource surface — files, DB queries, API responses?
- Authorization — does each tool call need explicit approval, or trust the agent inside a bounded scope?

## ⚡ 3. Model and provider

This drives cost, latency, capability ceiling, and many architecture choices.

Typical questions:
- Provider — Anthropic, OpenAI, Google, open-weight via Bedrock/Vertex/local?
- Specific model tier — frontier-quality or fast/low-cost? Record the product's exact provider/model choice.
- Fallback strategy if primary model fails or rate-limits?
- Streaming required, or batch/sync acceptable?
- Context window needs — small (few-shot prompts) or large (long docs, deep history)?

## 4. Tools and capabilities

The biggest design surface for agentic systems.

Typical questions:
- What's the canonical list of tools the agent will have access to?
- For each tool: what does it do, what are its inputs/outputs, what's the blast radius if it misfires?
- Side-effecting tools — idempotency keys, dry-run mode, audit logging?
- Tool composition — can the agent chain tools, or is each call independent?
- Tool discovery — fixed list at startup, dynamic from a registry, user-configurable?

## 5. Memory and state

Most non-trivial agents need some persistence beyond a single turn.

Typical questions:
- Short-term memory (conversation history) — held in transcript, summarized, both?
- Long-term memory (facts about user, prior decisions) — file-based, vector store, structured DB?
- Cross-session — does the agent remember between separate user sessions?
- Memory boundaries — per-user, per-project, global?
- Forgetting / expiration — manual purge, time-based, never?

## 6. Evaluation and quality

Without eval, you can't tell if changes help or hurt.

Typical questions:
- Golden set — small set of known-good inputs with expected outputs/behaviors?
- Eval cadence — every commit, every prompt change, weekly?
- Eval surface — exact string match, LLM-as-judge, structured output validation, human review?
- Regression tracking — when scores drop, what's the workflow?
- Cost target per eval run?

## 7. Guardrails and safety

What can the agent do wrong, and how do we prevent it?

Typical questions:
- Prompt injection defenses — input sanitization, response validation, tool-call gating?
- Refusal policy — does the agent refuse certain categories of request?
- Cost ceilings — max tokens per turn, max cost per session, kill-switch?
- Human-in-the-loop — for which actions, with what approval flow?
- Logging — what's logged for audit (prompts, completions, tool calls, costs)?

## 8. Cost and latency posture

Often only addressed when bills get scary.

Typical questions:
- Expected cost per session / per user / per month?
- Latency target — interactive (<2s) or background-acceptable (>10s OK)?
- Caching strategy — prompt caching, response caching, semantic caching?
- Batching opportunities — can multiple requests share a context?

## How to use

1. Themes 1, 2, 3 are the highest leverage — get those answered before anything else.
2. Theme 4 (tools) is where most of the design happens. Expect it to be the longest discussion.
3. Ask Themes 6 and 7 only to the depth warranted by an approved quality criterion or a reachable safety/tool risk.
4. The AI modifier (`modifiers/ai.md`) supplements this with cross-cutting AI themes; ensure both load in Phase A.
