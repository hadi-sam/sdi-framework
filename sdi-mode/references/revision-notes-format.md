# Revision Notes Format

Plans evolve during implementation. Revision notes are how that evolution is marked in the plan itself, so the plan stays a current document rather than becoming a stale snapshot of the original intent.

## When to add a revision note

- Audit of the plan against the repo produces real changes. Add a revision note.
- Mid-phase discovery shows a plan section is wrong or incomplete. Add a revision note.
- Scope changes mid-phase (customer requirement, tech decision, trade-off reversal). Add a revision note.
- Small typos or clarifications: no revision note needed — just fix.
- New DECISIONS.md or KNOWN_ISSUES.md entry that doesn't change the plan: no revision note needed.

Rule of thumb: if someone reading the plan in 6 months would be confused by the diff between what's written and what was built, add a revision note.

## Format

Revision notes live at the very top of the plan, above the first `##` section. They stack — newest on top, oldest below. Never delete prior revision notes.

```markdown
# Implementation Plan — Phase N: [Title]

> Detailed spec for Phase N of the roadmap. Companion to PRD.md, ARCHITECTURE.md, and PROJECT_STRUCTURE.md.
>
> **Revision note (r3):** one additional audit pass after r2. Two items added:
> 6. Webhook handler runs entirely on the [auth service-role client] (there's no JWT on incoming webhooks). §3.1 now states this explicitly as an invariant.
> 7. Sentry PII scrubbing is now an explicit acceptance criterion — both `phone` AND `email` must be absent from captured event bodies.
>
> **Revision note (r2):** plan was audited against the Phase 0 repo before kickoff. Five adjustments:
> 1. `sources.agent_id`: removed FK to `agents` (table doesn't exist yet)...
> 2. [Data isolation policy] helper: use `public.current_org_id()` (per DECISIONS.md #1)...
> [etc.]
>
> **General rule**: when this plan disagrees with the actual repo conventions, the repo wins. Flag the divergence in DECISIONS.md and keep going — don't stall on paperwork.

## 0. Pre-requisites
...
```

## Length

- Revision note: 4–10 lines.
- Bulleted list of specific changes, each 1 line.
- Ends with a general rule reminder if useful.

Don't write essays here. The purpose is a compact diff log, not a history lesson.

## What a revision note should contain

1. **Revision number and trigger**: `r3` or similar, plus why (audit, mid-phase discovery, scope change).
2. **Numbered list of changes**: specific, each on one line.
3. **General rule carry-over** (optional): the "repo wins" rule or equivalent if it matters.

## What NOT to include

- Personal justification or hand-wringing. "We realized we should have..." — no. Just state the change.
- Redundancy with DECISIONS.md. If a change is documented in detail in DECISIONS.md, reference the entry; don't re-explain.
- Speculation. If you're unsure whether a change is right, don't add it to the plan yet — discuss with the user first.

## Examples of good revision notes

### After audit (most common):

> **Revision note (r2):** plan audited against Phase 0 repo. 3 adjustments:
> 1. §2.1 removed FK to `agents` table (doesn't exist yet); plain `uuid` column instead. FK added in Phase 2.
> 2. §2 [data isolation policy] examples switched from `current_user_org()` (invented) to `public.current_org_id()` (actual helper in `migration 0001_rls_policies_and_auth_links.sql`).
> 3. §9.2 Test webhook UI switched from Monaco to `<textarea>` — Monaco is a 2MB dependency we don't need for MVP.

### After mid-phase discovery:

> **Revision note (r3):** mid-phase discovery. 1 adjustment:
> 6. §3.1 webhook handler now explicitly uses [auth service-role client] end-to-end. RLS bypass is intentional; isolation enforced in-code per `src/lib/leads/ingest.ts` invariant. Pattern formalized in DECISIONS.md #18.

### After scope change:

> **Revision note (r4):** customer requested expanded error reporting for PII events. 2 adjustments:
> 7. §13 Acceptance Criteria added AC #11 — Sentry events must never contain phone, email, or raw_payload. Added test AC #8 verifying scrubber behavior.
> 8. §12 Observability clarified — raw_payload is PII-by-design, never forwarded to Sentry or PostHog.

## When to re-read old revision notes

- When starting a new phase that touches the same area.
- When auditing the plan's current state.
- When onboarding a new contributor to the project.

Revision notes are a timeline; reading them in order tells the story of how the plan evolved.

## Housekeeping at end of phase

At phase close:

- Verify all revision notes reference resolved changes (not things that were discussed but not applied).
- If the plan has grown significantly misaligned with the implementation, consider a final "reconciliation note" (`r-final`) summarizing what was built vs what was planned.

This is optional but helpful — it's the plan's closing summary.
