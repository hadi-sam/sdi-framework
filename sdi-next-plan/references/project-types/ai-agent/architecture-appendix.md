# Architecture Appendix — AI agent / MCP server / chatbot

Use these sections as the type-specific implementation lens for AI-agent, MCP-server, and chatbot work items. For cross-cutting LLM constraints, read the target project's existing `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, and any eval/prompt docs recorded in `AGENTS.md` / `CLAUDE.md`; this skill does not carry the initial-scoping AI modifier.

## §2.1 Agent topology

State the structural shape of the agent.

- **Type:** [Conversational chatbot] / [MCP server] / [Autonomous task agent] / [Embedded copilot] / [Workflow with LLM-in-the-middle]
- **Surface:** [Web chat] / [CLI] / [MCP stdio/http] / [REST API consumed by another product] / [Slack/Discord bot]
- **Loop shape:** [Single-shot completion] / [Tool-using agent loop with N max iterations] / [Constrained workflow — fixed steps with LLM nodes] / [Multi-agent (orchestrator + workers)]
- **Concurrency:** Single-tenant per session vs. shared queue. Maximum parallel sessions before backpressure.

## §2.2 Tool catalog

The most consequential design surface. Each tool gets a row.

| Tool name | Purpose | Inputs | Outputs | Side effects | Blast radius |
|---|---|---|---|---|---|
| `read_file` | Read a project file | path | content + metadata | none | low |
| `run_query` | Execute a read-only DB query | sql | rows | none | low |
| `send_email` | Send a transactional email | to, subject, body | confirmation id | external send | high — irreversible |
| ... | ... | ... | ... | ... | ... |

For each high-blast-radius tool: state idempotency strategy, dry-run mode, audit log destination, human approval requirement.

Tool authorization model:
- [ ] All tools always available
- [ ] Tools gated by user role / scope
- [ ] Per-call human approval for high-blast-radius tools
- [ ] Dynamic registration (e.g., MCP discovery)

## §2.3 Memory architecture

- **Conversation memory:** [held in transcript only] / [summarized after N turns] / [stored in DB indexed by session_id]
- **Episodic memory:** [vector store with embedding model X] / [structured tables of (user, fact, source, timestamp)] / [file-based notes]
- **Semantic memory:** [knowledge base loaded into context per turn] / [retrieved via RAG] / [pre-baked into system prompt]
- **Memory write policy:** when does the agent write to long-term memory? [Explicit user request only] / [Auto after every turn with importance scoring] / [Curated by a separate memory agent]
- **Memory read policy:** what's in context for each turn? [Last N turns + retrieved facts] / [Full history up to context limit, then summarize]

## §2.4 Model orchestration

- **Primary model:** [provider/model + version pin]
- **Fast/cheap model for routing/classification:** [provider/model]
- **Fallback chain:** if primary fails or rate-limits, fallback to [model], then [model]
- **Streaming:** [yes/no] for the user-facing surface
- **Prompt caching:** [Anthropic prompt cache / OpenAI cached input / none]
- **Cost ceiling per turn:** [N tokens or $X], with [hard fail / graceful degradation] when hit

## §2.5 Guardrails

- **Input validation:** [Zod-style schema on tool inputs] / [LLM-as-judge for prompt-injection patterns] / [allow-list of accepted intent categories]
- **Output validation:** [JSON schema validation] / [content filters] / [post-hoc LLM-as-judge for policy compliance]
- **Tool gating:** [allow-list of safe tools by default; high-blast tools require user confirmation]
- **Refusal policy:** [system prompt directives + monitoring] / [external moderation API] / [both]
- **Loop limits:** max iterations per task, max tools called per iteration, max wall-clock time

## §2.6 Eval pipeline

Read the target project's existing eval/prompt docs and DECISIONS entries for cross-cutting eval discipline. Type-specific notes:

- **Golden set source:** [hand-curated], [sampled from production logs after PII scrub], [synthetic via stronger model]
- **Eval surface:** [exact match for structured outputs], [LLM-as-judge with rubric], [trajectory eval — were the right tools called in the right order?], [human review for subjective quality]
- **Regression workflow:** when eval scores drop on a PR, [block merge] / [warn but allow] / [require explicit override]
- **Cost of one eval run:** [$X], frequency: [every PR / nightly / weekly]
