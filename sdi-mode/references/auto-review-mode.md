# Auto-Review Mode (default for Checkpoints 2/3/4 + CP5 comprehensive)

A workflow extension that delegates checkpoint verification to a **reviewer ensemble** — different-model Opus and Sonnet subagents plus a Codex CLI process — escalating to the user only when something needs human judgment. **Default-on** for Checkpoints 2, 3, and 4 (per-round review) and CP5 (comprehensive phase-wide review, escalation-only). CP1 stays user-gated. The user can opt out per session or request a different reviewer schedule.

## What this is

Implementation rounds end with structured verdicts from independent reviewers, deduplicated and classified into a **Decision Bundle** that either auto-applies obvious fixes or pauses for user judgment:

- **Attempt 1** runs **three reviewers in parallel**: an Opus subagent (via Anthropic Agent tool, `model: opus`), a Sonnet subagent (via Anthropic Agent tool, `model: sonnet`), and a Codex CLI process (`codex exec`, typically gpt-5.5 with reasoning effort `xhigh` per the user's `~/.codex/config.toml`).
- **Attempt 2** (if needed after a FAIL) runs **three reviewers in parallel** again: Opus + Sonnet + Codex. Sonnet stays because fix commits introduce new code that merits full ensemble review.
- **Attempts 3+** (if needed) run **two reviewers in parallel**: Opus subagent + Codex CLI. Sonnet drops at this point for cost/time; bug surface is smaller, but Opus+Codex diversity stays.

This 3/3/2+ schedule is the default unless the user explicitly asks for a different schedule for the session or round. The attempt-1 ensemble is load-bearing: different models find partially-disjoint bugs, and the union catches more than any one reviewer alone. Attempts 1-2 re-verify both original code and intermediate fixes (new bugs can appear); attempts 3+ focus on residual fixes.

Reviewers on a given attempt receive the **same self-contained prompt** (the adversarial review template below) with explicit cross-file checks (CSS classes used vs defined, API contracts caller-vs-handler, report-vs-reality, optimistic UI revert paths, verify-before-claim audit). Outputs are captured to `docs/reviews/round-XN-attempt-N-{opus,sonnet,codex}.md` as applicable for the audit trail.

Goals:
- Remove friction at low-stakes checkpoints without losing review depth.
- Get model diversity exactly where it matters most (first review of fresh code).
- Keep the discipline binary (gates pass or fail; no fuzzy "looks good").
- Preserve full audit trail so the user can spot-check.
- Escalate quickly when something needs human judgment.

Non-goals:
- Replacing human review of decisions or issue deferrals. Anything that needs a `DECISIONS.md` entry, or a new/changed `KNOWN_ISSUES.md` entry, escalates.
- Speeding up the implementer agent itself (auto-review is purely about the gate at the end of each round).
- Working without explicit per-gate criteria. A vague "review this" prompt produces theater.

## Per-round commit convention

Auto-review is structured around per-round git commits. Each round produces **at minimum 2 commits** (code + report); fix attempts add more pairs.

- **Start of round:** capture `BASE_SHA` = SHA of the **last `round X/CN review artifacts: <verdict>` commit** from the previous round. **NOT** "last commit of the previous round" — after the split-commit convention, the previous round ends with multiple commits (A code, B report, possible fix N pairs, finally review artifacts). Capturing literally the `review artifacts` SHA ensures `git diff BASE_SHA..HEAD` on the new round captures only the new work, without polluting with the previous round's review artifacts. Record BASE_SHA in the round report draft header.

  **Round A (first round of the phase) — special case:** BASE_SHA = `phase-start commit`, defined as the **previous phase's last `review artifacts` commit** (not an arbitrary pre-phase commit). For the very first phase of a project, BASE_SHA = `mvp-bundle commit` (last commit from mvp-architect Phase C). In all cases, BASE_SHA is a homogeneous "tagged endpoint" category — never a mid-stream scaffolding commit or in-progress round. If the previous phase closed without review artifacts (e.g., pre-SDI phase), the user creates a marker commit `phase N-1: closed (manual)` before starting the new phase to serve as BASE_SHA. Without this marker, Round A of a new phase diffs against mixed state and reviewers see pre-phase things as false findings.

  **PHASE_BASE_SHA:** the SHA of the Round A phase-start commit (same value as BASE_SHA at Round A). Used in CP5 comprehensive review packet (`git diff PHASE_BASE_SHA..HEAD` captures the entire phase). Recorded literally in the Round A round report header with label `PHASE_BASE_SHA:`; subsequent CPs reference this value literally.

- **End of round implementation, commit A (code-only):** all code/test/migration edits of the round in ONE commit, without the round report included. Message: `round X/CN: <summary>` (e.g. `round B/C2: callback + middleware`).

- **End of round paper trail, commit B (report-only):** the round report draft at `docs/reviews/round-XN-report.md` referencing the real SHA of commit A. Message: `round X/CN report: at HEAD <short-SHA-de-A>` (e.g. `round B/C2 report: at HEAD 2a7ee27`).

- **Fix attempts (if auto-review FAIL):** the code fix is also split — fix code commit + fix report addendum commit. Messages: `round X/CN fix N: <what>` (code) + `round X/CN fix N report: at HEAD <SHA>` (paper trail). If the fix is doc-only (e.g., correcting a gate restatement in the report), a single commit `round X/CN fix N: <what>` suffices.

- **Loop close (PASS, ESCALATE, or cap):** review artifacts commit with per-attempt outputs + final round report. Message: `round X/CN review artifacts: <verdict>`.

- **No squashing.** Granular history IS the audit trail.

**Why two commits per round:** the report knows the code commit's SHA because the code commit already exists when the report is written. Reviewers read a report with materialized values (not placeholders) on attempt 1. Eliminates an entire class of class-4 findings ("report claims SHA X but HEAD is Y") that previously infested attempts 1-3.

**Reviewers read the diff via `git diff BASE_SHA..HEAD`** — this remains valid. HEAD includes both commit A (code) and commit B (report), but reviewers already expect the report draft to be committed before review (the previous alternative of uncommitted-read was the source of drift).

**Trade-offs accepted:**
- +1 obligatory commit per round (higher granularity, cleaner audit trail)
- +2-3 minutes per round (trivial overhead vs 1-2 attempts wasted on chicken-egg drift)
- Small divergence from old convention (the `round X/CN: <summary>` message now refers only to code; previously it was code + report combined)

The reviewers read the code diff via `git diff BASE_SHA..HEAD` — so BASE_SHA stays fixed across all attempts in a round. Each attempt re-evaluates the round's deliverable in full (initial commit + any fix commits), not just the last fix delta. This protects against fix-attempt-N reintroducing a problem that passed in fix-attempt-N-1.

## Verification evidence policy

Auto-review audits the implementer's verification evidence; it does not move test ownership to the reviewers.

- **The implementer runs the checks required by the round before review.** This includes the relevant unit tests, integration tests, typecheck/lint/build, evals, or manual smoke checks called for by the plan and checkpoint gates.
- **The round report records exact evidence.** Include the command, result, test counts, skipped tests/checks, runtime-relevant notes, and any manual smoke evidence. "Tests pass" without command/result/count is not enough.
- **The reviewer judges sufficiency.** A reviewer may run targeted checks that are compatible with the runtime and sandbox, but is not required to rerun the whole suite. If the report's evidence is absent, vague, contradictory, or too weak for the gate, the reviewer returns `FAIL`.
- **Codex stays read-only by default.** `codex exec --sandbox read-only` is the default reviewer mode. Checks that require writing caches, build output, snapshots, local DB state, or generated files are the implementer's responsibility and must be evidenced in the report.

The reviewer's job is to verify that the implemented diff, the plan gates, and the reported verification evidence agree. A PASS means the evidence is adequate and no class 1-6 finding was found; it does not mean the reviewer reran every command.

## Preflight before invoking reviewers

Before building the packet or starting reviewers, the implementer performs a clean-state preflight:

1. Confirm `HEAD` contains **both** the current round's commit A (`round X/CN: <summary>`) and commit B (`round X/CN report: at HEAD <SHA>`), OR the current fix attempt's commits (`round X/CN fix N: <what>` + `round X/CN fix N report: at HEAD <SHA>` per the split-commit convention).
2. Run a working-tree check such as `git status --short`.
3. The only allowed uncommitted files are `.sdi-review-prompt-tmp.txt` and prior attempts' reviewer outputs at `docs/reviews/round-XN-attempt-*-{opus,sonnet,codex}.md` (these stay uncommitted between attempts to support convergence check — see §"Loop cap" convergence semantics).
4. If intended code/doc/test changes from the round are still uncommitted, commit them before review using the split-commit pattern.
5. If unrelated or user-owned changes are present, do not run auto-review. Escalate to the user with the file list and ask whether to commit, stash, move to a separate worktree, or switch to manual review.

Do not create a separate worktree by default. A review worktree is an explicit advanced fallback for cases where unrelated user-owned changes must remain in place or where a reviewer needs an isolated writable environment. Without a clean preflight, reviewers may compare `git diff BASE_SHA..HEAD` against files on disk that include unrelated uncommitted state, which makes the audit ambiguous.

## Disabling and re-enabling per session

**Auto-review is the default. Every new session starts with auto-review on.**

**Opt-out per session:** the user says any of:
- "user-review for this phase"
- "review the next round myself"
- "stop auto-reviewing"
- "back to user-gated"
- "no auto-review"

When opted-out, the implementer drops back to user-gated for the rest of the session — every checkpoint waits for an explicit user "go".

**Re-enable per session:** the user says any of:
- "auto-review again"
- "go back to auto-review"
- "switch back to auto-review"

**Persistence:** none. Every new session starts in default (auto-review on). This is intentional — opt-out is per-phase or per-session work-style, not a project-level setting.

**Where to record it:** if the user opts out, mention in today's `docs/memory/YYYY-MM-DD.md` entry (e.g., "User opted out of auto-review this session for the rest of Phase 2"). Breadcrumb only; the mode itself lives in the conversation.

## When auto-review applies

| Checkpoint | Eligibility |
|---|---|
| 1 — Foundation | **User-gated always.** Audit findings (DECISIONS material divergences, KNOWN_ISSUES entries) routinely trigger always-escalate; making auto-review CP1-eligible would be a near no-op. The user gates the audit directly. |
| 2 — Core domain logic | **Auto-review default-on.** |
| 3 — Wire up integrations | **Auto-review default-on.** |
| 4 — UI | **Auto-review default-on.** |
| 5 — Housekeeping | **Auto-review comprehensive — escalation-only.** See §"CP5 comprehensive review" below for distinct semantics (phase-wide diff, 1 attempt, no fix loop, per-CP packet split by default). |

Even within a default-on checkpoint, the round escalates immediately when any of the always-escalate triggers below fire.

## CP5 comprehensive review

CP5 review is distinct from CPs 1-4: reviewers look at the **entire phase** (diff between `PHASE_BASE_SHA` and `HEAD`), not just the round. Findings at CP5 are typically cross-checkpoint regressions, acceptance criteria without evidence, scope drift, or accumulated KNOWN_ISSUES debt — things that per-round reviews don't catch.

**Schedule:** Opus + Sonnet + Codex in parallel (1 attempt only).

**Behavior on FAIL/ESCALATE:** always escalate to the user. **No fix attempt loop.** Reason: CP5 findings are rarely "rename method X to Y"; they typically require a decision (rewind and reopen a previous CP, mark as KI, or accept as AC gap). Automatic loop risks the agent applying superficial patches to structural problems.

**Packet structure — per-checkpoint split is the DEFAULT:** reviewers read per-CP individually, aggregate findings in a final summary. Reason: real phases with 4 CPs easily exceed 30 kloc of phase-wide diff, and single-packet review overflows reviewers' context or produces shallow coverage. Per-CP split:
- For each CP delivered (CP1-CP4), packet contains: CP diff (`git diff CP_N-1_SHA..CP_N_SHA`), CP round reports, DECISIONS/KIs created during the CP.
- Reviewers produce 1 finding-set per CP + 1 cross-CP aggregation (regressions, scope drift, AC coverage).
- Decision Bundle aggregates findings from all CPs.

**Whole-phase packet — exception** only when phase-wide diff is small (e.g., maintenance pass with only CP1 + CP5 — CP1 is audit user-gated with no code changes directly attached, so effective diff = CP5 diff) AND reviewer context budget fits. Implementer declares mode in the round report (`packet_mode: per-cp-split` or `whole-phase`).

**CP5 follow-up fix rounds (procedure after escalation):** if CP5 returns findings that the user decides to fix (doc drift in PROJECT_STRUCTURE, AGENTS.md row missing, etc.), the user directs the implementer to apply them as `round Z/CP5 housekeeping fix N: <what>` (code-only commit) + `round Z/CP5 housekeeping fix N report` (paper trail B). **These follow-up rounds are user-gated** (NOT auto-review eligible) — at this stage of the phase, each edit is surgically user-directed; auto-review would add overhead without benefit.

**Re-running CP5 comprehensive after fixes:** the user may optionally trigger one more CP5 comprehensive review after housekeeping fixes to confirm findings were resolved. **No automatic loop** — each re-run is user-triggered. If re-run returns PASS, phase closes. If re-run returns FAIL again, **user decides next step depending on the nature of the problem**: typically continues applying fixes + re-running reviews until satisfied; can also accept remaining findings as `KNOWN_ISSUES.md` entries and close the phase, OR open a separate work item if the gap is too large. No framework-imposed limit — convergence is organic and defined by the user at each iteration.

## Always-escalate triggers (override auto-review default)

If any of these occur during the round, the implementer skips auto-review for that round and stops for the user:

1. **The round produced (or should produce) a `DECISIONS.md` entry.** A material divergence, a deferred feature, a non-obvious trade-off, a deviation from convention — by definition a judgment call. See `decisions-log-format.md` for what qualifies.
2. **The round discovered or changed a `KNOWN_ISSUES.md` entry.** A new out-of-scope bug/security gap/tech debt item, a severity/blast-radius change, a scheduled fix, a partial mitigation, or a resolved KI should be visible to the user.
3. **Blocker encountered during implementation.** Anything that prevents finishing the round (missing dependency the user needs to install, contradictory plan content, broken external service).
4. **Emergency deviation.** Per `stop-and-review-patterns.md` — security bug, data-loss risk, regression of previously-working functionality.
5. **Schema migration with data-loss risk** (drop column, NOT NULL on existing column without backfill, type change that loses precision). Even if tests pass, the user must approve.
6. **New external dependency added** beyond what the plan listed. Plan said use library X; the implementer pulled in library Y too. Escalate.
7. **Security-relevant change** beyond plan scope (auth helper added/changed, RLS policy modified, secret-handling code touched, CORS or CSP changed).
8. **Plan revision (`rN`) added during the round.** A revision means reality diverged from plan; the user should see what changed before the next round proceeds.
9. **PRD or ARCHITECTURE deviation.** If implementing a §2 surface required deviating from the higher-precedence doc, escalate (see `expected-artifacts.md` precedence rules).

Surface the trigger explicitly when escalating: "Auto-review skipped because [trigger]. Stopping for your review."

## Terminology: always-escalate vs judgment-required

Two related but distinct concepts share the idea of "escalation":

- **Always-escalate triggers** — **pre-review** gate. Conditions that make the implementer SKIP auto-review entirely for the round (DECISIONS entry, KI entry change, blocker, emergency, schema migration, etc.). Listed in §"Always-escalate triggers". The round goes to user-gated review directly; reviewers DO NOT run.

- **Judgment-required category** — **post-review** classification in the Decision Bundle. Findings that reviewers returned with verdict ESCALATE, or findings class 5 / class 7 urgent. Reviewers ran, returned results, and this specific finding needs user input (cannot be auto-applied).

Don't confuse: always-escalate skips auto-review; judgment-required pauses it after an attempt. Both stop for the user, but at different phases of the flow.

## The loop

1. Implementer finishes the round and commits the pair: **commit A (code-only)** + **commit B (report-only referencing A's SHA)** per the split-commit convention. Messages: `round X/CN: <summary>` (A) + `round X/CN report: at HEAD <short-SHA-de-A>` (B).
2. If an always-escalate trigger fired, or the user opted out / requested user-gated review, stop for the user.
3. Run the clean-state preflight (confirming both commit A and commit B exist), and build `.sdi-review-prompt-tmp.txt`.
4. Run the scheduled reviewers for the attempt:
   - Attempt 1: Opus subagent + Sonnet subagent + Codex, in parallel.
   - Attempt 2: Opus subagent + Sonnet subagent + Codex, in parallel.
   - Attempts 3+: Opus subagent + Codex, in parallel.
5. Apply reviewer timeout/fallback. If no scheduled reviewer produced usable output, stop for the user.
6. Parse verdicts and merge them (see §"Verdict merging").
7. **Dedup pass:** read the 2-3 reviewer outputs and deduplicate findings by (file:line + class), prioritizing convergence (3-way > 2-way > unique).
8. **Classify each deduplicated finding** as `obvious-fix`, `needs-decision`, or `judgment-required`:
   - `obvious-fix` = ALL these conditions:
     - Class 1-4, 6, or K (mechanical / contract / missing prereq / vague-claim / convention / fictitious citation).
     - At least 2 reviewers converge **OR** surviving single reviewer in degraded mode (when others failed — not based on attempt number).
     - Reviewer cites specific fix (rename X to Y, add field Z, fix line N) — not "consider refactoring".
     - Fix touches only files in the round's diff (`git diff BASE_SHA..HEAD --name-only`).
   - `needs-decision` = remaining general case:
     - Findings divergent across reviewers (Opus says X, Codex says Y).
     - Fix requires changing files outside the round.
     - Reviewer only describes problem, doesn't propose concrete fix.
   - `judgment-required` = reviewers returned verdict ESCALATE OR finding is class 5 (DECISIONS-worthy) or class 7 marked urgent:
     - Always presented to user, NEVER auto-applied regardless of convergence.
     - Preserves ESCALATE-wins-over-FAIL semantics from existing merge rule.
   - **Edge case zero findings after dedup:** if dedup leaves 0 findings in all 3 categories but reviewer verdict remained FAIL (e.g., reviewer wrote vague concerns without specific fix or actionable detail), create 1 synthetic class-5 finding marked `judgment-required` ("vague reviewer concern — needs user clarification: <quote reviewer wording verbatim>") and stop for input. Don't treat as PASS — preserve the FAIL signal. **Why class-5 (not class-4):** class-4 is "vague/unverifiable claim" but is mechanical / FAIL-eligible in the taxonomy; a finding whose only classification is "reviewer couldn't propose a fix" requires user judgment, which is by definition class-5 territory (DECISIONS-worthy / user input required).
9. **Present Decision Bundle** to the user (see §"Decision Bundle format"):
   - If ALL findings are `obvious-fix` (zero `judgment-required`, zero `needs-decision`, ≥1 `obvious-fix`) → bundle marked "AUTO-APPLY ELIGIBLE"; coding agent proceeds without waiting for response unless user interrupts; applies fixes, commits `round X/CN fix N: <what>` (code) + `round X/CN fix N report: at HEAD <SHA>` (paper trail), and retries.
   - If ANY `needs-decision` or `judgment-required` exists → stop and wait for input; recommend fix or option for each item; `judgment-required` items highlighted as "user judgment required — never auto-applied".
10. **Apply discipline** during auto-apply: the coding agent re-verifies the reviewer's claim via Grep/Read before editing. Example: reviewer says "rename validateUser to validateMember"; agent greps `validateUser` in the round's diff + greps `validateMember` to confirm target shape before the edit. If Grep contradicts reviewer, escalate that finding as `needs-decision` (don't auto-apply). **Anti-restatement:** when applying a fix for findings like "gate restates spec" (class 6 convention), NEVER add restatement to the gate. Instead, consolidate the reference to "Per §X.Y" + verify §X.Y is correct in the plan.
11. **Apply failure recovery** during the auto-apply phase (after bundle marked AUTO-APPLY ELIGIBLE), if one or more Edits fail (file moved between reviewer-time and apply-time, conflict, permission, line shifted):

    Work-preserving policy (any number of failures):
    - **Apply the ones that succeed** — commit normally as `round X/CN fix N: <summary> (partial — M of N obvious-fixes applied)` (commit A code) + commit B paper trail message `round X/CN fix N report: at HEAD <SHA-A> (partial: M of N applied, K reclassified to needs-decision)`. The commit B message must be self-describing — anyone reading `git log --oneline` understands immediately that it was partial without needing to open commit A.
    - **Reclassify the ones that failed** as `needs-decision` with note "Edit failure during auto-apply: <reason from harness>" recorded in the round report (commit B body).
    - **Stop and present revised bundle to user** with section "Failed to apply" listing the reclassified.
    - User decides: apply manually, defer, or skip.

    If ALL Edits fail (nothing applied), apply doc-only commit rule (consistent with §"Loop cap" §"What counts vs not"): **single commit** `round X/CN fix N: aborted — all N edits failed (paper trail only)` only in the round report file, without separate commit B. This commit is doc-only (touches only `docs/reviews/round-*report.md`) and **does not consume a cap-5 slot**. Escalate entire bundle to user.

    **Interrupt mid-apply:** if user interrupts (Ctrl-C) during auto-apply, agent inspects which Edits were applied (via `git diff` working tree) and reports state honestly — "applied X of N fixes, working tree dirty, no commit yet". User decides whether to commit partial, discard, or continue.

12. On PASS, append auto-review history + Decision Bundle to the round report, delete `.sdi-review-prompt-tmp.txt`, commit review artifacts, post the report, and propose the next round.
13. On FAIL (with reclassification or apply failure escalation), stop for user input.
14. After attempt 5 still FAIL, or convergence check triggered, stop for the user with full review history.

BASE_SHA stays fixed across all attempts in a round. Each retry packet includes prior findings and the fix commit(s) that claim to address them.

PASS does not mean "skip the round report" — the implementer still posts the report (with auto-review history attached). It means the user does not have to gate-check explicitly; they can let the next round start, or interject if they want to look closer.

## Decision Bundle format

After dedup + classification, the implementer presents a Decision Bundle:

```
## Auto-review Round X attempt N — Decision Bundle

**Verdict:** FAIL (6 findings after dedup; 3 convergent, 3 unique)

### Obvious fixes (auto-apply eligible)
1. [Class 3] `src/foo.ts:42` — method `validateUser` not found; reviewers propose `validateMember`. Convergence: Opus + Sonnet + Codex. → APPLY
2. [Class 4] `docs/round-report.md:18` — test count claim "12 tests" but runner output shows 14. → APPLY

### Needs decision
3. [Class 1] `src/auth.ts:120 vs src/auth.test.ts:55` — implementation uses cookie, test uses header. Divergent reviewers (Opus says "fix code", Codex says "fix test"). Need user input.

### Judgment-required (user judgment required — never auto-apply)
4. [Class 5] `src/billing.ts:88` — retry policy choice not in DECISIONS.md (verdict ESCALATE from Opus).
   - Option A: exponential backoff 250ms/500ms/1s (recommended — mirrors existing pattern in src/sync.ts:34)
   - Option B: linear retry 1s × 3
   - Need user input.
5. [Class 7, urgent] `src/sync.ts:200` — race condition in concurrent sync trigger may cause double-billing (verdict ESCALATE from Codex).

### Persistent findings (same class + file + symbol OR ±5 lines as prior attempts)
None this attempt.

**Action if auto-apply approved:** apply fixes 1+2 only (judgment-required + needs-decision remain for user input), commit `round X/CN fix N: <summary>` (code) + `round X/CN fix N report: at HEAD <SHA>` (paper trail), retry attempt N+1. **But: because there are judgment-required/needs-decision, this bundle is NOT AUTO-APPLY ELIGIBLE; agent stops and waits.**

**Bundle marked AUTO-APPLY ELIGIBLE only when:** zero judgment-required + zero needs-decision + ≥1 obvious-fix.
**Action if pause requested:** stop here.
```

**Commit B status during user-pause:** if bundle is all-`judgment-required` (zero obvious-fix), commit B (report referencing A's SHA) was already created in step 1 — stays as-is during the pause. Don't amend. Reviewer outputs are committed in the final `round X/CN review artifacts: <verdict>` commit when the loop closes (PASS, manual ESCALATE, or cap reached).

## Verdict merging (all attempts)

When multiple reviewers run on an attempt, merge verdicts mechanically:

| Reviewer verdicts | Merged |
|---|---|
| all PASS | **PASS** |
| one or more FAIL, no ESCALATE | FAIL |
| any ESCALATE | ESCALATE |

Rules in plain language:
- **PASS only when every reviewer that ran returns PASS.** Any FAIL or ESCALATE blocks PASS.
- **ESCALATE wins over FAIL.** If any reviewer escalates, the round escalates — the user must judge.
- **Findings unionize.** When the merged verdict is FAIL, dedup + classification (per §"The loop" step 7-8) operates on the union of findings from all reviewers on the attempt.

## Reviewer fallback

If a reviewer cannot be invoked or produces unusable output (binary missing, network down, timeout, malformed output, no parseable `VERDICT:` line):

| Situation | Action |
|---|---|
| At least one reviewer ok, at least one failed | Continue with the reviewer(s) that ran. Note each skip in the round report ("sonnet skipped: <reason>", "codex skipped: <reason>", or "opus subagent skipped: <reason>"). Mark the mode as `degraded` in the auto-review history, but do NOT downgrade surviving verdicts — if the surviving reviewers all returned PASS, treat as PASS. |
| All scheduled reviewers failed | **Escalate to the user.** Surface: "All scheduled reviewers failed: [reasons]. Auto-review unavailable for this round — please review manually, fix the reviewer setup, or specify a different schedule." |

If the user has not overridden the schedule, attempts 1-2 are Opus + Sonnet + Codex and attempts 3+ are Opus + Codex. If a scheduled reviewer is unavailable in this runtime, use the fallback table above; do not silently substitute a different model unless the user has requested it or the runtime documents an equivalent reviewer mode in the round report.

## Reviewer timeouts

Reviewer orchestration uses a wall-clock timeout so "still thinking" does not become an invisible stall.

- **Default soft timeout:** 20 minutes per reviewer.
- **Attempts 1-2:** start Opus, Sonnet, and Codex in parallel. If at least one reviewer returns usable output and another exceeds 20 minutes, treat the slow reviewer as timed out, continue with the surviving reviewer(s) via reviewer fallback, and record the timeout in the round report. If all three exceed 20 minutes without usable output, `ESCALATE`.
- **Attempts 3+:** start Opus and Codex in parallel. Apply the same timeout + fallback policy. If both exceed 20 minutes without usable output, `ESCALATE`.
- **Large-diff exception:** before launching review, the implementer may declare a longer timeout in the round report when the diff is unusually large. If a review is expected to need more than 45 minutes, split the round or escalate instead of silently waiting.

Use the host runtime's background-process/subagent timeout mechanism when available. If the runtime cannot enforce timeouts automatically, the implementer must record start time, check elapsed wall-clock time, and apply the policy manually.

## Building the review packet

Before invoking any reviewer, build a self-contained prompt by substituting placeholders into the template in §"Adversarial review prompt template" below. Substitute BEFORE writing the prompt to disk / passing to subagents — reviewers do not expand placeholders.

| Placeholder | Source |
|---|---|
| `[ROUND_ID]` | e.g., "Phase 2 — Round B — Checkpoint 2 Core" |
| `[STACK]` | one-line stack summary from `AGENTS.md` or `CLAUDE.md` (e.g., "Next.js 15 App Router + Drizzle + Postgres + Supabase Auth") |
| `[BASE_SHA]` | the SHA captured at the start of this round (recorded in the round report header) |
| `[ROUND_REPORT_PATH]` | path to the round report draft/final artifact, e.g. `docs/reviews/round-B-C2-report.md` |
| `[PLAN_PATH]` | path to the implementation plan, e.g. `docs/IMPLEMENTATION_PLAN_PHASE_2.md` |
| `[PLAN_SECTIONS]` | the §s relevant to this round, e.g. "§3, §6.1, §11" |
| `[PRIOR_REVIEW_FINDINGS]` | attempt 1+ findings that must be re-checked on retries; use "None — first attempt." for attempt 1 |

Packet checklist before invocation:
- No placeholder token remains in the final prompt.
- `[BASE_SHA]`, `[ROUND_REPORT_PATH]`, `[PLAN_PATH]`, `[PLAN_SECTIONS]`, and `[PRIOR_REVIEW_FINDINGS]` are filled with concrete values.
- `[ROUND_REPORT_PATH]` exists before review starts.
- The round report includes a `Testing` section with exact commands/checks, results, counts, skips, and manual smoke evidence where applicable.
- On retries, `[PRIOR_REVIEW_FINDINGS]` includes the union of earlier findings and the fix commit(s) that claim to address them.

Write/update the round report draft at `[ROUND_REPORT_PATH]` before invoking reviewers. Then write the substituted prompt to `.sdi-review-prompt-tmp.txt` at the repo root (used as stdin to codex; the same file content is passed as the `prompt` parameter to the Opus and Sonnet subagents when scheduled). Add this file to `.gitignore` if it isn't already (it is temporary and recreated per attempt). Delete after the round closes.

The same packet goes to every reviewer scheduled for that attempt — they see identical input. Outputs are captured per reviewer:
- Opus subagent: returned as the Agent tool's text result; the implementer writes it to `docs/reviews/round-XN-attempt-N-opus.md`.
- Sonnet subagent: returned as the Agent tool's text result; the implementer writes it to `docs/reviews/round-XN-attempt-N-sonnet.md` when Sonnet is scheduled.
- Codex: written directly via `--output-last-message docs/reviews/round-XN-attempt-N-codex.md`.

These output files ARE committed for audit trail after the auto-review loop closes, together with the final round report.

Do **not** include in the packet:
- Prior conversation context.
- Prior rounds' diffs (only this round, computed by each reviewer via `git diff [BASE_SHA]..HEAD`).
- Memory entries, DECISIONS log, or KNOWN_ISSUES log directly (each reviewer reads them itself by grepping the repo when needed; the packet stays focused on this round's diff and report).

Exception: retry packets MUST include prior auto-review findings in `[PRIOR_REVIEW_FINDINGS]` so retry reviewers verify fixes for all Opus, Sonnet, and Codex findings from earlier attempts.

## Adversarial review prompt template

The template below is the prompt sent to reviewers. Copy verbatim, then replace `[ROUND_ID]`, `[STACK]`, `[BASE_SHA]`, `[ROUND_REPORT_PATH]`, `[PLAN_PATH]`, `[PLAN_SECTIONS]`, and `[PRIOR_REVIEW_FINDINGS]`.

```
You are an adversarial code reviewer for round [ROUND_ID] of a [STACK] implementation.

Workdir: project root.
The implementation is committed at HEAD; the previous round (baseline) is at commit [BASE_SHA].
The implementer wrote a round report at [ROUND_REPORT_PATH] claiming what was built and what gates pass.
The plan section relevant to this round is [PLAN_PATH] §[PLAN_SECTIONS].
Prior review findings that MUST be verified this attempt: [PRIOR_REVIEW_FINDINGS]

Your job: find what is broken AND what the report misrepresents. Default to skepticism — the implementer wants to ship and may overstate; assume claims are overstated until evidence confirms them. Trust only what you can verify.

You may run targeted read-only-compatible checks when they materially improve confidence. You are not required to rerun the whole suite; you ARE required to judge whether the implementer's reported verification evidence is sufficient for the gates.

## Steps you must perform

1. Run `git diff [BASE_SHA]..HEAD` to see the full round diff.
2. Run `git status --short`. If uncommitted files outside `.sdi-review-prompt-tmp.txt` and this round's `docs/reviews/round-XN-*` artifacts are present, file a class-4 finding because the reviewed state is ambiguous.
3. Read [ROUND_REPORT_PATH] end to end.
4. Read [PLAN_PATH] sections [PLAN_SECTIONS] to know what this round was supposed to deliver.
5. Read `AGENTS.md` or `CLAUDE.md` for stack and conventions. If both exist, they should carry the same facts; note any drift as a finding.
6. Read `docs/KNOWN_ISSUES.md` if present. If the report/plan claims to fix or defer a `KI-NNN`, verify status/evidence alignment.
7. For each concrete claim in the round report, verify it against the diff and the actual file system. Use git/ls/cat/grep as needed.
8. Audit the report's Testing section: commands run, results, counts, skips, and manual smoke evidence. If the evidence is missing, vague, contradictory, or too weak for the gate, file a class-4 finding.
9. If prior review findings are listed, verify each one was actually fixed. Do not PASS a retry until every prior finding is either fixed or explicitly escalated.

## Things you MUST actively check (beyond standard code review)

A. Report-vs-reality for files. For each NEW or MODIFIED file in the round report, verify it exists in the diff. Fabricated file claims are bugs.
B. Report-vs-reality for tests. For each test/check claim, verify the named files or commands are plausible from the repo and that counts/results/skips are specific. No test file, no command, no count, or vague "passes" evidence = class-4 finding.
C. CSS class definitions. For every className referenced in JSX/TSX, verify the class is defined in styles/globals.css, a CSS module, tailwind.config.*, or is a built-in tailwind utility. Undefined classes are bugs.
D. API contracts. For every fetch/POST/PUT/PATCH in client code, locate the route handler and compare request body shape vs handler validation (Zod schema). Mismatches are bugs.
E. Optimistic UI patterns. For setState before await fetch, verify error branch reverts state. Logging only is a bug.
F. Plan-vs-implementation. For each gate marked ✓ in the report, locate the evidence in the diff. Missing evidence = flag.
G. Report wording precision. UI behavior phrasing in the report must match code exactly.
H. Stack-specific architecture and high-blast-radius risk. Adapt to [STACK]: in-memory state in serverless, sync APIs in RSC, missing root layouts, RLS bypass, race conditions, unhandled promise rejections. Also weight failure categories that are expensive, dangerous, or hard to detect: auth/tenant isolation and trust boundaries; data loss, duplication, or irreversible state changes; rollback safety, retries, partial failure, idempotency gaps; ordering assumptions and re-entrancy; empty-state, null, timeout, and degraded-dependency behavior; version skew, schema drift, migration hazards; observability gaps that hide failure or block recovery.
I. DECISIONS log. For non-obvious choices in the diff, grep DECISIONS.md for an entry. Unflagged choices ESCALATE.
J. KNOWN_ISSUES log. For pre-existing bugs, security gaps, tech debt, or deferred fixes outside round scope, check `docs/KNOWN_ISSUES.md`. If absent or missing the issue, file a class-7 finding with a proposed `KI-NNN` entry; urgent P0/P1 issues ESCALATE.
K. **Verify-before-claim audit.** For each concrete reference in the plan/report — method, class, hook, file:line, precedent ("mirrors pattern of X"), count ("N sites to change") — Grep/Read and confirm it exists in the shape claimed. Invented / fictitious citations are class-3 finding (missing prerequisite); shape mismatches are class-1 (internal inconsistency). Use Grep verbatim and cite output in the finding. Especially watch for assertions like "(already exists in code)" / "(method available)" / "(N sites)" without Grep evidence immediately before the assertion.

## Bug classes

1. Internal inconsistency — report claims X, code does Y; or two parts of the code disagree.
2. Contract mismatch — caller sends one shape, handler expects another.
3. Missing prerequisite — code or report references a file, component, helper, hook, env var, test, or convention that doesn't exist.
4. Vague or unverifiable claim — gate, test/check, or report claim that cannot be marked ✓/✗ from evidence.
5. DECISIONS-worthy choice without flag.
6. Convention or architecture mistake.
7. Anything else surprising or risky.
K. Verify-before-claim violation — plan/report cited a method/class/hook/file:line/precedent/count that doesn't exist in the codebase as claimed (semantically same role as class-3, but distinguishes "reviewer-discovered fictitious citation" from "code reference to nonexistent symbol").

## Calibration

Prefer one strong, defensible finding over several weak ones. Do not dilute class 1-4 findings with marginal class 7 noise. Speculative or cosmetic concerns: omit. Every reported finding should be worth a fix attempt — the loop is expensive.

## Output format

Findings-first. Do not summarize what works. Each finding:
- Class (1–7).
- Where (file:line).
- What is wrong (one sentence).
- Why it bites (one sentence).
- Suggested fix (one sentence).

End with TWO lines:
- TOTAL FINDINGS: N. By class: 1=a, 2=b, 3=c, 4=d, 5=e, 6=f, 7=g, K=k.
- VERDICT: PASS / FAIL / ESCALATE.

VERDICT rules:
- PASS = zero findings of class 1–6 or K.
- FAIL = at least one finding of class 1–4, 6, or K (mechanically fixable).
- ESCALATE = at least one finding of class 5, OR class 7 marked urgent, OR anything requiring user judgment.

**Output format hint:** wrap method/class/symbol references in backticks always (enables symbol-based convergence check in the auto-review loop).

Do NOT edit any files. Your response is the review report itself.
```

## Verdict format (what the implementer expects back)

Each reviewer returns its review as Markdown text. The implementer parses the last `VERDICT:` line of each:

- **PASS** — all gates verified ✓ with citations; no escalation triggers found.
- **FAIL** — one or more gates ✗, but the failures are fixable mechanically (e.g., contract mismatch, missing test for an edge case the plan listed, observability hook not wired, undefined CSS class).
- **ESCALATE** — one or more findings require user judgment (DECISIONS-worthy choice without flag, urgent class-7 finding, anything outside the implementer's scope).

If the verdict line is missing, malformed, or the output is empty/garbage, treat that reviewer as failed (see §"Reviewer fallback"). Do not reject a short but well-formed PASS response solely because it is brief.

After parsing, apply the merge rules above (PASS only if all reviewers PASS; ESCALATE wins over FAIL), then proceed per the loop.

## Loop cap

- **Maximum 5 review attempts per round** (attempts 1-2: Opus + Sonnet + Codex; attempts 3+: Opus + Codex), unless the user explicitly requests a different schedule. The cap exists as a **circuit breaker** to prevent infinite loops when the agent isn't converging, NOT as a sign of a structural problem. Rounds requiring 5+ attempts are common and legitimate (especially in code that touches multiple areas).

- **Convergence check (escalation before the cap):** if the last 2 attempts produced findings with **same class + same file + same symbol/identifier OR within ±5 lines of the previous finding**, the loop is stuck in lazy fix (code shifted but root cause remains). Literal file:line match would be too weak — code moves after fixes. Escalate immediately with message:
  > "Finding {class} in {file} ({symbol/identifier or line}) persisted in attempts N-1 and N despite fix attempt. Lazy fix or root cause misunderstood — requesting input."

  **Symbol extraction algorithm (deterministic, not NLP discretion):**
  1. **First-pass — backtick extraction:** look for tokens between backticks in the finding text (`` `validateUser` ``, `` `IntegrationApiService` ``). If 1+ symbols found between backticks, use them as the symbol set. Match attempt N-1 vs attempt N: non-empty intersection = persistent.
  2. **Second-pass — quoted identifier extraction:** if zero backticks, look for identifiers in quotes (`"validateUser"`, `'validateUser'`). Same match rule.
  3. **Third-pass — CamelCase / snake_case heuristic:** if zero backticks AND zero quotes, extract tokens matching `/\b[A-Z][a-z]+[A-Z][a-zA-Z0-9]*\b|\b[a-z][a-z0-9_]*_[a-z0-9_]+\b/` (true CamelCase with 2+ caps — e.g., `IntegrationApi`, `getUserByEmail`, `OmieMapper`; OR snake_case with underscore — e.g., `parse_omie_config`). **Single-cap words like `User`, `Save`, `Foo` do NOT match** — avoids false-positive from prose words like `The`, `When`, `Bar` captured as symbols. They fall into the fourth-pass line-range fallback. If multiple matches, use all as the set. **Defensive stopword blacklist** (filter even if matched): `{The, This, That, These, Those, When, Where, While, If, Then, Else, And, Or, But, Not, For, Within, Without, Should, Could, Would, May, Must, Shall, Will, Can}` — common prose words that may coincidentally match the regex if reviewer wrote a phrase like "TheRetryPolicy".
  4. **Fallback — line-range match:** if none of the above passes returned symbols, use ±5 lines of the center of the range cited by the reviewer (e.g., "line 42-58" → center 50, persistent if attempt N flags within [45-55]).

  **Cross-pass match semantics:** match = intersection of symbol sets between attempts N-1 and N, **independent of which pass extracted each side**. If attempt N-1 came from pass-1 (backticks) with `{validateUser}` and attempt N came from pass-3 (CamelCase) with `{validateUser}`, it's a match (non-empty intersection). If attempt N-1 came from pass-1 and attempt N fell into pass-4 (line range), direct comparison doesn't work — in that case use pass-4 on both sides (re-extract line-range from the attempt N-1 finding too) and match by ±5 lines. **Principle:** always compare sides in equivalent passes when possible; if not, line-range fallback.

  **Reviewer outputs preservation:** convergence check requires that reviewer outputs from attempt N-1 remain accessible in the working tree when the attempt N convergence check runs. The implementer **must NOT delete** `docs/reviews/round-XN-attempt-(N-1)-{opus,sonnet,codex}.md` between attempts. Cleanup only happens at loop close (PASS / ESCALATE / cap), together with the review artifacts commit. Per-attempt outputs stay uncommitted in the working tree during the loop; the preflight already permits these files as an allowed uncommitted exception.

- **Cap reached (attempt 5 still FAIL):** escalate with message:
  > "Auto-review hit 5 attempts. Loop did not converge — user should review remaining findings and decide to continue manually, open as a separate work item, or accept as KNOWN_ISSUES."

  Don't interpret cap-hit as "structural problem". It can be, but frequently it's just a slow process. Let the user diagnose.

- **What counts vs doesn't count against the cap-5:**
  - **Counts:** each fix attempt that (a) addresses at least 1 reviewer finding class 1-7 or K, OR (b) modifies production code in any file of the round's diff.
  - **Doesn't count:** doc-only commits that correct typos in the commit B paper trail (e.g., wrong SHA copy-paste, typo in report prose, missing markdown link). These commits have the format `round X/CN report fix: <typo>` (distinct from `round X/CN fix N report: ...` which is the report-pair of a real fix N). The audit trail keeps them separate; the cap counter ignores them.
  - **Heuristic:** if the commit touches only `docs/reviews/round-*report.md` AND zero code, it's doc-only and doesn't consume a slot. Otherwise it consumes.

## Auto-review history in round report

Every auto-reviewed round must include the auto-review history in its round report. See `round-report-template.md` for the exact section shape.

For each attempt:
- Attempt N — reviewers run (default: `opus + sonnet + codex` on attempts 1-2, `opus + codex` on attempts 3+ unless the user overrides the schedule or the runtime is in documented degraded mode) and merged verdict.
- Per reviewer: full structured output verbatim from `docs/reviews/round-XN-attempt-N-{reviewer}.md` (findings + verdict line).
- Decision Bundle (per §"Decision Bundle format"): obvious-fix / needs-decision / judgment-required classification, action taken.
- Runtime notes: degraded mode, timeout, or extended timeout declaration if applicable.
- Issues found (if any) and the fix applied between attempts (with the fix commit SHA — both fix N code + fix N report SHAs).

Do not summarize ("3 attempts, eventual PASS"). The user uses the history to spot-check the reviewers' calls — omitting it defeats the purpose of the audit trail.

## Invocation — Anthropic subagents (Agent tool)

When the host runtime supports it, the Opus and Sonnet subagents run via the Anthropic Agent tool. Use the `general-purpose` subagent type with explicit `model: "opus"` or `model: "sonnet"` so the subagent runs the scheduled model regardless of the parent session's model. If the host runtime has no Agent tool or no requested model selection, record "`<model>` subagent unavailable: <reason>" and apply reviewer fallback.

Inputs:
- `description`: short, e.g. `Round B/C2 attempt 1 review`.
- `subagent_type`: `general-purpose`.
- `model`: `opus` or `sonnet`, depending on the scheduled reviewer.
- `prompt`: the substituted contents of `.sdi-review-prompt-tmp.txt` (the entire adversarial review prompt with placeholders filled in).

The subagent inherits file/Bash tools so it can run `git diff`, read files, and grep the repo as the prompt instructs. The text response is the review report — write it to `docs/reviews/round-XN-attempt-N-{opus,sonnet}.md` for audit trail.

If the parent session is already running the same model, the subagent still runs as a separate process with no shared conversation context — that's the load-bearing piece (independent reasoning over the same inputs).

## Invocation — Codex CLI (codex exec)

**Default: invoke via the host runtime's Bash tool.** The command below is POSIX-shell syntax — the `<` redirection and line continuations only parse in Bash, not PowerShell. On Windows hosts where Bash is unavailable, fall back to PowerShell calling `cmd /c "<full command on one line>"` so cmd.exe handles the redirection. Do **not** use PowerShell's pipe (`Get-Content prompt.txt | codex exec ...`): on Windows PowerShell 5.1, the codex banner (which is normal stderr) gets wrapped in `NativeCommandError` records that look like exceptions even when codex exits 0. Do **not** use `< file` directly in PowerShell — it's a parser error (`Operador '<' reservado para uso futuro`).

**Validate success by `exit code == 0` AND `--output-last-message` file is non-empty.** Never by stderr. Codex writes its session banner to stderr by design; on Windows machines with PowerShell `ConstrainedLanguage` mode (corporate Group Policy), codex.exe's internal PowerShell calls can also throw `[Console]::OutputEncoding` errors to stderr. Both can coexist with a clean exit 0 and a valid review output file — the agent should not abort the run on stderr noise alone.

```
codex exec --ephemeral \
  --sandbox read-only \
  --output-last-message docs/reviews/round-XN-attempt-N-codex.md \
  -C [REPO_ROOT] \
  - < .sdi-review-prompt-tmp.txt
```

Notes:
- `--ephemeral` — codex doesn't persist this run as a session.
- `--sandbox read-only` — reviewer runs read-only; the CLI still writes the final message to `--output-last-message`. Do not switch to writable sandbox just to let Codex rerun cache-writing tests; the implementer should run those checks and report evidence before review.
- `--output-last-message <FILE>` — captures only the final agent message in the output file. Skips intermediate stdout noise.
- `-C [REPO_ROOT]` — sets codex's working directory.
- `- < <prompt-file>` — passes the prompt via stdin (cleaner than escaping inline arguments).

The run typically takes 3–10 minutes with xhigh reasoning on a meaningful round diff. Run as a background command (your tool's mechanism for long-running shell commands), record start time, and apply the 20-minute reviewer timeout above.

## Parallel orchestration

On each attempt, the implementer fires the scheduled reviewers in parallel and waits for them:

1. Write/update `docs/reviews/round-XN-report.md` as the report draft for this attempt, including the Testing evidence.
2. Run the clean-state preflight. Do not invoke reviewers if uncommitted non-artifact changes remain.
3. Write the substituted prompt to `.sdi-review-prompt-tmp.txt` with `[PRIOR_REVIEW_FINDINGS] = "None — first attempt."` on attempt 1, or the union of prior findings plus fix commit(s) on attempts 2+.
4. Run the packet checklist. Do not invoke reviewers if placeholders remain or required paths/sections are missing.
5. Spawn the scheduled subagents (Agent tool, `run_in_background: true`) and record start time.
6. Start `codex exec` as a background Bash command and record start time when Codex is scheduled.
7. Wait for scheduled reviewers to complete, applying the 20-minute timeout policy.
8. Read output files. Parse VERDICT from each usable reviewer output. Apply the merge rules or direct Opus verdict.
9. If any reviewer failed to produce usable output, apply §"Reviewer fallback".

Default schedule:
- Attempts 1-2: Opus subagent + Sonnet subagent + Codex.
- Attempts 3+: Opus subagent + Codex.

After the round closes (PASS or escalation), append final auto-review history to `docs/reviews/round-XN-report.md`, delete `.sdi-review-prompt-tmp.txt` (it's gitignored and recreated per attempt anyway), and commit the round report + per-attempt output files with `round X/CN review artifacts: <verdict>`. Do NOT delete the per-attempt output files in `docs/reviews/` — those are the audit trail.

## Common pitfalls

- **Vague gate criteria.** "Verify the integration tests pass" is not enough. The gate must say what counts as ✓ ("Integration test count matches plan §8 list and all pass per the runner output below"). Without that, even adversarial prompts will rubber-stamp.
- **Thin verification evidence.** "All tests pass" without exact command, result, count, and skips is not reviewable. The reviewer should FAIL vague evidence instead of assuming the checks happened.
- **Dirty workspace at review time.** If uncommitted non-artifact changes are present, `git diff BASE_SHA..HEAD` no longer describes the same state the reviewer sees on disk. Commit intended round changes first; escalate on unrelated/user-owned changes.
- **Forgetting to substitute placeholders.** Neither reviewer expands `[BASE_SHA]` or `[ROUND_REPORT_PATH]` — substitute them into the prompt template before writing to disk / passing to the subagent, or the run is wasted.
- **Waiting forever on a reviewer.** Apply the 20-minute timeout. A timed-out reviewer is unavailable for this attempt; the fallback/escalation policy exists so the loop stays mechanical.
- **Each reviewer is a fresh subprocess with no shared context.** Build the packet to be entirely self-contained. The parent session's conversation context is invisible to all reviewers.
- **If the diff is too large for either reviewer's context, the round was too big.** Modern models handle 100k+ tokens, but extremely large rounds may overflow. Split the round (one commit's worth of work each) and re-invoke per chunk.
- **Treating PASS as "skip the round report".** PASS still requires the report. The user reads the report to track progress; the auto-review history is an addendum, not a replacement.
- **Looping on cosmetic issues.** If attempt 2 fixed the substantive gate failure but attempt 3 fails on a tiny new issue, the loop cap is your friend — escalate (or use convergence check if same finding persists), don't loop forever.
- **Single-commit round = paper trail drift.** The split-commit convention exists for a reason: report committed inside the code commit causes references to HEAD/SHA to become placeholders that reviewers flag in a loop. Today: commit A (code) and commit B (report) always separated. If the impulse is "consolidate into one commit", resist — the overhead is trivial and the gain is cutting 1-2 attempts of drift per round.
- **`--amend` on the code commit.** Never use — the SHA changes and commit B (which references that SHA) becomes orphan. If something needs to change in the code commit, create a new `round X/CN fix N` commit and follow the pattern.
- **Ignoring escalation triggers.** An always-escalate trigger means stop, period. Don't try to pre-resolve it and skip to auto-review; the user must see it.
- **Skipping the pre-review checklist.** Walk the always-escalate triggers (see SKILL.md §Step 4.5) at the end of every round, before invoking reviewers. Catching a trigger after the reviewers fired wastes a review cycle and produces an ESCALATE the implementer should have surfaced themselves.
- **Treating ESCALATE as FAIL.** ESCALATE means user judgment is required — stop, surface the findings, wait. Do **not** apply fixes and retry on ESCALATE; that path is only for FAIL. The most common ESCALATE is a class-5 finding (DECISIONS-worthy choice without flag), and writing the DECISIONS entry silently before retrying defeats the purpose of escalation.
- **Aborting Codex on stderr noise.** Codex writes its session banner to stderr by design. PowerShell may wrap codex stderr in `NativeCommandError` records; corporate ConstrainedLanguage mode may add `[Console]::OutputEncoding` errors. None of those are failures — validate by exit code + `--output-last-message` file presence, not by inspecting stderr text. See §"Invocation — Codex CLI" for the invocation rules.
- **Letting reviewers edit code.** The review prompt instructs read-only. If a gate failure requires a fix, the implementer makes the fix between attempts.
- **Codex CLI assumptions.** The framework assumes `codex` is on PATH and the user has `~/.codex/config.toml` (or `$CODEX_HOME/config.toml`) selecting an appropriate reviewer model. The framework does not configure this. If `codex --version` fails, surface the gap to the user and apply §"Reviewer fallback" for any attempt where Codex was scheduled. For Windows-specific invocation rules (Bash default, PowerShell `cmd /c` fallback, exit-code-not-stderr validation), see §"Invocation — Codex CLI" above.
- **Anthropic subagent assumptions.** Full ensemble mode assumes the host runtime supports the Anthropic Agent tool with Opus and Sonnet model selection. On runtimes without that, the unavailable subagent(s) are skipped via reviewer fallback. If no scheduled reviewer can run, escalate or opt out of auto-review.
- **`codex review --base/--commit` parser quirk.** The CLI rejects custom `[PROMPT]` when `--base` or `--commit` is set. This protocol uses `codex exec` (not `codex review`) precisely to bypass that limitation. Do not switch to `codex review`.
- **Sequencing reviewers serially.** On attempts with multiple scheduled reviewers, run them in parallel, not one after the other. Serial execution multiplies wall-clock latency for no benefit. The runtime supports parallel Agent + Bash background invocations.

## When auto-review is wrong

Sometimes auto-review is the wrong default for a phase even though it's enabled by default:

- **High-uncertainty work.** New domain, new stack, exploratory architecture — keep user-gated. The cost of an auto-pass on a poorly-understood checkpoint exceeds the friction savings.
- **Shipping a release candidate.** Higher stakes; extra human review is worth the friction.
- **After a series of FAILs.** If multiple recent rounds in this phase needed retries, drop back to user-gated until the issue is understood.

The user can opt out at any point. The implementer should also propose dropping back to user-gated when it sees these patterns: "Three recent rounds needed retries — recommend opting out of auto-review for the rest of this phase. OK?"
