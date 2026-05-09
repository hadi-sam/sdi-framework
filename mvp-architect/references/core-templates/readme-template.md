# README Template

The README is the index of the docs bundle. It's the first file the coding agent reads. Keep it tight: ~30–80 lines. No long-form content — link out to the other artifacts.

## Structure

```markdown
# [Product Name]

> One-paragraph product summary. What it does, who it's for, the core value proposition. Read this first; everything else is detail.

## Stack at a glance

| Layer | Choice |
|---|---|
| [Layer e.g. Language] | [Choice e.g. TypeScript] |
| [Layer e.g. Framework] | [Choice] |
| [Layer e.g. Persistence] | [Choice or "n/a"] |
| [Layer e.g. Deployment] | [Choice] |
| ... | ... |

Full rationale lives in [`ARCHITECTURE.md`](./ARCHITECTURE.md).

## Project type

**Type:** [Web SaaS multi-tenant / Landing page / Dashboard / Web API / Mobile app / Data pipeline / AI agent / Automation workflow / Other — describe]
**AI/LLM modifier:** [yes / no]

## Documents

| Doc | Purpose |
|---|---|
| [PRD.md](./PRD.md) | What's being built and why. Users, roles, features in/out of scope. |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Stack, type-specific patterns, critical flows, security, trade-offs. |
| [ROADMAP.md](./ROADMAP.md) | Phased delivery plan with acceptance criteria. |
| [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md) | Repo layout and coding conventions. |
| [DESIGN_SYSTEM.md](./DESIGN_SYSTEM.md) | Visual language and tokens. *(only if UI exists)* |
| [IMPLEMENTATION_PLAN_PHASE_1.md](./IMPLEMENTATION_PLAN_PHASE_1.md) *or `IMPLEMENTATION_PLAN_<slug>.md`* | Detailed spec for the current work item. `PHASE_N` for discrete phases; `<slug>` for free-form work (features, maintenance) in ongoing projects. |
| [KNOWN_ISSUES.md](./KNOWN_ISSUES.md) | Append-only catalog of known bugs, security gaps, tech debt, and deferred fixes. Starts empty for greenfield projects. |
| [DECISIONS.md](./DECISIONS.md) | Append-only paper trail of non-obvious choices. Starts empty for greenfield projects. |
| [MEMORY.md](./MEMORY.md) + [memory/](./memory/) | Dated implementation memory and handoff notes. Starts with the Phase C handoff entry. |
| [AGENTS.md](../AGENTS.md) / [CLAUDE.md](../CLAUDE.md) | Project fact sheet for coding agents: stack, doc map, conventions, work tracker. Both files carry the same content; keep whichever your tools read. |

## How to use with a coding agent

The SDI discipline loads from the `sdi-mode` skill (Claude Code / Codex) or the configured `sdi-mode` custom mode (Roo Code / Kilo Code / OpenCode). `AGENTS.md` / `CLAUDE.md` carry only project facts — they do not carry discipline.

- **Claude Code / Codex.** Install the `sdi-mode` skill (alongside `mvp-architect` and `convert-to-sdi`) under the tool's skills path. The skill auto-invokes when you start implementation work. `AGENTS.md` and `CLAUDE.md` are already at the repo root with the same project facts; keep the file(s) your coding agents read. Paste the kickoff prompt from the current `IMPLEMENTATION_PLAN_*.md` to start the work item.
- **Roo Code / Kilo Code / OpenCode.** Configure the `sdi-mode` custom mode/agent following the appropriate guide in your local copy of `sdi-framework/installation-guides/`. Once active, paste the kickoff prompt from the current `IMPLEMENTATION_PLAN_*.md` to start the work item.

## Open questions deferred to production

[Things that are known but intentionally not decided yet — will be revisited at a specific signal. Examples: payment processor (decide when first paying customer), search engine (decide when corpus exceeds 10k docs), real-time vs polling (decide based on usage patterns at month 2).]

- [Open question — when to decide]
- ...
```

## Writing tips

- **The product summary is one paragraph.** If you need three, you don't understand the product yet.
- **Stack table is compact.** Full rationale belongs in ARCHITECTURE — don't duplicate.
- **Open questions are a feature, not a bug.** They make explicit what is decided to leave undecided. Without them, the next reader assumes everything is final.
- **Do not write the README first.** It's the last artifact, generated after PRD, ARCHITECTURE, ROADMAP, PROJECT_STRUCTURE, the first IMPLEMENTATION_PLAN, DECISIONS, KNOWN_ISSUES, and MEMORY exist — it indexes them.

## Common failure modes

- **README full of content instead of links.** README is the menu, not the meal. Link out.
- **Broken links to non-existent docs.** If the project skips DESIGN_SYSTEM (no UI), don't link it.
- **Vague summary.** "A platform for managing things" tells a reader nothing. The summary should differentiate this product from generic alternatives in one sentence.
