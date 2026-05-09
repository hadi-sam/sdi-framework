# Existing artifact handling

When `convert-to-sdi` runs against a project that already has artifacts (`PRD.md`, `ARCHITECTURE.md`, `ROADMAP.md`, `KNOWN_ISSUES.md`, ADRs, etc.) — possibly in formats different from the framework's canonical structure — the skill must NOT silently overwrite them. This reference defines:

1. The four canonical **strategies** for handling existing artifacts
2. The **default strategy per artifact** (a matrix the skill applies)
3. The **decision flow** the skill runs in **Phase 1.5** (between Phase 1 triage and Phase 2 generation)
4. **Special cases** (ADRs, in-tool docs like Notion/Figma/Linear, custom `docs/` folders)

The whole point: never lose user content, never silently fight with their conventions, never duplicate without clear reason.

## Contents

- [The four strategies](#the-four-strategies) — A/B/C/D handling options for existing artifacts
- [The matrix — default strategy per artifact](#the-matrix--default-strategy-per-artifact) — what to do per file type
- [ADR handling (special case)](#adr-handling-special-case) — preserve ADR investment, default Option 1
- [In-tool / external docs](#in-tool--external-docs-notion-linear-figma-confluence) — Notion, Linear, Figma, Confluence handling
- [Custom `docs/` content](#custom-docs-content) — runbooks, post-mortems, internal wiki
- [Format compatibility detection (heuristic)](#format-compatibility-detection-heuristic) — per-artifact compatibility classification
- [Phase 1.5 decision flow](#phase-15-decision-flow) — present matrix → user respond → confirm
- [Strategy execution rules](#strategy-execution-rules) — how each strategy is applied in Phase 2
- [Don't-do list](#dont-do-list) — rules to avoid breaking user content
- [Recovery if convert-to-sdi was already run badly](#recovery-if-convert-to-sdi-was-already-run-badly) — git-based safety net

## The four strategies

### Strategy A — Preserve as-is + framework header

The existing file already does its job. Don't touch the content. Add a small header at the top so future readers know the framework is active.

**Pattern:**
```markdown
> **Framework:** This project uses the sdi-framework workflow. See `AGENTS.md` / `CLAUDE.md` (root) for project facts and invoke/activate `sdi-mode` for the operating discipline. This document predates the framework adoption and is preserved as-is.

[existing content unchanged]
```

**When:**
- Existing file already covers the canonical role (README with stack + summary + doc links; AGENTS.md / CLAUDE.md already in current fact-sheet format)
- Format compatibility is high (matches framework structure or close enough)
- User chose to keep current format (e.g. team has muscle memory for it)

**Cost:** zero rework, zero risk.

### Strategy B — Convert in place

Read the existing content. Propose a new version that **merges** canonical framework structure + existing content. Show the user the diff. They approve, edit, or reject.

**Pattern:**
1. Skill reads existing file.
2. Skill identifies what canonical sections are present, partially present, or missing.
3. Skill writes a new version: existing content reorganized into canonical sections; missing sections added as placeholders with confidence flags; extra content from the existing file kept as a `## Legacy notes` section at the end (or distributed where it fits).
4. Skill presents the diff to the user before writing.
5. User says: "go", "edit X", or "keep original".

**When:**
- Existing file has substance worth preserving but format diverges
- User wants framework-canonical structure going forward
- Format mismatch isn't extreme

**Cost:** ~5 min user review per file. Diff approval should be quick if the conversion is clean.

### Strategy C — Rename existing + generate new

Rename the existing file to `<name>.legacy.md` (or `<name>.original.md`). Generate a fresh canonical version from the framework template.

**Pattern:**
1. Skill renames `docs/ROADMAP.md` → `docs/ROADMAP.legacy.md`.
2. Skill generates fresh `docs/ROADMAP.md` from the framework template.
3. Skill adds a one-line note at the top of the new file: *"Predecessor preserved at [`ROADMAP.legacy.md`](./ROADMAP.legacy.md). Reference for historical context; not the source of truth."*
4. Skill mentions the legacy file in today's `docs/memory/YYYY-MM-DD.md` entry.

**When:**
- Existing file is in a fundamentally incompatible format (e.g. ROADMAP that's actually a Trello CSV export, ARCHITECTURE that's a 3000-line wiki dump)
- User explicitly wants a clean canonical version
- Existing is too outdated to merge usefully

**Cost:** zero rework on existing (preserved), but two files now exist — slight maintenance overhead.

### Strategy D — Skip generation entirely

Don't generate the canonical artifact at all. Add a note in `AGENTS.md` / `CLAUDE.md` (and optionally `README.md`) explaining where the source of truth lives.

**Pattern in AGENTS.md / CLAUDE.md:**
```markdown
## External artifact references

Some framework artifacts live outside this repo:

- **PRD:** Notion page [link]. The framework-canonical PRD.md is intentionally not generated; treat the Notion page as authoritative.
- **Roadmap:** Linear cycles + project view [link]. ROADMAP.md is not generated; Linear is the source of truth.
- **Design system:** Figma file [link] + the implemented tokens in `src/styles/tokens.css`. DESIGN_SYSTEM.md is not generated.
- **Known issues:** Jira project [link]. KNOWN_ISSUES.md is intentionally not generated; treat Jira as the canonical issue/debt catalog.

When sdi-mode references PRD.md / ROADMAP.md / DESIGN_SYSTEM.md / KNOWN_ISSUES.md, substitute the external source above.
```

**When:**
- Existing source of truth lives in another tool (Notion, Linear, Jira, Figma, Confluence)
- User explicitly wants to keep working in that tool, not migrate to markdown
- Forcing migration would create duplication and drift

**Cost:** sdi-mode loses some on-repo context for that artifact, but the user controls trade-off explicitly.

## The matrix — default strategy per artifact

Skill applies these defaults; user can override per-file in Phase 1.5.

| Artifact | If exists, default strategy | Conditions for override |
|---|---|---|
| `README.md` | **A** (preserve + framework header) | B if it lacks stack table + doc links AND user wants alignment |
| `AGENTS.md` / `CLAUDE.md` | **B** (merge in place — preserve project facts, drop any embedded discipline, write the approved fact sheet to both files) — see "AGENTS.md / CLAUDE.md merge handling" below | A if both already match the current `agents-template.md` content exactly; C only if an existing file is unrecoverable |
| `PROJECT_STRUCTURE.md` | **B** (existing as basis, add canonical sections) | A if already canonical |
| `ARCHITECTURE.md` | **B** (merge with type appendix sections) | C if outdated >1 year or wiki-style |
| `PRD.md` | **B** (preserve content, fit into canonical sections) | D if PRD lives in Notion/Confluence |
| `ROADMAP.md` | **B** if has phase/quarter structure; **C** if pure export | D if in Linear/Jira |
| `DESIGN_SYSTEM.md` | **B** (extract tokens, structure into canonical) | D if living in Figma |
| `KNOWN_ISSUES.md` | **A** if already an append-only issue catalog; **B** if format needs lifecycle/status scaffold added | D only if the team intentionally keeps the canonical issue catalog in an external tracker |
| `DECISIONS.md` (single file) | **B** (merge into framework format if needed) | A if format already matches |
| `docs/decisions/` or `docs/adr/` (ADR folder) | **Special — see ADR handling below** | |
| `CHANGELOG.md` | **A** (preserve; signals are channeled to AGENTS production-indicators section) | never overwrite |
| Custom `docs/` files (runbooks, post-mortems, internal wiki pages) | **A** (preserve all; reference where relevant from AGENTS doc map) | |

**Default safety bias:** when in doubt, prefer A or B over C. C is destructive of organization (renames file). D is conservative but creates external dependency.

## AGENTS.md / CLAUDE.md merge handling (specific Strategy B procedure)

`AGENTS.md` and `CLAUDE.md` always default to Strategy B when either exists because the canonical template is a strict **fact sheet** — it contains stack, doc map, conventions, and a work tracker, and **never** carries discipline (audit steps, checkpoint behavior, tone, document precedence). The discipline lives in the `sdi-mode` skill (Claude Code / Codex) or the configured custom mode (Roo / Kilo / OpenCode) and propagates from there.

Any existing `AGENTS.md` or `CLAUDE.md` is therefore either: (a) already a fact sheet and mostly compatible, (b) framework-aware but contains discipline-style instructions that should be removed, (c) a one-line pointer such as `@AGENTS.md`, or (d) ad-hoc but with valuable project facts that should be preserved. Strategy B handles all four and normalizes both output files to the same fact-sheet content.

**Procedure:**

1. **Read** the existing `AGENTS.md` and/or `CLAUDE.md`, if present.
2. **Classify each section/paragraph** into one of three buckets:
   - **Project fact** (stack details, file/directory conventions, helper names, schema directory paths, test runners, deployment target, doc map entries, work tracker rows, AI/LLM modifier flag, type identifier) → **preserve verbatim into the matching section of the canonical template**.
   - **Discipline rule** (anything imperative about the agent's behavior: "always audit before coding", "stop at checkpoints", "the agent should…", "tone: concise", "document precedence: X > Y", lists of "what this mode is not", "when in doubt: stop and ask") → **drop**. The canonical template has the rubric "Edit only project facts; never inject discipline rules" at the top, with examples; the discipline these instructions are trying to encode lives in the `sdi-mode` skill/mode.
   - **Ambiguous** (mixes a fact and an instruction, or a project-specific exception phrased as an instruction) → flag for the user. Examples: "Tests: use vitest. Always run lint before commit." → split into a fact ("Test runner: vitest") and a discipline instruction (drop or surface as a question to the user about whether it belongs in their lint hooks rather than `AGENTS.md`).
3. **Construct the new fact sheet** from the canonical template (loaded from `references/agents-template.md`), filling in:
   - The `Project context` block with values detected by Phase 0 + confirmed by Phase 1 + values pulled from buckets above.
   - The `Document map` reflecting actual `docs/` content (including any custom files preserved per the matrix).
   - `Project-specific conventions > Stack details / File / directory conventions / Convention exceptions` populated with everything bucket-classified as "fact".
   - The `Work tracker` with a single retroactive row marking the conversion ("Converted to SDI on YYYY-MM-DD; first work item TBD").
   - Any external artifact references (Strategy D outcomes for other artifacts) appended as an `External artifact references` block.
4. **Show a three-way diff to the user**:
   - **Preserved** — sections/lines copied verbatim from the existing file (which canonical section each landed in).
   - **Dropped** — discipline-style instructions removed, with a one-line reason each (e.g., "removed 'always audit before coding' — the discipline now lives in the `sdi-mode` skill/mode").
   - **Added** — new sections from the canonical template that the existing file didn't have (e.g., the rubric at the top, the work tracker, the operating-context block).
5. **Wait for user approval.** They can: accept, edit specific sections, or veto a drop (if a "discipline" line was actually a project-specific exception they want preserved as a fact — in which case rephrase as a fact).
6. **Write the approved fact sheet to both `AGENTS.md` and `CLAUDE.md`** only after explicit approval. If the user wants only one file, honor that explicit override. The original is not preserved as a `.legacy.md` (Strategy C territory) unless the user requests it; the diff shown in step 4 is the audit trail.

**When this procedure does NOT apply:**

- Existing `AGENTS.md` and `CLAUDE.md` already carry the same current canonical fact sheet. → Strategy A.
- One file is current and the other is missing or a one-line pointer. → Strategy B, with the current fact sheet copied to both files after approval.
- An existing file is unintelligible (binary, machine-generated noise, broken markdown). → Strategy C for that file (rename to `<name>.legacy.md`, generate fresh fact sheet).

## ADR handling (special case)

ADRs (Architecture Decision Records) are a mature, widely-adopted convention — typically `docs/decisions/0001-decision-name.md`, `0002-...`, etc. Don't fight ADR investment. Two acceptable approaches:

### Option 1 — Keep ADRs, generate DECISIONS.md as an index (DEFAULT)

```markdown
# DECISIONS

> **Source:** index pointing to ADR records in `docs/decisions/`. The ADR convention pre-dates the framework adoption; this file aggregates them and adds new framework-style entries below.

## ADR records (authoritative)

| # | Title | File |
|---|---|---|
| 0001 | [title from ADR file] | [docs/decisions/0001-...](docs/decisions/0001-...) |
| 0002 | ... | ... |

## Framework-style additions

(New decisions taken under SDI mode are added below in framework format. ADRs continue to be the canonical record for architecture-level decisions; framework-style entries cover implementation-level decisions per work item.)
```

**Why default:** preserves ADR investment + adds framework's lighter format for implementation decisions. Both coexist. Convention: architectural decisions → ADR; implementation decisions → DECISIONS.md.

### Option 2 — Convert ADRs to DECISIONS.md format

Read each ADR, produce a framework-style entry in `DECISIONS.md`, preserve the ADR number as a marker:

```markdown
### #ADR-0001 — [original title]

**Context**: [extracted from ADR §Context]

**Decision**: [extracted from ADR §Decision]

**Rationale**: [extracted from ADR §Rationale or §Consequences]

**Source**: converted from `docs/decisions/0001-...md` on YYYY-MM-DD.

**Revisit when**: [extracted if ADR has it; "?" otherwise]
```

After conversion, rename ADR folder to `docs/decisions.legacy/` (Strategy C applied to the folder).

**When:** user explicitly wants single-format DECISIONS and is willing to give up ADR convention. **Rare.**

The skill **always defaults to Option 1**. Option 2 only if the user explicitly asks.

## In-tool / external docs (Notion, Linear, Figma, Confluence)

When existing source-of-truth lives outside the repo, **do not import or migrate**. Apply Strategy D and document the external pointer in AGENTS.md / CLAUDE.md.

Common patterns:

| Artifact | Common external tool | Treatment |
|---|---|---|
| PRD | Notion, Confluence, Coda | D + link in AGENTS.md / CLAUDE.md "External artifact references" |
| Roadmap | Linear cycles, Jira epics, ClickUp | D + link |
| Design system | Figma, Storybook deployed | D + link; tokens may still be extractable from code |
| Known issues | Linear, Jira, GitHub Issues | Prefer generating `KNOWN_ISSUES.md` as repo-local index with external links; D only if user explicitly wants the external tracker as the source of truth |
| Runbooks | Notion, internal wiki | A (if in repo) or D (if external) |
| Customer docs | Help Center, Intercom | D |

The skill asks in Phase 1.5: *"Some artifacts may live in tools (Notion, Linear, Figma, etc.). Should any of these stay external? List the ones, with links."*

## Custom `docs/` content

Many projects accumulate `docs/`-folder content that's neither canonical framework artifact nor pure ADR — runbooks, post-mortems, integration guides, onboarding docs, etc.

Default: **Strategy A — preserve all**. The skill scans `docs/` and:

1. Lists all non-canonical files in the discovery report
2. Asks user (in Phase 1.5) if any should be linked from AGENTS.md / CLAUDE.md "Document map" → "Other docs" section
3. Default-links all of them under a flat list

Don't reorganize the `docs/` folder unless the user asks. Don't delete anything.

## Format compatibility detection (heuristic)

To decide between A (preserve) and B (convert in place), the skill checks **format compatibility** during Phase 0 audit. Heuristics per artifact:

### `README.md`
**Compatible** if has all of: 1-paragraph product summary, stack table or stack list, links to other docs.
**Partially compatible**: has 2 of the 3.
**Incompatible**: just title + clone instructions; no stack/docs.

### `PRD.md`
**Compatible** if has identifiable sections matching: product/goal description, users/audience, in-scope features, out-of-scope features, success metrics.
**Partially compatible**: has 3+ of 5.
**Incompatible**: <3 of 5, or pure prose without sections.

### `ARCHITECTURE.md`
**Compatible** if has identifiable sections: tech stack, critical flows or system overview, trade-offs or known issues.
**Partially compatible**: has 2 of 3.
**Incompatible**: <2, or pure decision list (treat as ADR).

### `ROADMAP.md`
**Compatible** if has identifiable phases/cycles/quarters with deliverables and acceptance criteria (or close equivalents).
**Partially compatible**: phases without acceptance criteria.
**Incompatible**: pure backlog list, Trello/CSV export, prose without sequence.

### `PROJECT_STRUCTURE.md`
**Compatible** if has directory tree + conventions section.
**Partially compatible**: directory tree only, or conventions only.
**Incompatible**: prose description without structure.

### `DESIGN_SYSTEM.md`
**Compatible** if has token definitions (color, typography, spacing) + at least 2 of: layout, motion, accessibility, components.
**Partially compatible**: tokens only.
**Incompatible**: aesthetic intent prose without tokens.

### `KNOWN_ISSUES.md`
**Compatible** if it has `KI-NNN` entries (or an empty scaffold) plus status/severity/lifecycle guidance.
**Partially compatible**: concrete issue entries exist but format varies or lacks lifecycle/status legend.
**Incompatible**: unstructured prose bug list with no evidence/status fields.

### `AGENTS.md` / `CLAUDE.md`
**Compatible** if it matches the current facts-only shape: project context + document map + project-specific conventions + work tracker, with no embedded discipline rules.
**Partially compatible**: framework-aware (mentions SDI or has tracker) but missing pieces, or contains residual discipline that must be stripped during Strategy B.
**Incompatible**: not framework-aware, different agent-rules style, or mostly behavioral instructions with few recoverable project facts.

### `DECISIONS.md` (single file)
**Compatible** if has numbered entries with Context/Decision/Rationale or close.
**Partially compatible**: entries exist but format varies.
**Incompatible**: prose log without entries (rare; usually means ADR-style elsewhere).

### Mapping to strategy

| Compatibility | Default strategy |
|---|---|
| Compatible | A (preserve + header) |
| Partially compatible | B (convert in place — gentle merge) |
| Incompatible | B (convert in place — heavy merge, more user review) or C (rename + generate) — user picks |

## Phase 1.5 decision flow

The skill runs Phase 1.5 **whenever** Phase 0 detected one or more existing canonical artifacts. If all detected artifacts are compatible, still show the matrix and recommend Strategy A where appropriate. If the project has no existing canonical artifacts, skip Phase 1.5 entirely and go straight to Phase 2.

### Step 1 — Present the matrix

Show the user a table of detected existing artifacts with the proposed default strategy per file:

```markdown
## Existing artifacts detected

| File | Compatibility | Proposed strategy | Why |
|---|---|---|---|
| `README.md` | compatible | **A — preserve + header** | already has stack/summary/doc links |
| `docs/ARCHITECTURE.md` | partially compatible | **B — convert in place** | has stack + flows but no §Trade-offs |
| `docs/ROADMAP.md` | incompatible | **C — rename + generate** | pure Trello export; no phase structure |
| `docs/KNOWN_ISSUES.md` | compatible | **A — preserve + header** | already uses append-only issue entries |
| `docs/decisions/` (ADR folder, 12 records) | n/a (special case) | **ADR Option 1** — keep + DECISIONS.md as index | preserves ADR investment |
| `CHANGELOG.md` | n/a | **A — preserve always** | release log |
| `docs/runbooks/` (3 files) | n/a (custom docs) | **A — preserve, link from AGENTS doc map** | |

Confirm or override per file? (per-file response, e.g. "ARCHITECTURE: B, ROADMAP: keep as is = A")
```

Immediately below the table, always include this legend so the user is not forced to know what "A" or "B" means:

```markdown
## Strategy legend

- **A — Preserve as-is + framework header:** keep existing content; add only the SDI marker/header.
- **B — Convert in place:** merge existing content into the framework structure; show diff and wait for approval before writing.
- **C — Rename existing + generate new:** preserve the old file as `<name>.legacy.md`; generate a fresh framework file that links to it.
- **D — Skip generation / external source:** do not create the repo-local artifact; record the external source of truth in `AGENTS.md` / `CLAUDE.md`.
```

If the table includes an ADR folder, immediately add:

```markdown
## ADR options

- **ADR Option 1 — Keep ADR folder + create DECISIONS.md index:** preserve every ADR file; generate `docs/DECISIONS.md` as the current decision index that links to the ADR history.
- **ADR Option 2 — Convert ADRs into DECISIONS.md:** only if the user explicitly asks; preserve originals as legacy/history and migrate summaries into the single decision log.
```

### Step 2 — User responds

Accept any of:
- "go" / "ok" / "tudo confirmado" → apply all defaults
- Per-file override: "ROADMAP: A" → user wants to preserve as-is even though incompatible
- "skip [file]: D" → user moves it to external (provides link)
- Mixed responses are fine

### Step 3 — Confirm and proceed

Echo back the final per-file plan, then proceed to Phase 2 with those strategies applied.

If the user says "skip" without specifying handling, **default to A (preserve)**. Better safe.

## Strategy execution rules

When generating in Phase 2, apply the chosen strategy:

### For Strategy A (preserve + header)

1. Read existing file.
2. Prepend the framework header.
3. Write back. Don't touch any other content.

### For Strategy B (convert in place)

1. Read existing file.
2. Parse identifiable sections.
3. Build a new version using the canonical framework template, populating sections from existing content.
4. Anything in existing that doesn't fit canonical sections → place in a `## Legacy notes` section at the end.
5. Add confidence flags per section as appropriate (per `confidence-flags.md`).
6. **Show the diff to the user before writing.**
7. After approval, write the new version.

For `KNOWN_ISSUES.md`, Strategy B has an extra safety rule: preserve every concrete issue entry verbatim unless the user explicitly approves rewriting that entry into the canonical `KI-NNN` format. Never drop resolved issues, never renumber existing IDs, and never collapse multiple issues into one without user approval.

### For Strategy C (rename + generate)

1. Rename existing: `git mv docs/ROADMAP.md docs/ROADMAP.legacy.md` (or filesystem rename if not git).
2. Generate the canonical fresh version per `artifact-generation-rules.md`.
3. Add note at top of new file: *"Predecessor preserved at [`ROADMAP.legacy.md`](./ROADMAP.legacy.md). Reference for historical context; not the source of truth."*
4. Mention the legacy file in `docs/memory/YYYY-MM-DD.md`.

### For Strategy D (skip)

1. Do NOT generate the artifact.
2. In AGENTS.md / CLAUDE.md, ensure the "External artifact references" section exists and includes this artifact with the user-provided link.
3. In README.md doc map, replace the artifact link with: *"[Artifact name] — external (see AGENTS.md / CLAUDE.md §External artifact references)"*

## Don't-do list

- ❌ Don't silently overwrite ANY existing canonical artifact, even if "incompatible". User picks the strategy.
- ❌ Don't merge content from existing into new without showing the diff. The user must see what changed.
- ❌ Don't reorganize `docs/` folder. Custom content stays where it is.
- ❌ Don't delete `<name>.legacy.md` files later "for cleanup". They're explicitly preserved.
- ❌ Don't try to migrate Notion/Linear/Figma content into the repo. Strategy D exists for a reason.
- ❌ Don't apply ADR Option 2 (convert all ADRs to DECISIONS.md format) unless user explicitly asks. Default is always Option 1 (keep ADRs + index).

## Recovery if convert-to-sdi was already run badly

If a previous convert-to-sdi run already overwrote things (because the older version of this skill didn't have this protocol), the user can recover via git:

1. `git log --diff-filter=M -- docs/PRD.md` to find pre-convert-to-sdi version.
2. Restore the pre-existing version: `git show HEAD~N:docs/PRD.md > docs/PRD.md.recovered`.
3. Re-run convert-to-sdi with the corrected handling.
4. The recovery is logged in `docs/memory/YYYY-MM-DD.md` for traceability.

This is the framework's "we don't lose user content" guarantee. If anything goes wrong, git is the safety net.
