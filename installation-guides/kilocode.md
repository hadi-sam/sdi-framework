# Kilo Code — SDI Mode Installation Guide

This guide shows how to install `sdi-mode` as a custom agent in Kilo Code.

## Prerequisites

- Kilo Code installed
- This `sdi-framework/` repo cloned or accessible (you'll copy the body of [`SKILL.md`](../sdi-mode/SKILL.md) into the agent file)
- A project where you want SDI mode active

## What you're configuring

Kilo Code supports custom agents and native `SKILL.md` skills. Use the agent for `sdi-mode` implementation sessions, and use skills for `mvp-architect` / `convert-to-sdi` planning.

There are two ways to define the `sdi` implementation agent — pick one:

1. **Markdown agent file** (recommended) — a `.md` file with YAML frontmatter; the body becomes the system prompt. Cleanest because there's no escaping.
2. **JSON config** — `kilo.jsonc` at project root.

Kilo can also read `AGENTS.md` from the project root. Use that for project-specific conventions and tool parity; use the dedicated `sdi` agent when you want explicit agent selection, prompt isolation, and permission defaults for SDI implementation sessions.

Agent scopes:

- **Project** — `.kilo/agents/sdi.md` or project-root `kilo.jsonc`.
- **Global** — `~/.config/kilo/agent/sdi.md` or `~/.config/kilo/kilo.jsonc`. Some Kilo versions also accept `~/.config/kilo/agents/`. (On Windows: `C:\Users\<user>\.config\kilo\...`)

## Approach A — Markdown agent file (recommended)

Create `.kilo/agents/sdi.md` in your project (or `~/.config/kilo/agent/sdi.md` for global):

```markdown
---
description: Spec-Driven Implementation discipline. Use after planning is complete.
mode: primary
color: "#3b82f6"
permission:
  edit:
    "docs/PRD.md": deny
    "docs/ARCHITECTURE.md": deny
    "docs/ROADMAP.md": deny
    "*": allow
  bash: ask
---

<paste the body of sdi-framework/sdi-mode/SKILL.md here — start at "# SDI Mode — Spec-Driven Implementation" and skip the YAML frontmatter at the top of SKILL.md (that block is skill-discovery metadata, not part of the system prompt)>
```

The body of the file (everything after the closing `---`) becomes the system prompt. Markdown formatting is preserved.

**Frontmatter fields used here:**

| Field | Purpose |
|---|---|
| `description` | Shown in the agent picker |
| `mode` | `primary` (selectable as the active agent) / `subagent` / `all` |
| `color` | UI color in agent picker (hex or named keyword) |
| `permission.edit` | Per-glob file-edit restrictions; `deny` blocks the listed canonical artifacts |
| `permission.bash` | `allow` / `ask` / `deny` for shell commands |

Other available frontmatter fields: `model`, `temperature`, `top_p`, `steps`, `hidden`, `disable`. See Kilo's docs for the complete list.

## Approach B — JSON config (`kilo.jsonc`)

If you prefer keeping all agents in one config file, create `kilo.jsonc` at the project root:

```jsonc
{
  "agent": {
    "sdi": {
      "description": "Spec-Driven Implementation discipline. Use after planning is complete.",
      "mode": "primary",
      "color": "#3b82f6",
      "prompt": "<JSON-escaped body of SKILL.md, OR a {file:./path/to/SKILL.md} reference if your version supports it; in either case skip the YAML frontmatter at the top of SKILL.md>",
      "permission": {
        "edit": {
          "docs/PRD.md": "deny",
          "docs/ARCHITECTURE.md": "deny",
          "docs/ROADMAP.md": "deny",
          "*": "allow"
        },
        "bash": "ask"
      }
    }
  }
}
```

**Caveat:** the `prompt` field needs JSON-escaped newlines (`\n`). For long content like the SKILL.md body, the markdown agent file approach (A) is much easier — that's why it's recommended.

> **About the SKILL.md frontmatter:** the `---`-delimited block at the top of `SKILL.md` (with `name:` and `description:`) is metadata used by skill discovery in Claude Code / Codex. It is **not** part of the SDI discipline and should not be pasted into the agent prompt. Start your paste at the first heading (`# SDI Mode — Spec-Driven Implementation`).

## Planning skills

Install `mvp-architect` and `convert-to-sdi` as native Kilo skills:

- Project scope: `.kilo/skills/mvp-architect/SKILL.md` and `.kilo/skills/convert-to-sdi/SKILL.md`
- Global scope: `~/.kilo/skills/mvp-architect/SKILL.md` and `~/.kilo/skills/convert-to-sdi/SKILL.md`

The Kilo CLI also supports compatibility directories such as `.claude/skills/` and `.agents/skills/`. Copy each whole skill directory from this repo, preserving its `SKILL.md` and `references/` folder.

If you are on the legacy VS Code extension path, older docs may refer to `.kilocode/skills/` and mode-specific folders such as `skills-code/`. Prefer `.kilo/skills/` for current Kilo unless your installed version documents otherwise.

## Step 2 — Activate

1. Reload Kilo Code (or restart) so the agent config is picked up.
2. Open Kilo's agent/mode selector.
3. Choose `sdi`.
4. Verify the agent badge shows it's active.

## Step 3 — Smoke test

Ask:

> "List the 8 steps of SDI discipline."

Expected: Read → Audit → Propose → Implement in rounds → Tests alongside → DECISIONS.md / KNOWN_ISSUES.md / memory → Revision notes → End-of-phase housekeeping.

If the agent improvises:
- Verify the agent file path (`.kilo/agents/sdi.md` or the JSON config path) is correct
- Check that the markdown body / `prompt` field actually contains the SKILL.md body (not truncated)
- Confirm `sdi` is the selected agent (not the default)

## File restrictions

The `permission.edit` block enforces the framework's "PRD/ARCHITECTURE/ROADMAP edit only via revision notes" rule as a hard fence. The system prompt's discipline is the soft fence — both reinforce the same behavior.

To also block `IMPLEMENTATION_PLAN_*.md` from full rewrites:

```yaml
permission:
  edit:
    "docs/PRD.md": deny
    "docs/ARCHITECTURE.md": deny
    "docs/ROADMAP.md": deny
    "docs/IMPLEMENTATION_PLAN_*.md": ask
    "*": allow
```

Glob `*` matches the slug or `PHASE_N` part. `ask` requires explicit user approval per edit, which suits "revision notes only" semantics — the agent has to surface what it's about to change.

## Tips

- **Planning vs implementation.** Keep `mvp-architect` and `convert-to-sdi` as skills, not primary implementation agents. Use the `sdi` agent only once a plan exists and code is being written.
- **Global vs project:** per-project `.kilo/agents/sdi.md` travels with the repo. Global `~/.config/kilo/agent/sdi.md` is convenient when SDI is your default discipline everywhere.
- **Updating the discipline:** when this framework updates `SKILL.md`, re-paste the body in the markdown approach, or re-escape the string in the JSON approach. Either way, reload Kilo afterward.
- **Configuration precedence (lowest → highest):** built-in defaults → global config → project `kilo.jsonc` → `.kilo/agents/*.md` files → environment overrides. Project markdown agents win over JSON config; useful if you keep a global JSON baseline and override per-project.
