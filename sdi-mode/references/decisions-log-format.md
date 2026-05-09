# DECISIONS.md Format

Paper trail of non-obvious choices during implementation. Format is deliberately lightweight — a DECISIONS entry is one short paragraph, not an essay.

## Location and structure

- **File**: `DECISIONS.md` at the repo root, or under `docs/DECISIONS.md`. Either is fine; be consistent.
- **Entries are numbered sequentially.** #1, #2, #3... Never renumber, even when reshuffling.
- **Newest at the bottom, oldest at the top.** Append-only.

## Entry format

```markdown
### #N — [short title of the decision]

**Context**: [One or two sentences explaining the situation that forced this decision.]

**Decision**: [One sentence: what was decided.]

**Rationale**: [One or two sentences: why this option over alternatives.]

**Revisit when**: [Optional — a trigger that would make this decision wrong. Omit if permanent.]
```

Four fields, each one short. An entry fits on a screen.

## What becomes an entry

- Choosing one library / framework / service over another when the reasons aren't obvious.
- Deferring a feature to a later phase (explicit: what, why, when to revisit).
- Accepting a trade-off (over-matching regex, at-most-once job dispatch, no grace period on secret rotation, etc.).
- Resolving a **material** plan-vs-repo divergence (see "Material vs mechanical divergences" below).
- Deviating from a convention for a local reason.
- Changing the interpretation of an artifact (what "done" means for a particular AC).

## What does NOT become an entry

- Obvious decisions that match the plan. No entry.
- Pure implementation details (naming a variable, choosing a helper structure). No entry.
- Things any competent dev would decide the same way. No entry.
- Pre-existing bugs, security gaps, or tech debt items by themselves. Those go in `KNOWN_ISSUES.md`. A DECISIONS entry is needed only if the team makes a non-obvious choice about accepting, deferring, or fixing that issue.

Rule of thumb: if you had to explain *why* this choice to a peer, and the explanation wasn't obvious, it's an entry.

## Material vs mechanical divergences

A plan-vs-repo divergence becomes a `DECISIONS.md` entry only when it is **material** — when the resolution required a judgment call and a future reader would benefit from knowing why. **Mechanical** divergences (idiomatic corrections with no real trade-off) are noted in the round report's "Delivered" section instead.

### Mechanical (round report only — no DECISIONS entry)

- Plan said `getCwd()`, repo has `getCurrentWorkingDirectory()` — used repo's name.
- Plan listed `axios` as a new dep, repo already uses `node-fetch` for the same purpose — used existing.
- Plan said file goes in `src/lib/`, repo convention is `src/utils/` — followed convention.
- Plan referenced a missing env var; added it during setup.

### Material (DECISIONS entry)

- Plan said use Postgres native enum, repo uses `text` + check constraint — kept repo pattern. Trade-off: no automatic enum exhaustiveness in TS, but consistency across schema.
- Plan said use Inngest for background jobs, repo already has BullMQ wired — chose BullMQ to avoid two job systems.
- Plan referenced `agents.id` FK, but `agents` is in Phase 2 — used plain UUID with comment instead. FK added when the table exists.
- Plan said use Postgres RLS for tenant isolation, repo enforces in app layer — kept app-layer enforcement; trade-off documented.

### Rule of thumb (material vs mechanical)

If the resolution would surprise the next reader, or you'd want to explain *why* to a peer, it's material. If you'd describe it as "just used the repo's name", it's mechanical.

## Example entries

### Good:

```markdown
### #18 — HMAC verification runs before rate limiting

**Context**: Webhook ingestion has both HMAC signature verification and per-source rate limiting. Order matters.

**Decision**: HMAC verify first, rate-limit second.

**Rationale**: `sourceId` is in the URL (easily discoverable). If rate-limit ran first, an attacker could flood an unsigned source with garbage and exhaust the legitimate quota. HMAC-SHA256 is microseconds on modern CPUs, so running it first adds negligible cost. Stripe follows the same pattern.

**Revisit when**: never (this is the correct order).
```

### Good:

```markdown
### #29 — Secret rotation has no grace period in Phase 1

**Context**: `POST /api/sources/:id/rotate-secret` generates a new secret and persists it, invalidating the old one immediately. Any webhook in flight signed with the old secret returns 401 after rotation.

**Decision**: No grace period. Rotation is an instant cutover.

**Rationale**: Phase 1 is single-customer; coordination with the integrator is acceptable. A real grace period (supporting old + new secret for a window) requires storing multiple secrets, TTL logic, and cleanup — a week of work for a feature that only matters when there are external integrators. Deferred to later.

**Revisit when**: first external customer reports a rotation-caused outage, or a sales requirement surfaces it.
```

### Too long (bad):

```markdown
### #X — Using jsonpath-plus instead of google-libphonenumber

**Context**: We need to parse JSONPath expressions for field mapping. There are several libraries that could work, including jsonpath-plus, jsonpath, jsonpath-rfc9535, and others. Each has trade-offs in terms of bundle size, feature completeness, security posture, and ecosystem support...

[etc. — too much]
```

Keep it tight. If you find yourself writing more than a paragraph, that's a signal the decision is genuinely complex, and it might merit its own file in `docs/decisions/` with a pointer from DECISIONS.md. Rare.

## Writing timing

Write entries **as you go**, not at the end of a round or phase. The context is freshest at the moment of decision. Writing retroactively leads to:

- Forgetting why you chose one option.
- Writing a generic justification that doesn't match the real reasoning.
- Missing entries entirely.

Three lines now is better than a paragraph later.

## Referencing in other places

Decisions get referenced from:

- **Code comments**: `// see DECISIONS.md #18`
- **Plan revisions**: "rN applied the audit findings; see DECISIONS.md #X, #Y."
- **Other DECISIONS entries**: "Supersedes #17."
- **Round reports**: "Chose X — see DECISIONS.md #Z."
- **KNOWN_ISSUES.md**: a decision may reference `KI-NNN` when it explains why a known issue is accepted or deferred; the issue entry remains the durable catalog of what is wrong.

This creates a web of traceability that helps future work.

## End-of-phase review

At end of phase, sweep DECISIONS.md:

- Are there entries you forgot to write? (Look at unusual parts of the code — any of them represent a decision that's not yet documented?)
- Are any entries unclear or contradictory with later decisions?
- Are any "Revisit when" triggers now met? (If yes, the entry may need follow-up.)

Fix these before closing the phase.
