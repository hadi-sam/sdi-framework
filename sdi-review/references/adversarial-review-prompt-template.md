# Adversarial review prompt template

The self-contained adversarial prompt that `sdi-review`'s **coordinator hands each dispatched reviewer** (Opus / Sonnet / Codex / Haiku). It is what a reviewer receives — **never the `sdi-review` skill itself**; a reviewer that loads the skill would re-coordinate (dispatch its own reviewers) instead of reviewing. The same prompt is also usable **ad-hoc/manually** — when you want a second pair of eyes on a plan, a doc, a branch, a function, or a sketch.

The `sdi-mode` **PM/orchestrator** dispatches reviewers the same way (see `sdi-mode/references/roles-and-orchestration.md`): for a **plan or standalone target** it fills *this* template; for a **round/diff target** it fills the embedded template in `sdi-mode/references/auto-review-mode.md`. Either way the dispatched reviewer gets the **filled prompt, never a skill** — the prompt-not-skill rule, from both sides.

Adapted from `sdi-mode/references/auto-review-mode.md` §"Adversarial review prompt template", with the implementer-loop scaffolding (round report, BASE_SHA, plan sections, prior findings) stripped and replaced with manual placeholders the coordinator fills before dispatching.

## How to use

1. Copy the prompt block below verbatim.
2. Replace the four placeholders: `[TARGET]`, `[CONTEXT]`, `[FOCUS]`, `[OUT_OF_SCOPE]`.
3. Paste into a fresh chat with the reviewer (Claude/Codex/etc). A fresh session is the point — the reviewer should not inherit your reasoning.
4. Read the BOTTOM LINE first; then walk the findings in order of class.

The reviewer should be a different model from the one that produced the target when possible — model diversity finds disjoint bugs.

## Filling the placeholders

| Placeholder | What goes in it | Example |
|---|---|---|
| `[TARGET]` | What is being reviewed. A file path, a commit range, a function name, or pasted-inline content. Be specific so the reviewer doesn't have to guess. | `the plan in docs/PROPOSAL_BILLING_REWRITE.md`<br>`the diff main..feature/auth-refactor`<br>`the function processWebhook in src/webhooks/handler.ts`<br>`the architecture sketch I'm pasting below: <paste>` |
| `[CONTEXT]` | What the reviewer needs to know that isn't in the target itself. Stack, project state, related docs to read, recent decisions. Keep it tight — a paragraph or a short bullet list. | `Next.js 15 App Router + Drizzle + Postgres. The current auth flow lives in src/auth/. We just shipped passkeys last week (DECISIONS.md entry 2026-04-21). Read AGENTS.md or CLAUDE.md for conventions.` |
| `[FOCUS]` | What you're worried about, or "open adversarial review" for general. Weight findings here but don't suppress others. | `whether the migration is reversible if we have to roll back mid-deploy`<br>`race conditions when two tabs hit submit at the same time`<br>`open adversarial review` |
| `[OUT_OF_SCOPE]` | What's already decided, what NOT to relitigate, hard requirements you've already weighed. Optional but useful — avoids noise. | `library choice (Drizzle stays); naming conventions; whether to use server actions vs route handlers (already decided in DECISIONS.md)` |

If `[OUT_OF_SCOPE]` is empty, write `none — open review`.

## The prompt

Copy from the next line through the closing backticks, fill the placeholders, and paste.

```
You are an adversarial reviewer. Your job is to find what is wrong, weak, or misrepresented in the target — not to validate it.

## Target

[TARGET]

## Context

[CONTEXT]

## Specific focus

[FOCUS]

## Out of scope

[OUT_OF_SCOPE]

---

## Stance

Default to skepticism. The author wants this to ship or work and may overstate confidence. Assume claims are overstated until evidence confirms them. Trust only what you can verify in the target itself, the context I gave you, or what you can read/grep in the repo.

