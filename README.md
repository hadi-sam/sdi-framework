# SDI Framework

> **Spec-Driven Implementation** — a workflow for using coding agents on software projects, from rough idea to shipped feature.

SDI is opinionated about *how* work is done, not *what* the product becomes. Five skills cover the lifecycle: scope a greenfield product, onboard an existing codebase, orchestrate implementation against specs, review work, plan the next round.

Stack-agnostic. Single-developer friendly. Designed for IDE-based AI coding tools.

## Skills

| Skill | Purpose | Use when |
| --- | --- | --- |
| `mvp-architect` | Turn an idea into the initial spec bundle (PRD, ARCHITECTURE, ROADMAP, PROJECT_STRUCTURE, IMPLEMENTATION_PLAN_PHASE_1, DECISIONS, KNOWN_ISSUES, MEMORY, WORK_LOG, AGENTS/CLAUDE.md). | Starting greenfield. |
| `convert-to-sdi` | Adopt SDI on a project that already has code. Documents reality without editing source. | Joining a legacy project or formalizing an in-flight one. |
| `sdi-mode` | Orchestrate proportional implementation against specs: audit-first, profiled Engineers, risk-based review/checkpoints, decisions, known issues and memory. | Writing code from an SDI plan. |
| `sdi-review` | SDI-aware review coordinator for plans, rounds, fork decisions and bugs. Dispatches the work-item reviewer profile; reviewers get the prompt, never the skill. | Mid-implementation second pair of eyes. |
| `sdi-next-plan` | Generate the next `IMPLEMENTATION_PLAN_*.md` after a phase or feature closes. | Between work items in an ongoing project. |

