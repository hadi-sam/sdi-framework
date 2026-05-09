# OpenCode — SDI Mode Installation Guide

This guide shows how to install `sdi-mode` as a custom agent in OpenCode (sst/opencode).

## Prerequisites

- OpenCode installed
- This `sdi-framework/` repo cloned or accessible
- A project where you want SDI mode active

## What you're configuring

OpenCode supports custom agents and native `SKILL.md` skills. Use the agent for `sdi-mode` implementation sessions, and use skills for `mvp-architect` / `convert-to-sdi` planning.

There are two ways to define the `sdi` implementation agent — pick one:

1. **Markdown agent file** (recommended) — a `.md` file with YAML frontmatter; the body is the system prompt. Cleanest path for long prompts like SKILL.md.
2. **JSON config** — `opencode.json` at the project root or `~/.config/opencode/opencode.json` globally, under the `agent` key. Supports `{file:...}` references so you don't need to inline SKILL.md.

OpenCode can also read `AGENTS.md` from the project root. Use that for project-specific conventions and tool parity; use the dedicated `sdi` agent when you want explicit agent selection, prompt isolation, and permission defaults for SDI implementation sessions.

Two scopes:

- **Project** — `.opencode/agents/sdi.md` or project-root `opencode.json`
- **Global** — `~/.config/opencode/agents/sdi.md` or `~/.config/opencode/opencode.json`

The filename of a markdown agent file becomes its identifier (e.g., `sdi.md` → `sdi` agent).

## Approach A — Markdown agent file (recommended)

Create `.opencode/agents/sdi.md`:

```markdown
---
description: Spec-Driven Implementation discipline. Use after planning is complete.
mode: primary
color: "#3b82f6"
permission:
  edit:
    "*": allow
    "docs/PRD.md": ask
    "docs/ARCHITECTURE.md": ask
    "docs/ROADMAP.md": ask
    "docs/IMPLEMENTATION_PLAN_*.md": ask
  bash:
    "*": ask
    "git status": allow
    "git diff*": allow
    "git log*": allow
  webfetch: ask
---

<paste the body of sdi-framework/sdi-mode/SKILL.md here — start at "# SDI Mode — Spec-Driven Implementation" and skip the YAML frontmatter at the top of SKILL.md (that block is skill-discovery metadata, not part of the system prompt)>
```

The body is the system prompt. Markdown formatting is preserved verbatim.

**Frontmatter fields used here:**

| Field | Purpose |
|---|---|
| `description` | Shown in the agent picker |
| `mode` | `primary` (user-selectable) / `subagent` (only callable from another agent) / `all` |
| `color` | UI color (hex or `primary`/`secondary`/`accent`/`success`/`warning`/`error`/`info`) |
| `permission.edit` | `allow` / `ask` / `deny`, optionally keyed by file glob |
| `permission.bash` | Either a flat value or an object keyed by glob patterns |
| `permission.webfetch` | Network access |

Other available fields: `model`, `temperature`, `top_p`, `steps`, `hidden`, `disable`. Permission also supports `task` for subagent invocation control.

> **Note on file-edit restrictions.** OpenCode supports glob-based `permission.edit` rules. The example above lets normal edits proceed, but requires approval before any write to canonical SDI artifacts that should only receive revision notes or housekeeping updates. For a stricter setup, change those `ask` entries to `deny`.

> **About the SKILL.md frontmatter:** the `---`-delimited block at the top of `SKILL.md` (with `name:` and `description:`) is metadata used by skill discovery in Claude Code / Codex. It is **not** part of the SDI discipline and should not be pasted into the agent prompt. Approach A: start your paste at the first heading (`# SDI Mode — Spec-Driven Implementation`). Approach B: the `{file:...}` reference loads the whole file as-is, but OpenCode treats the leading frontmatter as content; if it interferes with your prompt, strip the frontmatter from a copy of `SKILL.md` and point `{file:...}` at the stripped copy.

## Approach B — JSON config (with `{file:...}` reference)

This is the cleanest way to avoid copying SKILL.md content. Create or edit `opencode.json` at the project root:

```json
{
  "agent": {
    "sdi": {
      "description": "Spec-Driven Implementation discipline. Use after planning is complete.",
      "mode": "primary",
      "color": "#3b82f6",
      "prompt": "{file:./sdi-framework/sdi-mode/SKILL.md}",
      "permission": {
        "edit": {
          "*": "allow",
          "docs/PRD.md": "ask",
          "docs/ARCHITECTURE.md": "ask",
          "docs/ROADMAP.md": "ask",
          "docs/IMPLEMENTATION_PLAN_*.md": "ask"
        },
        "bash": {
          "*": "ask",
          "git status": "allow",
          "git diff*": "allow",
          "git log*": "allow"
        },
        "webfetch": "ask"
      }
    }
  }
}
```

The `{file:...}` syntax loads the prompt from disk at config-parse time. Path is relative to the config file location. **This means SKILL.md updates are picked up automatically on the next OpenCode reload — no re-paste required.**

If you don't have `sdi-framework/` cloned inside your project, point the path at wherever you keep the repo, e.g. `{file:/Users/me/repos/sdi-framework/sdi-mode/SKILL.md}` (absolute) or `{file:../sdi-framework/sdi-mode/SKILL.md}` (relative).

For a global config, use `~/.config/opencode/opencode.json` with the same `agent.sdi` schema.

## Planning skills

Install `mvp-architect` and `convert-to-sdi` as native OpenCode skills:

- Project scope: `.opencode/skills/mvp-architect/SKILL.md` and `.opencode/skills/convert-to-sdi/SKILL.md`
- Global scope: `~/.config/opencode/skills/mvp-architect/SKILL.md` and `~/.config/opencode/skills/convert-to-sdi/SKILL.md`

OpenCode also discovers compatible skills in `.claude/skills/`, `.agents/skills/`, `~/.claude/skills/`, and `~/.agents/skills/`. Copy each whole skill directory from this repo, preserving its `SKILL.md` and `references/` folder.

If you restrict skills through OpenCode permissions, allow these two names:

```json
{
  "permission": {
    "skill": {
      "*": "ask",
      "mvp-architect": "allow",
      "convert-to-sdi": "allow"
    }
  }
}
```

## Step 2 — Activate

1. Reload OpenCode (restart or use the reload command).
2. Select `sdi` in the agent picker.
3. Confirm the agent badge shows it's active.

## Step 3 — Smoke test

Ask:

> "List the 8 steps of SDI discipline."

Expected: Read → Audit → Propose → Implement in rounds → Tests alongside → DECISIONS.md / KNOWN_ISSUES.md / memory → Revision notes → End-of-phase housekeeping.

If the agent improvises:
- Verify the file exists at `.opencode/agents/sdi.md` (Approach A) or that the `{file:...}` path resolves (Approach B)
- Check that the agent is selected (not the default)
- Confirm config syntax is valid (no parse errors in OpenCode's output)

## Tips

- **`{file:...}` is a killer feature.** With Approach B, SKILL.md updates flow through automatically — no copy-paste cycle. This is the recommended setup if you have `sdi-framework/` checked out as a sibling or sub-directory of your project.
- **Planning vs implementation.** Keep `mvp-architect` and `convert-to-sdi` as skills, not primary implementation agents. Use the `sdi` agent only once a plan exists and code is being written.
- **Updating SKILL.md:** Approach A → re-paste the body and reload. Approach B → no action; reload picks up the new file content.
- **Permission tuning:** `bash: { "*": "ask" }` is the safest default. As trust grows on a project, you can add `"npm test": "allow"`, `"npm run *": "allow"`, etc.
