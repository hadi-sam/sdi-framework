# PROJECT_STRUCTURE Template

Repo layout and coding conventions. Read by the coding agent as context when generating code.

Target length: 300–450 lines.

## Structure

```markdown
# [Product] — Project Structure & Conventions

> Folder layout and coding conventions for the [framework] app. Designed to be read by the coding agent as context when generating code.

## Top-Level Layout

\`\`\`
[repo-root]/
├── .github/                # CI workflows
├── [migrations-dir]/       # generated migrations (checked in)
├── public/                 # static assets
├── src/
│   ├── app/                # App Router routes
│   ├── components/         # reusable UI
│   ├── db/                 # schema + client + migrations source
│   ├── lib/                # domain logic, clients, utilities
│   ├── inngest/            # background jobs (if applicable)
│   ├── ai/                 # AI skill wrappers (if applicable)
│   └── types/              # shared TypeScript types (create only when needed)
├── tests/                  # integration & e2e tests
├── docs/                   # PRD, ARCHITECTURE, DECISIONS, KNOWN_ISSUES, MEMORY, etc.
└── [config files]
\`\`\`

## src/app/ — Routes

\`\`\`
[tree of route groups and key routes with short comments]
\`\`\`

## src/db/ — Database Layer

\`\`\`
[tree]
\`\`\`

### Schema Conventions

- [bullets — one file per table, timestamptz always, enums as pgEnum when stable, etc.]

## src/lib/ — Domain Logic

\`\`\`
[tree]
\`\`\`

## src/inngest/ — Background Jobs (if applicable)

\`\`\`
[tree]
\`\`\`

### Event Conventions

[How events are named, how payloads are validated, how handlers are organized.]

## src/ai/ — AI Assistant (if applicable, may be marked "Phase 4+, not present")

\`\`\`
[tree or "Created later"]
\`\`\`

## src/components/ — UI

\`\`\`
[tree]
\`\`\`

## Coding Conventions

### TypeScript
- [rules — strict mode, preferred types, no `any`, etc.]

### React
- [patterns — server components by default, data fetching, forms, error boundaries]

### API Routes
- [patterns — thin routes, validation via Zod, auth gates]

### Testing
- [patterns — Vitest for unit, integration with local [DB], manual smoke]

### Commits & Branches
- [conventional commits, branch naming]

### Environment Variables
- [shape of .env.example, grouping]

## Claude Code Kickoff Prompt Template

[End-of-doc prompt template — what the user pastes into the coding agent on day one. Keeps the repo docs self-contained.]
```

## Writing tips

- **Keep the top-level layout small and stable.** Deeply nested directories are harder to navigate.
- **Short comments per directory.** The tree is scanned; long explanations belong in prose sections.
- **Conventions should be specific.** "Use TypeScript strict mode" is generic. "`noUncheckedIndexedAccess: true`; no `any` in production code; `unknown` + narrowing instead" is specific.
- **Don't pre-create empty directories.** If `src/types/` will only be needed later, don't list it as existing — say "create when needed."
- **Mark future-only directories explicitly.** If `src/ai/` is a Phase 4+ concern, label it in the tree ("not present at Phase 1") so the coding agent doesn't assume it should create it.

## Common failure modes

- **Aspirational vs actual drift.** The doc lists directories that aren't in the repo. Over time this confuses readers. Keep in sync at end of each phase.
- **Over-specific conventions.** "Use this specific naming pattern for this specific case" that doesn't matter. Keep conventions to the ones that actually affect code quality or consistency.
- **Missing kickoff prompt.** The coding agent needs a way to start; provide one.
- **Outdated paths referenced in other docs.** If PROJECT_STRUCTURE says "use `src/lib/auth/guards.ts`" and the repo has `src/lib/auth/session.ts`, other plans will inherit the wrong reference. Update at end of each phase.
