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
│   ├── providers/          # only if a shared provider boundary is justified
│   ├── eval/               # only for an approved scored quality criterion
│   └── server/             # transport (MCP stdio/http, REST, websocket)
├── prompts/                # markdown prompts checked into version control
├── evals/                  # only when the approved eval contract needs datasets
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
- Log iteration/model/tool/cost fields when an approved budget, audit or recovery requirement needs them.
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
- Tests justified by material silent harm or an approved acceptance criterion may live next to the tool file (`tool-name.test.ts`).

## src/prompts/ — Prompts

\`\`\`
[tree — system prompts, reusable fragments, prompt versioning notes]
\`\`\`

### Prompt conventions

- System prompt is the only file allowed to be very large; everything else is composable.
- Version prompts only when they have a release/review lifecycle independent from application code.
- Variable interpolation is explicit (`{{user_name}}`, `{{tools_list}}`) — no hidden mutation.
- Link prompt diffs to eval results only when an approved eval contract requires them.

## src/memory/ — Memory layers

\`\`\`
[tree — short-term (conversation), long-term (vector/structured), policy modules]
\`\`\`

### Memory conventions

- Read and write paths are separated. A memory store has clearly named query/upsert methods.
- PII scrubbing happens at the write boundary, not on every read.
- Decay/expiration is documented per layer.

## src/eval/ — Eval harness (if required by an approved quality criterion)

\`\`\`
[tree — runner, scorers, output formatters]
\`\`\`

### Eval conventions

- Record only the dataset, report fields, judge prompts and baseline needed by the approved eval contract.

## src/server/ — Transport

\`\`\`
[tree — MCP stdio entry, optional HTTP server, websocket if streaming]
\`\`\`

## Coding Conventions

### Language-specific
- [TypeScript: strict mode, Zod for runtime validation, no `any`]
- [Python: type hints required, Pydantic for I/O, ruff/black]

### LLM SDK usage
- Add a provider wrapper only when shared call sites or auth/contract boundaries justify it.
- All API calls flow through the wrapper; add retry, fallback, cost accounting or logging only for the path's real contract/risk.
- Unify streaming and non-streaming only when both exist and share a contract.

### Logging & observability
- When a failure or cost overrun would be materially silent, log only the fields needed to detect/recover, with PII scrubbing.
- Propagate a trace ID when the approved flow crosses boundaries that must be correlated.

### Testing
- Add a unit/integration test only for material silent harm or an explicitly approved acceptance criterion.
- Use an eval suite only when product quality criteria define a scored behavior.

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
- **Prompt lifecycle follows risk.** Version or evaluate prompts only when the product contract needs that control.
- **Memory and eval are optional systems.** Give them structure only when approved behavior requires them.
- **Provider abstraction must earn its keep.** Do not wrap one call site solely for a hypothetical swap.
