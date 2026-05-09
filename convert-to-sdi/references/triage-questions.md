# Triage questions (Phase 1)

Exactly 5 questions. Each accepts **"don't know / skip"** as a valid answer with a defined skip behavior. Do not ask follow-ups.

The audit ran in Phase 0 and produced a discovery report. These questions confirm or correct the report's findings.

## Asking style

Batch all 5 in one message, OR ask one at a time if the user prefers (some users handle batches better; others prefer step-by-step). Either way, keep the questions short, with the auto-detected default visible so the user can confirm with a single word.

## The 5 questions

### Q1 — Project type

```
**Q1.** Auto-audit detected type: **[Type detected]** (confidence: [high/medium/low]).

Confirm? If wrong, which of the 8 types is correct?
1. Web app SaaS multi-tenant
2. Landing page / marketing site
3. Dashboard / admin / internal tool
4. Web API / backend service
5. Mobile app
6. Data pipeline / scraper + reports
7. AI agent / MCP server / chatbot
8. Integration / automation workflow
9. Other — describe
0. Don't know / skip
```

**Skip behavior (0):** Keep the auto-detected type with a low-confidence flag in `AGENTS.md` / `CLAUDE.md`. The framework still works; user can correct later by editing the project fact sheet(s).

### Q2 — AI modifier

```
**Q2.** Auto-audit detected AI modifier: **[yes/no]** ([signals if yes]).

Does the product have a significant LLM/AI component? yes / no / don't know
```

**Skip behavior (don't know):** Use the auto-detected value. If signals were present, mark as "yes (auto-detected)"; if not, mark as "no (auto-detected)". The user can flip this later.

### Q3 — Project stage

```
**Q3.** Auto-audit suggests stage: **[stage]** ([N] production indicators detected).

What stage is the project in?
(a) Greenfield / MVP under construction (no real users)
(b) MVP launched, first users
(c) Mature production, several active customers
(d) Maintenance / few changes, evolving slowly
(e) Don't know / skip
```

**Skip behavior (e):** Use the auto-detected stage. If 3+ production indicators were detected, treat as `mature-production` and emit the `Production constraints` section in `AGENTS.md` / `CLAUDE.md` (the indicators justify it even without confirmation). If 0–2 indicators, mark stage as "unknown" and skip the production section — user can add later.

### Q4 — Work cadence

```
**Q4.** How is the work organized today?
(a) Discrete planned phases (Phase 1, 2, 3...)
(b) Continuous features (no rigid phases, scoping one at a time)
(c) Mostly maintenance and fixes (few new features)
(d) Mixed
(e) Don't know / skip
```

**Skip behavior (e):** Mark as `mixed`. The framework supports both — naming will be decided per work item in Phase 3 and subsequent `sdi-next-plan` runs.

### Q5 — Anything material I missed

```
**Q5.** Is there anything critical about the project this audit wouldn't catch? For example:
- Specific customers with contracts / SLAs
- Compliance constraints (GDPR, LGPD, HIPAA, SOC2)
- Commercial / regulatory deadlines
- On-call structure / runbook in an external tool
- Architectural decisions made off-repo (in Slack, Notion, etc.)
- Recent incidents that still inform decisions

Anything relevant? (free-form answer, or "nothing" / "don't know")
```

**Skip behavior ("nothing" or "don't know"):** Leave the `Critical context` section in `AGENTS.md` / `CLAUDE.md` as a placeholder with a `> Source: best-effort placeholder — populate as you learn the project` flag. User adds context as it surfaces.

## After Q5

Confirm understanding briefly:

> "Setup confirmed:
> - Type: [X]
> - AI modifier: [yes/no]
> - Stage: [stage]
> - Cadence: [cadence]
> - Critical context: [summary or 'pending']
>
> Generating artifacts now. Takes ~1-2 minutes."

Then proceed to Phase 2.

## Rules

- **Never ask follow-ups beyond these 5.** If the user asked you to elaborate, fine — answer their question, but don't proactively add Q6.
- **Never push back on "don't know".** Each skip behavior is defined; just apply it and move on.
- **Don't repeat the audit.** The user has already seen the discovery report. Reference it, don't re-show.
- **Order can be reordered** if the user starts answering Q3 before Q1 — adapt. The order above is a suggestion, not a script.
- **Conversational language.** Render the questions and confirmation in the user's language (see `SKILL.md` §Tone). Source text is English; the assistant translates at runtime.

## What NOT to ask in Phase 1

The temptation will be to interrogate. Resist:

- ❌ "Why did you choose Drizzle instead of Prisma?"
- ❌ "Who are the product's users?"
- ❌ "What's the roadmap for the next 6 months?"
- ❌ "Which architectural decisions matter most in this codebase?"
- ❌ "How does the signup flow work?"

Reasons not to ask:
- The first three are the user's job to fill in (or not) over time. Asking front-loads work.
- The last two are extractable from code (let Phase 0 do its job) or belong to PRD which is thin-by-design.

If the user wants to volunteer this info, capture it. But the skill never asks.