`mvp-architect`, `convert-to-sdi`, and `sdi-next-plan` produce planning artifacts. `sdi-review` reviews them. `sdi-mode` orchestrates execution — the PM dispatches Engineers and a reviewer ensemble (see [Execution model](#execution-model)). The project's `AGENTS.md` / `CLAUDE.md` carry only project facts (stack, doc map, conventions).

## Quick Start

| Situation | Use |
| --- | --- |
| Rough idea, nothing built | `mvp-architect` Phase 0 → A → B → C, then `sdi-mode`. |
| Existing codebase | `convert-to-sdi` Phase 0 → 1 → (1.5) → 2 → 3, then `sdi-mode`. |
| Implementing a planned work item | `sdi-mode`. |
| Mid-implementation review | `sdi-review`. |
| Phase closed, plan the next | `sdi-next-plan`. |

After `convert-to-sdi` runs once on a project, don't run it again. Use `sdi-next-plan` for subsequent plans.

## Installation

Each skill is a self-contained directory (`SKILL.md` + `references/`). Copy the whole directory; don't cherry-pick files. `AGENTS.md` and `CLAUDE.md` are generated *for the target project* by `mvp-architect` or `convert-to-sdi` — they are not part of this repo's installation.

### Claude Code / Codex

Install the five skills as either project- or user-scoped:

- Claude Code: `.claude/skills/<skill>/` or `~/.claude/skills/<skill>/`
- Codex: `.codex/skills/<skill>/` or `$CODEX_HOME/skills/<skill>/` (defaults to `~/.codex/skills/`)

Skills auto-invoke from their descriptions. Restart Codex after adding skills.

`sdi-mode` uses native subagents when the selected profile and required read/write boundary are available. Otherwise it can use a supported tool's CLI with explicit model/effort and an isolated worktree (Engineer) or fresh read-only session (Reviewer). There is no default roster or automatic fallback. See [`sdi-mode/references/roles-and-orchestration.md`](sdi-mode/references/roles-and-orchestration.md) for confirmed cross-tool recipes.

The installer accepts one or more skill destinations in a single transaction:
`./install.sh /path/to/skills-a /path/to/skills-b`. With no path it preserves
the existing single-destination behavior (`SKILLS_DIR` or the default). It
preflights all destinations before copy and prints a restore command backed by
an ephemeral snapshot for post-install smoke recovery.

### Roo Code, Kilo Code, OpenCode

These tools use custom modes / agents. Configure `sdi-mode` per the relevant guide:

- Roo Code: [`installation-guides/roocode.md`](installation-guides/roocode.md)
- Kilo Code: [`installation-guides/kilocode.md`](installation-guides/kilocode.md)
- OpenCode: [`installation-guides/opencode.md`](installation-guides/opencode.md)

For the other skills, use the tool's native skill/agent system and keep the names (`mvp-architect`, `convert-to-sdi`, `sdi-review`, `sdi-next-plan`) so portability holds.

> When pasting `SKILL.md` content into a non-skill tool, start at the first `#` heading and drop the YAML frontmatter at the top of the file.

Tools that only support always-applied global rules are not supported — SDI assumes implementation discipline is loaded on demand.

## Project Types

`mvp-architect` Phase 0 routes to one of eight playbooks: **web SaaS multi-tenant, landing page, dashboard / admin, web API, mobile, data pipeline, AI agent / MCP, integration / automation**. An optional AI/LLM modifier adds prompts/evals/cost/RAG/guardrail concerns to any type. If the project fits none, the skill asks whether to adapt on the fly or stop.

## Core Disciplines

These live in `sdi-mode/SKILL.md` and load on demand. They are never copied into `AGENTS.md` / `CLAUDE.md`.

1. **Audit the plan against the repo before coding.** The repo wins when it disagrees with the plan; the plan gets a revision note.
2. **Use proportional checkpoints and binary gates.** Each must map to a real risk, decision, delivery boundary, acceptance criterion or mandatory project gate.
3. **Maintain decisions and memory separately.** Durable rationale in `docs/DECISIONS.md`; dated state in `docs/memory/YYYY-MM-DD.md`; factual result/evidence/consequence links in `docs/WORK_LOG.md` at close.
4. **Maintain known issues separately.** `docs/KNOWN_ISSUES.md` with append-only lifecycle status.
5. **Respect document precedence.** Live repo > `AGENTS.md` / `CLAUDE.md` > `PRD` > `ARCHITECTURE` > `ROADMAP` > `PROJECT_STRUCTURE` > `IMPLEMENTATION_PLAN` > `DESIGN_SYSTEM` > `README`. The fact sheet wins on **facts**, not on **scope**, which is the PRD's. `DECISIONS` patches authority; `KNOWN_ISSUES` catalogs wrongness; `docs/memory/` is breadcrumbs, not source of truth.

## Execution model

`sdi-mode` runs as a **multi-agent** loop, not a single agent writing code. Three roles:

- **PM / orchestrator** (the main session) — runs the audit, writes briefs, dispatches subagents, reconciles verdicts, and owns the entire paper trail. Never writes or reviews code itself.
- **Engineer** (selection persisted in plan §0 and reused for normal/Fix/Merge) — writes the smallest sufficient change in an exclusive worktree and runs scoped checks; never touches the paper trail.
- **Reviewer** (profile persisted in plan §0) — independently reviews the same packet in a fresh read-only session and returns a verdict.

Independent review is used where risk or contract warrants it. Findings are deduplicated into a Decision Bundle; instrumental or documentary findings block only when they expose a real defect/material silent harm, break an existing mandatory gate, or invalidate the only evidence for an approved acceptance criterion. The cap remains canonical in [`sdi-mode/references/auto-review-mode.md`](sdi-mode/references/auto-review-mode.md) §"Loop cap".

Full spec: [`sdi-mode/references/roles-and-orchestration.md`](sdi-mode/references/roles-and-orchestration.md) (roles + tool scoping, Engineer fan-out, the prompt-not-skill reviewer dispatch, brief templates) and [`sdi-mode/references/auto-review-mode.md`](sdi-mode/references/auto-review-mode.md) (the reviewer-ensemble mechanics it reuses). The same ensemble is also available user-invoked through `sdi-review`.

## Generated Artifacts

After `mvp-architect` or `convert-to-sdi`, a project typically has, under `docs/`: `PRD.md`, `ARCHITECTURE.md`, `ROADMAP.md`, `PROJECT_STRUCTURE.md`, `IMPLEMENTATION_PLAN_*.md`, `KNOWN_ISSUES.md`, `DECISIONS.md`, `MEMORY.md` (+ `memory/YYYY-MM-DD.md`), `WORK_LOG.md`, and `DESIGN_SYSTEM.md` (UI projects only). Plus `AGENTS.md` / `CLAUDE.md` at repo root carrying the same project facts, with a one-line Work tracker indexing `WORK_LOG.md` where the project keeps one and `docs/plans/` as the index where it doesn't.

## What SDI Is Not

- **Not a code reviewer.** `sdi-mode` is the PM/orchestrator; profiled Engineers author code and profiled reviewers independently assess it when justified.
- **Not an auto-approver.** Open decisions, irreversible/production actions and material risks remain user-gated. Review PASS never substitutes for a required live smoke or PR approval.
- **Not a refactor agent.** `convert-to-sdi` documents reality; it never edits source.
- **Not scope-from-scratch for in-flight projects.** Use `sdi-next-plan`.
- **Not bureaucracy.** Friction should earn its keep by improving clarity, quality, or auditability.

## Language

Source files are authored in English. Generated artifacts default to English for code/i18n alignment. At runtime, skills mirror the user's conversational language — start in Portuguese, get Portuguese back. Ask if you want generated artifacts in another language.

## Contributing

Issues and PRs welcome. Useful areas:

- New project types (browser extensions, CLI tools, ML pipelines, embedded).
- New modifiers beyond `ai.md`.
- Installation-guide improvements.
- Documentation corrections and examples.

Contributions should follow SDI's own discipline: plan, audit, implement in reviewable rounds, record decisions when they matter.
