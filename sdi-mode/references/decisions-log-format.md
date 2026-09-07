# DECISIONS.md Format

Append-only paper trail of non-obvious choices. One short paragraph per entry, not an essay.

## Location and structure

**File**: `docs/DECISIONS.md`, one file and one place. No **new** per-decision file or `docs/decisions/` directory: an entry too long for it needs cutting, not a new home; a pre-existing ADR folder follows `convert-to-sdi`'s `existing-artifact-handling.md` §"ADR handling", with `DECISIONS.md` as the index. Entries are **numbered sequentially**, newest at the bottom, never renumbered, never deleted, and leave the hot file only by being **archived with a stub** (below). Numbers are a **global namespace across live branches**: the next free one is `max(main, every live branch) + 1`, measured at write time, never pre-allocated in a plan.

## Entry format

The **anchor comes immediately before the header**, the header is `### #N — title` with the ` — ` separator, and `Vigência` is mandatory: those three shapes are parsed by tooling, so they are literal. The four content field names are the project's own, in its language.

```markdown
<a id="N"></a>
### #N — [short title, one line]
- **Vigência**: **Vigente**
- **Context**: [one or two sentences: the situation that forced the decision.]
- **Decision**: [one sentence: what was decided.]
- **Rationale**: [one or two sentences: why this option over the alternatives.]
- **Revisit when**: [optional trigger that would make it wrong. Omit if permanent.]
```

`Vigência` takes **one** of `Vigente`, `Supersedida por #N`, `Parcialmente supersedida por #N`, `Arquivada`, and nothing else on the line: whatever qualifies it goes on a line of its own. **Size:** the four content fields **together** fit the per-entry character ceiling of the project's doc lint (`scripts/docs_bounds.py` where there is one; one screen where there isn't).

**Stub** — the second canonical form, written when the entry moves to `DECISIONS_ARCHIVE.md`. Exactly these four contiguous lines:

```markdown
<a id="N"></a>
### #N — [title, byte-identical to the archived one]
- **Vigência**: **Arquivada**
- **Arquivo**: status Vigente em AAAA-MM-DD, texto completo em [#N](DECISIONS_ARCHIVE.md#N)
```

Archiving is **moving with a stub, never deleting**; the project's archiver stops, by name, an entry outside either canonical form.

## What becomes an entry

**Yes:** a library or service chosen for non-obvious reasons; a feature deferred (what, why, when to revisit); a trade-off accepted; a convention deviated from; a change to what "done" means for an acceptance criterion; an attempt past the review cap authorized, written **before** it runs; a plan-vs-repo divergence resolved by a judgment call.

**No:** what matches the plan, implementation detail, anything a competent dev would decide the same way; a bug, gap or debt on its own, which is `KNOWN_ISSUES.md` (here goes only a non-obvious choice *about* one); and a **mechanical** divergence — `getCwd()` in the plan against `getCurrentWorkingDirectory()` in the repo — which is a line in the round report's "Delivered".

If you had to explain *why* to a peer and it wasn't obvious, it's an entry.

## The bad example, at the real size

```markdown
### #X — Using jsonpath-plus for field mapping
**Context**: We need to parse JSONPath expressions. Several libraries could work, each with
trade-offs in bundle size, completeness, security posture and maintenance cadence. We compared
download counts, open issues, last release and filter-expression support, then benchmarked…
```

Three mechanical defects: no anchor, no `Vigência`, and a Rationale that runs on instead of the one or two sentences the format asks for. The lint measures the entry and names it — length is not judged by eye.

## Timing, cross-references, sweep

Write **as you go**: retroactive entries become generic justifications or get missed. Each is also a line in that round report's `## Decisões desta rodada`, and entries are cited from code comments, revision notes, other entries, round reports and `KNOWN_ISSUES.md`. At phase close, look for the entry you forgot, the one a later entry contradicts without carrying `Supersedida por #N`, and the `Revisit when` trigger now met.
