# PROJECT_STRUCTURE Template — AI agent / MCP server / chatbot

Repo layout and conventions for an LLM-driven agent project. Adapt to the chosen language/runtime.

Target length: 200–350 lines.

## Structure

```markdown
# [Product] — Project Structure & Conventions

> Folder layout and conventions for the [Anthropic SDK / OpenAI SDK / Vercel AI SDK / mcp-python / mcp-typescript / etc.] agent. Read by the coding agent as context when generating code.

## Top-Level Layout

\`\`\`
[repo-root]/
├── .github/                # CI workflows
├── src/
│   ├── agent/              # core agent loop + orchestration
│   ├── tools/              # tool implementations (one file per tool)
│   ├── prompts/            # system prompt + reusable prompt fragments
│   ├── memory/             # short-term + long-term memory layers
│   ├── guardrails/         # input/output validators, refusal policy
│   ├── providers/          # LLM client wrappers, fallback chains
│   ├── eval/               # eval harness + golden sets
│   └── server/             # transport (MCP stdio/http, REST, websocket)
├── prompts/                # markdown prompts checked into version control
├── evals/                  # golden datasets (jsonl/yaml)
├── tests/                  # unit + integration tests
├── docs/                   # PRD, ARCHITECTURE, DECISIONS, KNOWN_ISSUES, MEMORY, etc.
└── [config files]
\`\`\`

## src/agent/ — Core loop

\`\`\`
[tree showing the loop entry, iteration controller, tool dispatcher, message reducer]
\`\`\`

### Loop conventions

- One loop file owns the main agent iteration. No tool dispatch logic spread across files.
- Max iterations is a config knob, not a magic number.
- Every iteration logs: model used, tool calls made, tokens consumed, cost delta.
- Early-stop conditions are explicit: success signal from agent, budget exhausted, error budget exceeded.

## src/tools/ — Tool implementations

\`\`\`
[tree — one file per tool, plus an index that aggregates them]
\`\`\`

### Tool conventions

- One tool per file. Filename matches the tool name.
- Each tool exports: name, description (used in tool list), input schema (Zod / Pydantic / JSON Schema), execute function.
- Idempotent tools mark themselves as such in metadata.
- High-blast-radius tools require an explicit approval flag in the call signature.
- Tests live next to the tool file (`tool-name.test.ts`) and exercise both happy path and error cases.

## src/prompts/ — Prompts

\`\`\`
[tree — system prompts, reusable fragments, prompt versioning notes]
\`\`\`

### Prompt conventions

- System prompt is the only file allowed to be very large; everything else is composable.
- Prompts are versioned: `system.v1.md`, `system.v2.md`, etc. Switch via env var or model registry.
- Variable interpolation is explicit (`{{user_name}}`, `{{tools_list}}`) — no hidden mutation.
- Prompt diffs accompany eval results in the PR description.

## src/memory/ — Memory layers

\`\`\`
[tree — short-term (conversation), long-term (vector/structured), policy modules]
\`\`\`

### Memory conventions

- Read and write paths are separated. A memory store has clearly named query/upsert methods.
- PII scrubbing happens at the write boundary, not on every read.
- Decay/expiration is documented per layer.

## src/eval/ — Eval harness

\`\`\`
[tree — runner, scorers, output formatters]
\`\`\`

### Eval conventions

- Golden sets live in `evals/*.jsonl` (or yaml). One scenario per record.
- Each eval run produces a report file with score, cost, latency.
- LLM-as-judge prompts live in `evals/judges/`.
- A baseline score is committed; PRs that regress need explicit reason in commit message.

## src/server/ — Transport

\`\`\`
[tree — MCP stdio entry, optional HTTP server, websocket if streaming]
\`\`\`

## Coding Conventions

### Language-specific
- [TypeScript: strict mode, Zod for runtime validation, no `any`]
- [Python: type hints required, Pydantic for I/O, ruff/black]

### LLM SDK usage
- One wrapper module per provider. App code never calls SDK directly.
- All API calls flow through the wrapper, which adds: retry, fallback, cost accounting, logging.
- Streaming and non-streaming go through the same surface.

### Logging & observability
- Every LLM call logs: provider, model, latency, input tokens, output tokens, cost, request id.
- Tool calls log: name, input (PII-scrubbed), output (PII-scrubbed), duration, success/failure.
- Trace ID propagates from request → loop iteration → tool calls → LLM calls.

### Testing
- Unit tests for each tool, each prompt template renderer, each guardrail.
- Integration tests: a fixed transcript replay confirms the agent loop converges as expected on canonical inputs.
- Eval suite is separate from tests — slower, scored, run on a cadence.

### Commits & Branches
- [conventional commits, branch naming]

### Environment Variables
- API keys: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, etc.
- Knobs: `AGENT_MAX_ITERATIONS`, `AGENT_COST_CEILING_USD`, `MODEL_PRIMARY`, `MODEL_FALLBACK`.
- Feature flags: `ENABLE_HIGH_BLAST_TOOLS`, `ENABLE_LONG_TERM_MEMORY`.

## Coding agent kickoff prompt template

[End-of-doc prompt template — what the user pastes into the coding agent on day one. Keeps the repo docs self-contained.]
```

## Writing tips

- **Tool surface is what makes or breaks the agent.** Spend most of the structure doc on the tools/ conventions.
- **Prompts are code.** Version them, diff them, eval them. Don't bury them in string literals.
- **Memory and eval are systems, not afterthoughts.** Give each its own directory and conventions.
- **Wrap the SDK.** App code calling Anthropic/OpenAI directly makes provider swaps painful and observability inconsistent.
