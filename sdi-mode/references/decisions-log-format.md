# DECISIONS.md Format

Append-only paper trail of non-obvious choices. An entry is one short paragraph, not an essay.

## Location and structure

- **File**: `docs/DECISIONS.md`. One file, one place — there is no per-decision file and no `docs/decisions/` directory. An entry too long for this file is an entry that needs cutting, not a new home.
- **Numbered sequentially**, newest at the bottom, never renumbered, never deleted. An entry leaves the hot file only by being **archived with a stub** (below).
- Numbers are a **global namespace across live branches**: the next free number is `max(main, every live branch) + 1`, measured when the entry is written, never pre-allocated in a plan.

## Entry format

The **anchor comes immediately before the header**, the header is `### #N — title` with the ` — ` separator, and `Vigência` is mandatory. Those three shapes are what tooling parses, so they are literal; the four content field names are the project's own (use its language).

```markdown
<a id="N"></a>
### #N — [short title, one line]
- **Vigência**: **Vigente**
- **Context**: [one or two sentences: the situation that forced the decision.]
- **Decision**: [one sentence: what was decided.]
- **Rationale**: [one or two sentences: why this option over the alternatives.]
- **Revisit when**: [optional trigger that would make the decision wrong. Omit if permanent.]
```

`Vigência` takes **one** value: `Vigente`, `Supersedida por #N`, `Parcialmente supersedida por #N`, or `Arquivada`. Nothing else on the line — whatever qualifies the value goes on a line of its own.

**Size.** The four content fields **together** must fit the per-entry character ceiling in the project's doc lint (`scripts/docs_bounds.py` where the project has one; treat an entry as one screen where it doesn't). The number lives in the lint and is not repeated in any document.

**Stub** — the second canonical form, written when the entry is moved to `DECISIONS_ARCHIVE.md`. Exactly these four contiguous lines, and nothing else:

```markdown
<a id="N"></a>
### #N — [title, byte-identical to the archived one]
- **Vigência**: **Arquivada**
- **Arquivo**: status Vigente em AAAA-MM-DD, texto completo em [#N](DECISIONS_ARCHIVE.md#N)
```

Archiving is **moving with a stub, never deleting** — that is what keeps append-only true while the hot file stays readable. The archiver is the project's script; it is strict, and an entry outside either canonical form stops it by name.

## What becomes an entry

- Choosing one library / framework / service over another when the reasons aren't obvious.
- Deferring a feature (explicit: what, why, when to revisit).
- Accepting a trade-off.
- Resolving a **material** plan-vs-repo divergence (below).
- Deviating from a convention for a local reason, or changing what "done" means for an acceptance criterion.
- Authorizing an attempt past the review cap — written **before** the attempt runs.

## What does NOT become an entry

- Decisions that match the plan; pure implementation details; anything a competent dev would decide the same way.
- Pre-existing bugs, security gaps, or tech debt on their own — those are `KNOWN_ISSUES.md`. An entry here is needed only for a non-obvious choice *about* such an issue.

Rule of thumb: if you had to explain *why* to a peer and the explanation wasn't obvious, it's an entry.

## Material vs mechanical divergences

A plan-vs-repo divergence is an entry only when it is **material** — the resolution took a judgment call a future reader would want explained. **Mechanical** ones (idiomatic corrections with no real trade-off) go in the round report's "Delivered" instead.

- Mechanical: plan said `getCwd()`, repo has `getCurrentWorkingDirectory()` — used the repo's name. Plan said `src/lib/`, repo convention is `src/utils/` — followed the convention.
- Material: plan said native enum, repo uses `text` + check constraint — kept the repo pattern, trading exhaustiveness for schema consistency. Plan said Inngest, repo already has BullMQ wired — chose BullMQ to avoid two job systems.

If the resolution would surprise the next reader, it's material.

## Examples

Good:

```markdown
<a id="18"></a>
### #18 — HMAC verification runs before rate limiting
- **Vigência**: **Vigente**
- **Context**: Webhook ingestion has both HMAC verification and per-source rate limiting. Order matters.
- **Decision**: HMAC verify first, rate-limit second.
- **Rationale**: `sourceId` is in the URL, so if rate-limiting ran first an attacker could flood an unsigned source and exhaust the legitimate quota; HMAC-SHA256 costs microseconds.
- **Revisit when**: never — this is the correct order.
```

Bad, and this is the real size of the problem:

```markdown
### #X — Using jsonpath-plus for field mapping
**Context**: We need to parse JSONPath expressions for field mapping. There are several libraries
that could work: jsonpath-plus, jsonpath, jsonpath-rfc9535, and a few smaller ones. Each has
trade-offs in bundle size, feature completeness, security posture, ecosystem support, and
maintenance cadence. We looked at download counts, open issue counts, the last release date, and
whether each one supports filter expressions, script expressions, and the `$..` recursive descent
we need for the nested payloads that arrive from the three integrations we support today, plus the
two we expect to add next quarter, and then we benchmarked the two finalists on a payload of…
```

Three defects, all mechanical: no anchor, no `Vigência`, and a Rationale that keeps going. The lint measures the entry and names it — you don't have to judge the length by eye.

## Writing timing and cross-references

Write entries **as you go**; the context is freshest at the moment of decision, and retroactive entries turn into generic justifications or get missed entirely. Every entry written in a round is also one line in that round report's `## Decisões desta rodada`.

Decisions get referenced from code comments (`// see DECISIONS #18`), plan revision notes, other entries ("Supersedes #17"), round reports, and `KNOWN_ISSUES.md` when a decision explains why an issue is accepted or deferred.

## End-of-phase sweep

Are there entries you forgot to write? Any unclear or contradicted by a later entry — and if so, does the later one carry `Supersedida por #N`? Any `Revisit when` trigger now met? Fix these before closing the phase.