You may run targeted read-only checks (read files, grep, run tests if I say so explicitly). Do NOT edit anything. If something I referenced is unclear or missing, ask me — do not guess.

## Steps

1. Read the target end to end before forming any opinion.
2. Read the context I pointed you at (named files, related docs, `AGENTS.md` / `CLAUDE.md` if either exists).
3. For every concrete reference in the target — file, function, helper, env var, dep, test, hook, convention — verify it exists and actually does what the target assumes. Use git/ls/cat/grep.
4. If the target is a plan or proposal: walk through how it would actually be implemented step by step; flag where the plan glosses over a hard part or assumes work that isn't trivial.
5. If the target is code: trace the unhappy paths — bad input, retry, concurrent calls, partial failure, timeouts, empty state, degraded dependency.
6. For the specific focus, weight findings there but still report any other material issue you can defend.

## What to actively check

A. Internal consistency. Does the target contradict itself across sections?
B. External consistency. Does the target contradict the context I gave you, existing code, or documented conventions?
C. Cross-references. Every named file/function/env var/dep/test the target leans on — verify it exists and behaves as assumed.
D. Hidden assumptions. What does the target assume that isn't stated and might not hold? Name them.
E. Unhappy paths. Bad input, retries, concurrent calls, partial failure, timeouts, empty state, degraded dependency — does the target survive each?
F. High-blast-radius risk. Auth/tenant isolation and trust boundaries; data loss, duplication, or irreversible state changes; rollback safety, retries, partial failure, idempotency gaps; ordering assumptions and re-entrancy; version skew, schema drift, migration hazards; observability gaps that hide failure or block recovery.
G. Vague claims. "Tests pass", "performant", "secure", "scalable", "easy to extend" without evidence — flag and say what would constitute proof.
H. Scope risk. Is the target trying to do too much in one step? Is there a piece that should be its own decision or its own change?
I. SDI plan-vs-bundle (only when [TARGET] is an SDI implementation plan). Does the plan contradict a `DECISIONS.md` entry? Does it misreference or fail to status-gate a `KI-NNN` from `KNOWN_ISSUES.md`? Does it violate PRD/ARCHITECTURE precedence (PRD and ARCHITECTURE win over the plan)? Is each round's output evidenceable from THAT round's deliverable, not a downstream one?
K. Verify-before-claim audit. For every concrete reference in `[TARGET]` — method, class, hook, file:line, precedent ("mirrors pattern of X"), count ("N sites to change") — Grep/Read and confirm it exists in the shape claimed. Invented / fictitious citations are class-3 (missing prerequisite); shape mismatches are class-1 (internal inconsistency). Especially watch for assertions like "(already exists in code)" / "(method available)" / "(N sites)" without Grep evidence immediately before the assertion.

## Bug classes (use to organize findings)

1. Internal inconsistency — target contradicts itself, or two parts disagree.
2. External contradiction — target contradicts the context, existing code, or repo convention.
3. Missing prerequisite — references something that doesn't exist, or doesn't do what's assumed.
4. Vague or unverifiable claim — cannot be marked done/correct from evidence.
5. Decision-worthy choice without justification — non-obvious trade-off treated as obvious.
6. Architecture or convention mistake.
7. Other — surprising, risky, or load-bearing in a way the author didn't flag.
K. Verify-before-claim violation — target cited a method/class/hook/file:line/precedent/count that doesn't exist in the codebase as claimed (semantically same role as class-3, but distinguishes "reviewer-discovered fictitious citation" from "code reference to nonexistent symbol").

## Calibration

Prefer one strong, defensible finding over several weak ones. Do not dilute class 1-4 findings with marginal class 7 noise. Speculative or cosmetic concerns: omit. Every finding should be worth me acting on. If the target looks solid, say so directly and return no findings.

## Output

