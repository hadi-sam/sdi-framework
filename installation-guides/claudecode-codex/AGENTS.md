# Project Agent Facts

> Project-specific **fact sheet** for the SDI workflow. Generated into both `AGENTS.md` and `CLAUDE.md` so the user can keep whichever file(s) their coding agents read.
>
> **Edit only project facts** (stack, doc map, conventions, work tracker).
> **Never inject discipline rules** (audit steps, checkpoint behavior, tone, document precedence) — those live in the `sdi-mode` skill (Claude Code / Codex) or custom mode (Roo Code / Kilo Code / OpenCode) and propagate from there.
>
> - **Fact** → "DECISIONS.md lives at `docs/DECISIONS.md`", "KNOWN_ISSUES.md lives at `docs/KNOWN_ISSUES.md`", "Test runner: vitest", "Auth helpers in `src/lib/auth/`".
> - **Instruction** (do **not** put here) → "When you make a non-obvious choice, append to DECISIONS.md", "Stop at checkpoints", "Audit before coding".

---

## Operating context

This project follows the SDI (Spec-Driven Implementation) workflow. The implementation discipline is loaded from the `sdi-mode` skill (Claude Code / Codex) or the configured `sdi-mode` custom mode (Roo Code / Kilo Code / OpenCode). This file carries only the project-specific facts the agent needs in every session.

For the discipline itself (8-step loop, audit-first protocol, stop-and-review checkpoints, document precedence, tone, references), invoke / activate `sdi-mode`.

## Project context

- **Type:** [filled by `mvp-architect` Phase 0 — e.g., "Web app SaaS multi-tenant"]
- **AI/LLM modifier:** [yes / no — if yes, also see `docs/ARCHITECTURE.md` AI sections and operate under AI guardrails]
- **Stack:** [filled during/after planning — e.g., "Next.js 15 App Router + Drizzle + Postgres + Supabase Auth + Inngest"]
- **Primary deployment target:** [Vercel / Fly / Railway / EAS / etc.]

## Document map

All planning docs live under `docs/` unless noted:

- `docs/README.md` — index
- `docs/PRD.md` — product requirements
- `docs/ARCHITECTURE.md` — stack + type-specific structural model + critical flows + trade-offs
- `docs/ROADMAP.md` — phased delivery
- `docs/PROJECT_STRUCTURE.md` — repo layout and conventions
- `docs/DESIGN_SYSTEM.md` — visual language *(only if UI exists)*
- `docs/IMPLEMENTATION_PLAN_*.md` — detailed spec for the current work item. `PHASE_N` for discrete phases (greenfield/migrations); `<slug>` for free-form work (features, maintenance) in ongoing projects.
- `docs/KNOWN_ISSUES.md` — append-only catalog of known bugs, security gaps, technical debt, and deferred fixes
- `docs/DECISIONS.md` — running paper trail of non-obvious choices *(append-only, atemporal)*
- `docs/MEMORY.md` — index of daily memory entries
- `docs/memory/YYYY-MM-DD.md` — daily session memory: active round, blockers, next step, open questions
- `docs/WORK_LOG.md` — verbose per-work-item narrative; the **Work tracker** section is its one-line index

## Project-specific conventions

*Populated as the agent discovers them during audit and implementation. The agent proposes additions; the user approves before they land.*

### Stack details

- [e.g., "Auth helpers: `requireRole()` and `requireRoleApi()` in `src/lib/auth/session.ts`"]
- [e.g., "Schema directory: `drizzle/`, with migrations named `NNNN_description.sql`"]
- [e.g., "Test runners: `vitest` for unit (in `*.test.ts`), `vitest --config integration.config.ts` for integration"]

### File / directory conventions

- [e.g., "API routes: `src/app/api/<resource>/route.ts`, never directly fetch in components"]
- [e.g., "Domain logic: `src/lib/<domain>/`; never in route handlers"]

### Convention exceptions

- [e.g., "`src/legacy/` follows older patterns — don't touch unless explicitly scoped in a phase"]

## Work tracker

One-line index per work item — current status + pointers, nothing more. The full narrative of each item lives in [`docs/WORK_LOG.md`](docs/WORK_LOG.md) and in the canonical artifacts each row links (the plan, `docs/memory/`, `DECISIONS.md`, `KNOWN_ISSUES.md`). Keep each `Notes` cell to a single line — new detail goes to `WORK_LOG.md` and those artifacts, never bloats a cell here.

| Work item | Type | Status | Date | Notes |
|---|---|---|---|---|
| Phase 0 (scaffolding) | phase | [pending / ✓] | [YYYY-MM-DD] | [one line: plan link + key pointers] |
| Phase 1 | phase | [pending / in progress / ✓] | | |
| ... | | | | |

`Type` accepts: `phase` (discrete numbered phases — greenfield, migrations) | `feature` | `maintenance` | `migration` | `refactor` | `perf` | `bugfix`. `Work item` accepts `Phase N` or a slug (e.g. `billing-portal`, `q1-perf-pass`). Each row corresponds to one `IMPLEMENTATION_PLAN_*.md` and, once the item closes, to one `## <work item>` section in [`docs/WORK_LOG.md`](docs/WORK_LOG.md).

## Updating this file

This file is **living** for project facts only. Every phase reveals new project-specific conventions — add them under the relevant section. Every phase completes — update the work tracker (keep rows one-line; the closing item's full narrative goes to `docs/WORK_LOG.md`).

Two rules:

1. Edit only project facts. If you find yourself writing behavioral instructions ("the agent should...", "always do X before Y"), stop — that belongs in the `sdi-mode` skill/mode, not here.
2. Propose updates explicitly; don't silently mutate. The user reviews and approves changes.
