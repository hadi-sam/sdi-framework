# Roles & Orchestration — how SDI executes a plan

This is the execution model for `sdi-mode`. The work-item operating profile in
the plan's §0 names the models, vendors and efforts for implementation and
review. It is set once by the PO and reused for the whole item.

- **PM / orchestrator** — the main session. Audits, writes briefs, dispatches,
  reconciles verdicts and owns the paper trail. It does not author or review
  production code.
- **Engineer** — implements in an exclusive writable worktree, runs the scoped
  checks and creates commit A. The Engineer selection also covers Fix and Merge
  Engineer unless §0 explicitly overrides it.
- **Reviewer** — receives the same self-contained packet as its peers in a fresh
  read-only session, edits no repository file, and returns findings plus a
  non-empty final verdict.

Before the first dispatch, read §0. If a function to be dispatched is marked
`Pendente`, ask the PO once, persist the answer there, and then reuse it. Never
invent a model, vendor, effort or reviewer quantity. A rate limit, invocation
failure or unusable output is measured unavailability: return to the PO to pause
or choose a replacement. Persist a replacement for the item unless the PO says
it applies only once. Independent reviewers from different vendors are
recommended, not a gate or a reason to label a run degraded.

## Proportional execution

Every role follows the canonical proportionality rule in [`../SKILL.md`](../SKILL.md)
§"Proportionality rule". The PM chooses the smallest reviewable slice and only
dispatches concurrent Engineers when the plan's independent, non-overlapping
slices make that useful. No fixed agent count is part of the framework.

The PM may combine foundation, implementation and housekeeping reports into one
round when they do not represent distinct risk, decision or delivery boundaries.
Audit still precedes writing. A required user gate still stops the work before
code, migration, production action or other gated change.

## The per-round cycle

1. Capture `BASE_SHA` before the round.
2. Give each Engineer a bounded brief and exclusive writable worktree. Each
   Engineer creates its own code-only commit A and reports the exact checks run.
3. The PM writes the factual report commit B. A report records what changed,
   evidence, consequence and links; it does not require a test-count census.
4. When risk or contract justifies independent review, dispatch the reviewers in
   parallel with the same packet and reconcile only after all scheduled outputs
   return. Apply the cap and verdict rules in [`auto-review-mode.md`](auto-review-mode.md).
5. Route a confirmed code fix to the profiled Fix Engineer. The PM may fix only
   its paper-trail artifacts. A non-obvious choice returns to the PO.

CP1 audit and CP5 housekeeping responsibilities remain mandatory, but their
reports need not be standalone checkpoints. A user gate is required for an open
product/architecture/scope decision, irreversible action, production action or
material risk. The final live smoke remains user-run when the plan requires it.

## Worktree and merge rules

One Engineer owns each file slice. Concurrent slices start from the same
`BASE_SHA` in exclusive worktrees and must not overlap. The PM may merge clean,
non-overlapping commits. A conflict that requires a code choice goes to the
profiled Merge Engineer; the PM does not resolve it by authoring code.

## Engineer brief template

```text
You are the Engineer for [ROUND_ID]. Model/vendor/effort: [PROFILE_ENTRY].

Work only in the exclusive writable worktree [WORKTREE_PATH] at [BASE_SHA].
Your authorized slice is [FILES/DIRS]. Do not access external directories or PII.

Deliver [BEHAVIOR] per [PLAN_PATH] §[SECTIONS]. Apply the proportionality rule:
make the smallest change needed for the real flow and contracts; do not add an
abstraction, adjacent refactor, instrumentation, hardening or test without a
demonstrated requirement. A new test is allowed only for material silent harm
to data/access or an acceptance criterion explicitly approved by the PO.

Run only [SCOPED CHECKS] and report exact commands/results/skips. Create the
code-only commit `round X/CN: <summary>`. Do not edit plans, DECISIONS,
KNOWN_ISSUES, memory or round reports.

Return: commit SHA, changed files, checks, and any exception. Stop and report if
the plan contradicts the repo, a non-obvious decision is needed, a check fails
without an obvious scoped fix, or work would leave this slice.
```

## Reviewer dispatch contract

Reviewers receive the filled prompt, never a review skill. Each run must use the
profile's explicit model and effort, start without coordinator conversation
context, be read-only and non-persistent, and produce an exit-zero, non-empty
final artifact with evidence it read or grepped the target. Use the same target,
packet and rubric for every scheduled reviewer and dispatch in parallel. Any
failed reviewer returns to the PO; there is no automatic fallback.

For a round/diff, fill the prompt in [`auto-review-mode.md`](auto-review-mode.md).
For a plan or standalone target, fill
[`../../sdi-review/references/adversarial-review-prompt-template.md`](../../sdi-review/references/adversarial-review-prompt-template.md).

## Cross-tool recipes

Use a native subagent when the profile can be dispatched with the required
read/write boundary. Otherwise use the other tool's CLI. These examples are
vendor-specific invocation recipes, not defaults; replace every placeholder
from §0. If the installed runtime cannot honor the boundary, stop for the PO.

### Claude CLI reviewer (read-only)

Run from the reviewed repo. Add only the repo itself or an explicitly authorized
sibling; do not add PII or credential directories.

```bash
claude -p \
  --model <full-model-id> \
  --effort <level> \
  --safe-mode \
  --permission-mode plan \
  --permission-prompts none \
  --tools 'Read,Glob,Grep,Bash' \
  --add-dir <repo-or-authorized-sibling> \
  --no-session-persistence \
  --output-format text \
  < prompt.txt > review-output.md
test $? -eq 0 && test -s review-output.md
```

`--bare` requires `ANTHROPIC_API_KEY` or `apiKeyHelper` and does not read OAuth
or keychain authentication. Do not use a permission bypass.

### Codex CLI reviewer (read-only)

```bash
codex exec --ephemeral \
  --sandbox read-only \
  --model <model-id> \
  -c 'model_reasoning_effort="<level>"' \
  --color never \
  --output-last-message review-output.md \
  -C <repo> \
  - < prompt.txt
test $? -eq 0 && test -s review-output.md
```

### Claude CLI Engineer (exclusive writable worktree)

Run with the worktree as the current directory and do not add another directory.
The shell redirects the final message to PM-owned scratch outside the worktree;
that does not grant the model access to the scratch directory.

```bash
claude -p \
  --model <full-model-id> \
  --effort <level> \
  --safe-mode \
  --permission-mode acceptEdits \
  --permission-prompts none \
  --tools 'Read,Glob,Grep,Edit,Write,Bash' \
  --no-session-persistence \
  --output-format text \
  < engineer-brief.txt > [PM_SCRATCH_OUTPUT]
test $? -eq 0 && test -s [PM_SCRATCH_OUTPUT]
```

### Codex CLI Engineer (exclusive writable worktree)

```bash
codex exec --ephemeral \
  --sandbox workspace-write \
  --model <model-id> \
  -c 'model_reasoning_effort="<level>"' \
  --color never \
  --output-last-message [PM_SCRATCH_OUTPUT] \
  -C <exclusive-worktree> \
  - < engineer-brief.txt
test $? -eq 0 && test -s [PM_SCRATCH_OUTPUT]
```

Engineer output is not success without the expected commit A and a clean scope
check. Never add permission-bypass flags or authorize siblings for convenience.

## Ad-hoc review

When `sdi-review` has no plan/work item, ask for the review profile once and
record it in the first review artifact's header. Reuse it only for that review
invocation; it is not global configuration.
