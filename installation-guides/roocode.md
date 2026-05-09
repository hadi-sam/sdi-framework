# Roo Code — SDI Mode Installation Guide

This guide shows how to install `sdi-mode` as a custom mode in Roo Code so the implementation discipline loads on every session.

> **Status note (April 2026):** recent public reporting says Roo Code products are scheduled to shut down on May 15, 2026. Keep this guide for existing Roo projects, but prefer another maintained tool for new long-lived setups.

## Prerequisites

- Roo Code installed (VSCode extension)
- This `sdi-framework/` repo cloned somewhere accessible (you'll copy the body of [`SKILL.md`](../sdi-mode/SKILL.md) into the mode config)
- A project where you want SDI mode active

## What you're configuring

Roo Code custom modes can be defined in two formats — **YAML (preferred since v3.18)** or JSON. Both work; YAML is the new default in the UI and avoids the JSON-string-escape pain of multi-line `roleDefinition`. New modes created by the UI default to YAML.

If your Roo setup also loads repo-level instruction files such as `AGENTS.md`, keep those for project-specific conventions and tool parity. The `.roomodes` custom mode remains the recommended SDI carrier because it gives you explicit mode selection, prompt isolation, and file-edit restrictions.

Two scopes:

- **Project-scoped** — `.roomodes` (YAML or JSON) at workspace root. Travels with the repo.
- **Global** — `settings/custom_modes.yaml` (or `.json`) in Roo's config directory. Available across all workspaces.

Each mode has:

- `slug` (required) — unique id, `[a-zA-Z0-9-]+`
- `name` (required) — display name
- `roleDefinition` (required) — system prompt where the SKILL.md body goes
- `description` (optional) — short summary shown in the mode selector
- `whenToUse` (optional) — guidance for Roo's automated mode-routing
- `customInstructions` (optional) — appended near the end of the prompt
- `groups` (required) — tool/permission set, with optional file-edit regex restriction

## Step 1 — Create `.roomodes` at the project root (YAML)

```yaml
customModes:
  - slug: sdi
    name: SDI — Implementation
    description: Spec-Driven Implementation discipline. Use after planning is complete.
    whenToUse: Use this mode whenever implementing against an IMPLEMENTATION_PLAN_*.md from a project under the sdi-framework.
    roleDefinition: |
      <paste the body of sdi-framework/sdi-mode/SKILL.md here, preserving markdown — start at "# SDI Mode — Spec-Driven Implementation" and skip the YAML frontmatter (the `---`-delimited block at the top is skill metadata, not part of the system prompt)>
    groups:
      - read
      - - edit
        - fileRegex: ^(?!docs/(PRD|ARCHITECTURE|ROADMAP)\.md$).*
          description: PRD/ARCHITECTURE/ROADMAP edited only via revision notes
      - command
      - browser
```

**YAML pasting tip:** the `roleDefinition: |` block-literal preserves newlines and markdown formatting as-is — no escaping needed. Just keep the indentation consistent (2 spaces past `roleDefinition:`).

## Step 1 (alternative) — JSON format

If you prefer JSON, the same mode looks like this:

```json
{
  "customModes": [
    {
      "slug": "sdi",
      "name": "SDI — Implementation",
      "description": "Spec-Driven Implementation discipline. Use after planning is complete.",
      "whenToUse": "Use this mode whenever implementing against an IMPLEMENTATION_PLAN_*.md from a project under the sdi-framework.",
      "roleDefinition": "<JSON-escaped SKILL.md body — newlines as \\n; skip the YAML frontmatter at the top of SKILL.md>",
      "groups": [
        "read",
        ["edit", { "fileRegex": "^(?!docs/(PRD|ARCHITECTURE|ROADMAP)\\.md$).*", "description": "PRD/ARCHITECTURE/ROADMAP edited only via revision notes" }],
        "command",
        "browser"
      ]
    }
  ]
}
```

JSON requires escaping every newline as `\n` in `roleDefinition`. This is the main reason YAML is the recommended format — there's no equivalent of the `|` block-literal in JSON.

> **About the SKILL.md frontmatter:** the `---`-delimited block at the top of `SKILL.md` (with `name:` and `description:`) is metadata used by skill discovery in Claude Code / Codex. It is **not** part of the SDI discipline and should not be pasted into `roleDefinition`. Start your paste at the first heading (`# SDI Mode — Spec-Driven Implementation`).

## Step 2 — Activate

1. Reload the workspace so `.roomodes` is picked up.
2. Open the mode selector (chat header).
3. Choose `SDI — Implementation`.
4. Verify the mode badge shows the new mode name.

## Step 3 — Smoke test

Ask:

> "List the 8 steps of SDI discipline."

Expected: Read → Audit → Propose → Implement in rounds → Tests alongside → DECISIONS.md / KNOWN_ISSUES.md / memory → Revision notes → End-of-phase housekeeping.

If the agent improvises, re-check that:
- `.roomodes` parses (no errors in the Roo Code output panel)
- The mode is selected (not "Code" or default)
- `roleDefinition` actually contains the SKILL.md body (not truncated)

## Planning skills

If your Roo Code build exposes native Agent Skills / `SKILL.md` support, install `mvp-architect` and `convert-to-sdi` through that skill system and copy each whole skill directory from this repo, preserving `SKILL.md` and `references/`.

If your installed Roo version only exposes custom modes and rules, keep planning inside Roo by adapting each planning skill into a dedicated custom mode or mode-specific rule. The important constraint is the same: planning should run in the tool the user is actually using, not in a separate Claude Code or Codex session.

## File restrictions detail

The `groups` `edit` entry uses a regex to prevent silent rewrites of PRD/ARCHITECTURE/ROADMAP. The discipline allows revision notes (small additions at the top) but not full rewrites. Roo's regex restriction is the hard fence; the system prompt is the soft fence. Both reinforce the same rule.

For a stricter pattern that also blocks `IMPLEMENTATION_PLAN_*.md` (both `PHASE_N` and `<slug>` variants):

```yaml
- - edit
  - fileRegex: ^(?!docs/(PRD|ARCHITECTURE|ROADMAP|IMPLEMENTATION_PLAN_[\w-]+)\.md$).*
    description: Plan files take revision notes only; PRD/ARCH/ROADMAP edited only at end-of-phase housekeeping
```

The `[\w-]+` matches `PHASE_1`, `PHASE_2`, `billing-portal`, `q1-perf-pass`, etc. Note the trade-off: the agent will then need to ask permission before adding any revision note, which is friction.

## Global vs project scope

- **Per-project `.roomodes`** is the default and preferred when the SDI mode is tied to a project that has the `sdi-framework` artifacts.
- **Global `settings/custom_modes.yaml`** is convenient when SDI is your default discipline across many projects. The path is in Roo's config directory (resolves to your user settings folder; see Roo's docs for the exact OS-specific path).

## Tips

- **Updating the discipline:** when this framework updates `SKILL.md`, re-paste the body into `.roomodes` (or update the global YAML) and reload the workspace.
- **One mode per workspace** is fine — no need to nest sdi-mode inside other modes.
- **Mode-switch ritual:** when leaving implementation for scoping, switch out of SDI mode and use the native `mvp-architect` / `convert-to-sdi` skill or equivalent planning mode. SDI mode's discipline is for execution, not exploratory thinking.