Findings-first. Do not summarize what works. For each finding:
- Class (1-7).
- Where (file:line, or section heading if it's a doc, or "the assumption that X" if it's an unstated assumption).
- What is wrong (one sentence).
- Why it bites (one sentence — the failure scenario, not just the rule violated).
- Suggested fix or what would need to be true to resolve it (one sentence).

End with TWO lines:
- TOTAL FINDINGS: N. By class: 1=a, 2=b, 3=c, 4=d, 5=e, 6=f, 7=g, K=k.
- BOTTOM LINE: <SHIP | FIX-THEN-SHIP | RETHINK | BLOCK> + one sentence saying why.

**Output format hint:** wrap method/class/symbol references in backticks always (enables convergence-check symbol extraction when this prompt feeds into an automated loop).

BOTTOM LINE rules:
- SHIP — zero findings of class 1-6 or K; class 7 only if minor and optional.
- FIX-THEN-SHIP — at least one class 1-4, 6, or K finding, but all are mechanically fixable without rethinking the approach.
- RETHINK — at least one class 5 finding (decision needs to be made deliberately), or the structure is wrong enough that fixing one finding at a time won't help.
- BLOCK — class 7 marked urgent, or something I as the author need to stop and address before any further work on this target.

Do NOT edit any files. Your response is the review report itself.
```

## When NOT to use this

- **Mid-implementation auto-review for an SDI round.** Use the orchestrated prompt in `sdi-mode/references/auto-review-mode.md` instead — it's wired to BASE_SHA, the round report, and the FAIL/ESCALATE loop the `sdi-mode` PM/orchestrator expects.
- **Greenfield product scoping or fresh idea capture.** Use `mvp-architect` — adversarial review on something that doesn't exist yet is theater.
- **A code-style or convention nit pass.** This prompt's calibration explicitly suppresses style findings. Use a different reviewer or a linter.
- **You want validation, not interrogation.** This prompt is biased toward finding problems. If you want a balanced "what's good and what's bad" read, ask for that explicitly in a different prompt.

## Pairing with codex exec or a subagent

If you want to run this review headless (background process, structured artifact), the same template works. **Two steps, do not skip step 1:**

### Step 1 — Write the filled prompt to a file

```
cat > my-filled-review-prompt.txt <<'PROMPT_EOF'
<the full filled prompt — all four placeholders replaced>
PROMPT_EOF
```

The heredoc delimiter MUST be quoted (`'PROMPT_EOF'`) so bash doesn't expand `$variables` or backticks inside the prompt content.

### Step 2 — Invoke codex with stdin redirected from the file

```
codex exec --ephemeral --sandbox read-only \
  --output-last-message review-output.md \
  -C . \
  - < my-filled-review-prompt.txt
```

The `- < file` pattern is load-bearing: the `-` argument tells codex to read prompt from stdin, the `< file` feeds the file as stdin AND closes naturally on EOF.

**Never pass the prompt as a positional argument** (e.g., `codex exec ... "$(cat <<EOF ... EOF)"`). In any non-TTY shell (Claude Code Bash, CI, background tasks), codex sees "stdin is piped" and tries to read it to append to the positional prompt; stdin never closes; the process hangs with 0 bytes output. Always use stdin redirect.

**Pre-flight:** ensure the directory containing the `--output-last-message` path exists (e.g., `mkdir -p docs/reviews` if writing there). Codex exits 0 even when the output file can't be written, so a missing parent dir results in a silently empty/absent reviewer output.

---

Or pass the filled prompt to an Agent subagent (Anthropic Agent tool, `subagent_type: general-purpose`, `model: opus` / `sonnet` / `haiku`) as the `prompt` argument — no stdin gymnastics needed; the subagent runtime handles input. The output is the review report. The coordinator dispatches one such subagent per ensemble reviewer, in parallel — Opus + Sonnet via the Agent tool, Codex via the `codex exec` block above (or a Haiku subagent if Codex is down). **Pass the filled prompt, never the skill.**
