# Auto-Review Mode (default for Checkpoints 2/3/4/5)

Delegates checkpoint verification to a **reviewer ensemble** — different-model Opus, Sonnet, and Codex (if Codex is unavailable, **stop and ask the user**; there is no automatic substitute) — escalating only when something needs human judgment. **Default-on** for Checkpoints 2, 3 and 4 (per-round) and CP5 (comprehensive, phase-wide), all four running the **same fix loop**. CP1 stays user-gated. The user can opt out per session or ask for a different schedule.

> **Roles referenced in this file.** The **PM/orchestrator** is the main session: it runs the gate, dispatches reviewers, reconciles verdicts, assigns each finding's mark, and owns the paper trail; it never authors code. The **Engineer** is a dispatched Opus subagent that writes code and runs the build/tests, and never edits the paper trail; a code fix routes to a **fix-Engineer**, a paper-trail fix the PM applies. Roles, tool scoping and fan-out are in [`roles-and-orchestration.md`](roles-and-orchestration.md); this file is the reviewer machinery it reuses by reference.

## What this is

Implementation rounds end with structured verdicts from independent reviewers, deduplicated and classified into a **Decision Bundle** acted on **per finding**: obvious fixes are auto-applied and the next attempt fires automatically; decision findings are surfaced with options + a recommendation and pause for the user. An obvious fix is never blocked behind a coexisting decision finding.

- **Every attempt** runs **three reviewers in parallel**: an Opus subagent (Agent tool, `model: opus`), a Sonnet subagent (`model: sonnet`), and a Codex CLI process (`codex exec`, typically gpt-5.5 at reasoning effort `xhigh`). The full ensemble is load-bearing on every attempt, not just the first: different models find partially-disjoint bugs, and each retry re-reviews the fix commits, which are the freshest code in the round.
- **If Codex is unavailable on any attempt** (can't be invoked, times out, or returns unusable output), **STOP and ask the user — never substitute automatically.** See §"Reviewer fallback".

All reviewers of an attempt receive the **same self-contained prompt** (the template below); outputs are captured to `docs/reviews/round-XN-attempt-N-{opus,sonnet,codex}.md`. This is a gate, not a speed-up: it keeps the discipline binary and escalates what needs human judgment. It does not replace the user on an open decision, and it does not work without explicit per-gate criteria — a vague "review this" produces theatre.

## Per-round commit convention

Each round produces **at minimum 2 commits** (code + report); fix attempts add more pairs.

- **Start of round:** capture `BASE_SHA` = SHA of the **last `round X/CN review artifacts: <verdict>` commit** of the previous round — **not** "last commit of the previous round", which under this convention is a fix pair or a report. Record it in the report header. For **Round A** it is the **previous phase's last `review artifacts` commit** (the `mvp-bundle commit` for a project's first phase) — always a tagged endpoint, never a mid-stream commit; if the previous phase closed without review artifacts, the user makes a marker commit `phase N-1: closed (manual)` to serve as BASE_SHA, without which Round A diffs against mixed state and reviewers report pre-phase things as findings. **PHASE_BASE_SHA** is that Round A value, recorded literally and reused by the CP5 packet.

- **Commit A (code-only):** every code/test/migration edit of the round in ONE commit, no report — `round X/CN: <summary>`.
- **Commit B (report-only):** the report at `docs/reviews/round-XN-report.md` quoting A's real SHA — `round X/CN report: at HEAD <short-SHA-of-A>`.
- **Fix attempts:** same split — `round X/CN fix N: <what>` + `round X/CN fix N report: at HEAD <SHA>`. A doc-only fix is a single commit.
- **Loop close (PASS, ESCALATE, or cap):** `round X/CN review artifacts: <verdict>`, carrying the per-attempt outputs + final report.
- **No squashing.** Granular history IS the audit trail.

The split lets the report quote a SHA that already exists, which removes a whole class of "report claims SHA X but HEAD is Y" findings. BASE_SHA stays **fixed across all attempts of a round**, so each attempt re-evaluates the whole deliverable rather than the last fix delta — that is what stops fix N from reintroducing what fix N-1 fixed.

## Verification evidence policy

Auto-review audits the Engineer's verification evidence; it does not move test ownership to the reviewers.

- **The Engineer runs the checks the round requires** before review — tests, typecheck/lint/build, evals, or the manual smoke the plan and gates call for — and **the round report records exact evidence**: the generated block per `round-report-template.md` §"Testing", plus skips and smoke evidence. "Tests pass" with no command, result or count is not evidence.
- **The reviewer judges sufficiency.** It may run targeted checks its sandbox allows, but need not rerun the suite; evidence that is absent, vague, contradictory or too weak for the gate is a FAIL.
- **Codex stays read-only by default.** Checks that write caches, build output, snapshots or local DB state are the Engineer's.

A PASS means the evidence is adequate and nothing failed the attempt; it does not mean the reviewer reran every command.

## Preflight before invoking reviewers

Before building the packet, the PM performs a clean-state preflight:

1. Confirm `HEAD` contains **both** the round's commit A and commit B, or the current fix attempt's pair, and run `git status --short`.
2. The only allowed uncommitted files are `.sdi-review-prompt-tmp.txt` and prior attempts' reviewer outputs at `docs/reviews/round-XN-attempt-*-{opus,sonnet,codex}.md`, which stay in the tree so the convergence check can compare.
3. Intended round changes still uncommitted → commit them with the split pattern first.
4. Unrelated or user-owned changes present → **do not run auto-review**: escalate with the file list and ask whether to commit, stash, move to a separate worktree, or review manually.

Without this, reviewers compare `git diff BASE_SHA..HEAD` against a disk state holding unrelated changes and the audit is ambiguous. Do not create a review worktree by default; it is an advanced fallback.

## Disabling and re-enabling per session

**Auto-review is the default; every new session starts with it on.** The user opts out by saying any of "user-review for this phase", "review the next round myself", "stop auto-reviewing", "back to user-gated", "no auto-review"; and re-enables with "auto-review again" or an equivalent.

When opted out, the PM does **not** dispatch the ensemble: it runs the checkpoint **user-gated** for the rest of the session, posting the report and the diff and waiting for an explicit "go". Only the gate changes — the Engineer-dispatch and paper-trail roles are unchanged, and there is no single-agent fallback model. **Persistence: none**; record the opt-out as a breadcrumb in today's `docs/memory/YYYY-MM-DD.md`.

## When auto-review applies

| Checkpoint | Eligibility |
|---|---|
| 1 — Foundation | **User-gated always.** Audit findings routinely trigger always-escalate, so auto-review here would be a near no-op. The user gates the audit directly. |
| 2 — Core domain logic | **Auto-review default-on.** |
| 3 — Wire up integrations | **Auto-review default-on.** |
| 4 — UI | **Auto-review default-on.** |
| 5 — Housekeeping | **Auto-review default-on (comprehensive).** Same fix loop; see §"CP5 comprehensive review" for what differs. |

Even in a default-on checkpoint, the round escalates immediately when an always-escalate trigger fires.

## CP5 comprehensive review

CP5 differs from CPs 2-4 in **scope**, not in loop mechanics: reviewers read the **entire phase** (`git diff PHASE_BASE_SHA..HEAD`), and find cross-checkpoint regressions, acceptance criteria without evidence, scope drift, or accumulated known-issue debt — what a per-round review cannot see. **Schedule and fix loop are identical** (§"The loop", §"Loop cap"). Structural findings — rewind a previous CP, accept as a known issue, an AC gap — classify `needs-decision`/`judgment-required` and are presented, **never** auto-patched, so the loop cannot paper over a structural problem.

**Everything CP5 delivers is the paper trail**, so the `[docs]`-is-`[code]` promotion of §"Marks and the verdict matrix" covers all of it: a documentation finding at CP5 blocks, and the backlog deferred by CPs 2-4 is what CP5 exists to consume.

**On PASS — clear the review gate, not the PR.** CP5 closure still requires the **user-run CP-final smoke** (the PM generates the steps, the user runs them, the PM interprets). Never auto-open a PR or merge: the PM opens it via `gh pr create` only after **both** the review PASSes **and** the smoke passes.

**Packet structure — per-checkpoint split is the DEFAULT**, because a real phase easily exceeds what one packet can carry. Per CP delivered: its diff (`git diff CP_N-1_SHA..CP_N_SHA`), its round reports, and the DECISIONS/KI entries written during it; reviewers produce one finding-set per CP plus a cross-CP aggregation. A **whole-phase packet** is the exception, for a phase small enough to fit. The PM declares the mode in the report (`packet_mode: per-cp-split` or `whole-phase`). The packet is fixed across CP5 attempts; fix pairs are `round Z/CP5 fix N: …`, and each retry re-reviews the full phase diff including them.

## Always-escalate triggers (override auto-review default)

If any of these occur during the round, the PM skips auto-review for that round and stops for the user:

1. **Blocker** that prevents finishing the round — a dependency the user must install, contradictory plan content, a broken external service.
2. **Emergency deviation** per `stop-and-review-patterns.md` — security bug, data-loss risk, regression of working functionality.
3. **Schema migration with data-loss risk** (drop column, NOT NULL without backfill, lossy type change). Green tests do not substitute for the user's approval.
4. **New external dependency** beyond what the plan listed.
5. **Security-relevant change beyond plan scope** — auth helper, isolation policy, secret handling, CORS or CSP.
6. **Plan revision (`rN`) added during the round**: reality diverged from the plan, and the user sees what changed before the next round.
7. **PRD or ARCHITECTURE deviation** required to deliver the round (see `expected-artifacts.md` precedence).

Surface the trigger explicitly: "Auto-review skipped because [trigger]. Stopping for your review." Do not confuse this with `judgment-required`: **always-escalate is pre-review** and the reviewers never run, while **judgment-required is a post-review classification** in the Decision Bundle. Both stop for the user, at different points of the flow.

**Writing a `DECISIONS.md` or `KNOWN_ISSUES.md` entry no longer stops the round.** Those were triggers 1 and 2; the record they guaranteed is now the report's `## Decisões desta rodada`, written **in** the round and repeated in the stop message at every user-gated point — mandatory to write, optional to read. What still stops the round at any moment is a **choice of product, design or architecture that is still open**: class 5, ESCALATE by the matrix, and not the PM's to take.

## The loop

1. The Engineer(s) finish the round and commit **commit A**; the PM writes **commit B**. If an always-escalate trigger fired, or the user opted out, stop for the user.
2. Run the clean-state preflight and build `.sdi-review-prompt-tmp.txt`.
3. Run the attempt's three reviewers in parallel: **Opus + Sonnet + Codex**. If Codex is unavailable, **stop and ask the user** first — §"Reviewer fallback". Same on every attempt.
4. Apply the timeout/fallback policy; if no scheduled reviewer produced usable output, stop for the user.
5. Parse and merge verdicts (§"Verdict merging"), then decide the attempt by §"Marks and the verdict matrix".
6. **Dedup pass:** deduplicate by **same class + same file + same symbol/identifier, or within a few lines** — two reviewers flagging `validateUser` at lines 42 and 48 of one file are one convergent finding. Prioritize 3-way over 2-way over unique. The `obvious-fix` criterion "2+ reviewers converge" reuses this matcher: divergent line numbers for one logical bug DO converge; divergent symbols or files do not.
7. **Classify each deduplicated finding** as `obvious-fix`, `needs-decision`, or `judgment-required`:
   - `obvious-fix` = **a finding that fails the attempt and has a mechanical fix.** All of: it fails the attempt per §"Marks and the verdict matrix"; a convergence condition holds (2+ reviewers converge, **or** a surviving single reviewer in degraded mode, **or** a **solo grounded finding the PM cannot grep-refute** — the strict-solo gate below); the reviewer cites a specific fix, not "consider refactoring"; and the fix touches only files in `git diff BASE_SHA..HEAD --name-only`.
   - `needs-decision` = the rest: genuinely divergent reviewers (they disagree on the *fix*, not on line numbers, which dedup already treats as convergence); a fix reaching outside the round; a reviewer that describes a problem without proposing a fix.
   - `judgment-required` = verdict ESCALATE, class 5, or urgent class 7. Always presented, **never** auto-applied regardless of convergence — which is why the strict-solo gate never reaches class 5.
   - **Zero findings after dedup but verdict still FAIL** (vague concerns, no actionable detail): create one synthetic class-5 finding marked `judgment-required`, quoting the reviewer verbatim, and stop for input. Never PASS — "the reviewer could not propose a fix" is user-judgment territory by definition.
   - **Strict-solo policy note (the canonical encoding of this gate):** a solo **grounded** finding that fails the attempt and that the PM cannot refute with its own grep is a **blocker routed to a fix**, not deferred to the user — model diversity is load-bearing, and in production a lone model-diverse reviewer caught a cross-tenant coupling bug the other two PASSed. *Grounded* = cites specific evidence in the diff (file:line / symbol); the PM's refutation or confirmation goes in the round report. *Exclusions:* a solo class-5 stays `judgment-required`, and genuinely divergent reviewers stay `needs-decision`.
8. **Present the Decision Bundle, then act per finding.** The bundle is always posted for the audit trail; the action is per-finding, not all-or-nothing.
   - **Act on every `obvious-fix` now**, even when the bundle holds decision findings. A **paper-trail artifact** (plan, `docs/reviews/`, DECISIONS, KNOWN_ISSUES, memory) → the **PM applies it directly**; **code** → the PM **dispatches a fix-Engineer (Opus)**, never editing code itself. Commit as `round X/CN fix N: <what>` + `round X/CN fix N report: at HEAD <SHA>`. The fix is re-verified by the **next** attempt, not by an inline grep.
   - **Then branch on what remains:** nothing left → **fire the next attempt automatically**. Anything `needs-decision` or `judgment-required` left → **stop and present those** with options + a recommendation each, through the host's structured ask tool (`AskUserQuestion` under Claude Code), not plain prose. The obvious fixes are already committed, so they don't wait behind the decision.
9. **Re-verify before any fix lands.** The PM greps or reads to confirm the reviewer's claim before its own edit, and before dispatching a fix-Engineer (for a solo finding this pre-dispatch grep *is* the strict-solo check); the fix-Engineer verifies again before editing. If grep contradicts the reviewer, reclassify `needs-decision` — don't apply, don't dispatch. **Anti-restatement:** for a "gate restates spec" finding, never add restatement to the gate; consolidate to "Per §X.Y" and verify §X.Y is right.
10. **Failure recovery during the apply phase**, when an edit fails to land (file moved, conflict, permission, line shifted). Work-preserving: **apply the ones that succeed** (`round X/CN fix N: <summary> (partial — M of N applied)`, with a self-describing commit B message), **reclassify the failed ones** `needs-decision` with the reason recorded, and **stop with the revised bundle** under a "Failed to apply" section for the user to apply manually, defer, or skip. If **all** fail, write one doc-only commit `round X/CN fix N: aborted — all N edits failed (paper trail only)`, which **does not consume an attempt**, and escalate the bundle. On a user interrupt mid-apply, report state honestly — "applied X of N, working tree dirty, no commit yet".
11. On PASS, append the history and Decision Bundle to the report, delete `.sdi-review-prompt-tmp.txt`, commit the review artifacts, post, and propose the next round. **At CP5 a PASS clears only the review gate**: post and stop, do not open a PR. On FAIL after reclassification or an apply failure, stop for user input.
12. On the cap without a PASS, or when the convergence check triggers, stop for the user with the full review history; the next attempt needs the user's authorization and its DECISIONS entry (§"Loop cap").

PASS does not mean "skip the round report" — the PM still posts it. It means the user does not have to gate-check explicitly; they can let the next round start, or interject.

## Decision Bundle format

After dedup + classification the PM posts a bundle with these five parts, one line per finding, carrying its mark, class, location, convergence and action:

```
## Auto-review Round X attempt N — Decision Bundle
**Verdict:** FAIL (6 findings after dedup; 3 convergent, 3 unique)
### Obvious fixes (auto-apply eligible)      → each with mark, class, file:line, proposed fix, which reviewers converged, and APPLY
### Needs decision                            → each with why it is not obvious (divergent reviewers / outside round / no concrete fix)
### Judgment-required (never auto-apply)      → each with options + a recommendation
### Persistent findings (convergence check)   → any finding matching a prior attempt, or "None this attempt"
**Action:** which fixes were applied and by whom (PM for paper trail, fix-Engineer for code), and whether the loop CONTINUED (next attempt fired automatically) or PAUSED-FOR-USER.
```

**All obvious-fix**: apply everything and fire the next attempt, no user wait. **All decision**: present and stop. **Commit B during a user-pause** stays as written — don't amend; reviewer outputs are committed at loop close.

## Verdict merging (all attempts)

| Reviewer verdicts | Merged |
|---|---|
| all PASS | **PASS** |
| one or more FAIL, no ESCALATE | FAIL |
| any ESCALATE | ESCALATE |

- **PASS only when every reviewer that ran returned PASS**; any FAIL or ESCALATE blocks it, and **ESCALATE wins over FAIL** because the user must judge.
- **Findings unionize.** Dedup + classification (steps 6-7) operate on the union across reviewers.

This table merges what the **reviewers returned**. The verdict of the **attempt** then comes from §"Marks and the verdict matrix" and from nothing else: class alone does not decide, the mark does, and the PM assigns it.

## Reviewer fallback

| Situation | Action |
|---|---|
| **Codex failed** (any attempt — can't invoke, timeout, unusable output) | **STOP and ask the user. Never substitute automatically.** Surface the reason (usually a rate limit) and offer: **(a)** authorize a **Haiku** subagent as the third reviewer *for this occasion*, **(b)** proceed with **two** reviewers in documented degraded mode, or **(c)** pause and retry Codex later. Record the choice in the round report ("codex skipped: <reason>; user chose <a/b/c>"). An authorized Haiku runs the same packet and merges exactly as Codex would, noted as "haiku substituted **with user authorization**". |
| Opus or Sonnet failed, at least one ok | Continue with those that ran; note each skip and mark the mode `degraded`. Do **not** downgrade surviving verdicts. |
| All scheduled reviewers failed (including any authorized substitute) | **Escalate:** "All scheduled reviewers failed: [reasons]. Review manually, fix the reviewer setup, or specify a different schedule." |

**There is NO sanctioned automatic model swap.** A substitute reviewer is a spending decision and it belongs to the user, so a Codex failure must be *told*, and the authorization is **per occasion** — it does not carry to the next attempt, round, or work item unless the user says so.

## Reviewer timeouts

- **Default soft timeout: 20 minutes per reviewer.** Start all three in parallel and record start time.
- A **Codex** timeout is a Codex failure → §"Reviewer fallback", which means asking the user, not swapping a model in. Another reviewer over the limit while at least one returned usable output is treated as timed out and recorded; all three over it without usable output is `ESCALATE`.
- **Large-diff exception:** the PM may declare a longer timeout in the report before launching. A review expected to need over 45 minutes means the round should be split or escalated.

Use the runtime's background-process timeout where available; otherwise track wall-clock time and apply the policy by hand.

## Building the review packet

Substitute the placeholders **before** writing the prompt to disk or passing it to a subagent — reviewers do not expand them. `[ROUND_ID]` (e.g. "Phase 2 — Round B — Checkpoint 2 Core"), `[STACK]` (one-line summary from `AGENTS.md` / `CLAUDE.md`), `[BASE_SHA]` (from the report header), `[ROUND_REPORT_PATH]`, `[PLAN_PATH]`, `[PLAN_SECTIONS]` (the §s this round delivers), and `[PRIOR_REVIEW_FINDINGS]` ("None — first attempt." on attempt 1).

Checklist before invocation: no placeholder survives; every value is concrete; `[ROUND_REPORT_PATH]` exists and carries its `Testing` block; on a retry `[PRIOR_REVIEW_FINDINGS]` holds the **union** of earlier findings plus the fix commits claiming to address them.

Write the report draft first, then the substituted prompt to `.sdi-review-prompt-tmp.txt` at the repo root — stdin for codex, the `prompt` argument for the subagents. Gitignore it; it is recreated per attempt and deleted at loop close.

The same packet goes to every reviewer of the attempt. Opus and Sonnet return text the PM writes to `docs/reviews/round-XN-attempt-N-{opus,sonnet}.md`; Codex writes its own via `--output-last-message`. These files ARE committed at loop close. **A reviewer edits no file of the repository under review; writing its own report into `docs/reviews/` is not editing** — which is why a read-only Codex sandbox and `--output-last-message` are compatible.

Keep out of the packet: prior conversation context, prior rounds' diffs, and the memory/DECISIONS/KNOWN_ISSUES files — each reviewer greps for what it needs, and the packet stays on this round's diff and report.

## Adversarial review prompt template

The template below is the prompt sent to reviewers for a **round/diff** target. Copy verbatim, then replace the seven placeholders. (For a **plan or standalone** target, fill `sdi-review/references/adversarial-review-prompt-template.md` instead.)

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

**Mark every finding `[code]`, `[gate]` or `[docs]`. Your mark is a proposal — the coordinator assigns the final one.**

- `[code]` — the fix touches production code; **or** the description reveals a defect in the thing described, which you decide by measuring the code, not by where the finding points; **or** the text you are reviewing **is the deliverable** of this checkpoint.
- `[gate]` — the fix touches only a test, gate, lint, CI config, or fixture.
- `[docs]` — the fix touches only documentation that **describes** code: a round report, a memory entry, a comment, an already-executed plan section.

Two promotions apply before the mark is final: a `[gate]` finding on a gate **cited by an acceptance criterion** is `[code]` (only a gate no acceptance criterion cites has budget); and `[docs]` is `[code]` **when the text is the deliverable** — a plan review, a checkpoint whose deliverable is documentation, and everything a housekeeping checkpoint delivers, that checkpoint's deliverable being the paper trail itself.

Two traps. **Prose that a live gate parses** is not `[docs]` — some repos have tests that walk the tree and parse comments, so editing that prose can turn a test red. **A choice that is still open** is class 5, not paperwork: a missing decision entry is `[docs]` only when the choice was already made and merely isn't written down.

| Mark / class | Effect on the attempt |
|---|---|
| `[code]` of class 1–4, 6, or K | **fails** the attempt |
| `[gate]` not promoted | fails **one** attempt per round; on the next, a remaining or new one becomes a known-issue entry with a trigger and does not fail |
| `[docs]` not promoted, and non-urgent class 7 of any mark | never fails; goes to the report's paper-trail backlog and is paid at the housekeeping checkpoint |
| class 5 | **ESCALATE**, beats everything |
| class 7 marked urgent | **BLOCK** |

Report the `[docs]` ones anyway — they are collected, not discarded — but spend your budget on the thing being built.

**Output format hint:** wrap method/class/symbol references in backticks always (enables symbol-based convergence check in the auto-review loop).

Do NOT edit any files. Your response is the review report itself.
```

## Verdict format (what the PM expects back)

Each reviewer returns Markdown text; the PM parses the last `VERDICT:` line. **PASS** — no finding of class 1-6 or K. **FAIL** — a mechanically fixable finding. **ESCALATE** — something needs user judgment.

If the verdict line is missing, malformed, or the output is empty or garbage, treat that reviewer as failed (§"Reviewer fallback"). Do not reject a short but well-formed PASS just for being brief. After parsing, apply the merge rules, then decide the attempt by §"Marks and the verdict matrix", then proceed per the loop.

## Marks and the verdict matrix

This is the single place the framework decides what a finding does to an attempt; convergence, plan review, and CP5 cite it, and nothing restates it. **The PM assigns the mark**, during classification, with the reviewer's evidence as input — the reviewer proposes, so it can never buy a PASS by labelling its own finding. The block between the markers is **copied verbatim** into the two reviewer prompt templates (the one embedded in this file and `sdi-review/references/adversarial-review-prompt-template.md`), because a dispatched reviewer cannot read this file.

<!-- marks-inline:start -->
**Mark every finding `[code]`, `[gate]` or `[docs]`. Your mark is a proposal — the coordinator assigns the final one.**

- `[code]` — the fix touches production code; **or** the description reveals a defect in the thing described, which you decide by measuring the code, not by where the finding points; **or** the text you are reviewing **is the deliverable** of this checkpoint.
- `[gate]` — the fix touches only a test, gate, lint, CI config, or fixture.
- `[docs]` — the fix touches only documentation that **describes** code: a round report, a memory entry, a comment, an already-executed plan section.

Two promotions apply before the mark is final: a `[gate]` finding on a gate **cited by an acceptance criterion** is `[code]` (only a gate no acceptance criterion cites has budget); and `[docs]` is `[code]` **when the text is the deliverable** — a plan review, a checkpoint whose deliverable is documentation, and everything a housekeeping checkpoint delivers, that checkpoint's deliverable being the paper trail itself.

Two traps. **Prose that a live gate parses** is not `[docs]` — some repos have tests that walk the tree and parse comments, so editing that prose can turn a test red. **A choice that is still open** is class 5, not paperwork: a missing decision entry is `[docs]` only when the choice was already made and merely isn't written down.

| Mark / class | Effect on the attempt |
|---|---|
| `[code]` of class 1–4, 6, or K | **fails** the attempt |
| `[gate]` not promoted | fails **one** attempt per round; on the next, a remaining or new one becomes a known-issue entry with a trigger and does not fail |
| `[docs]` not promoted, and non-urgent class 7 of any mark | never fails; goes to the report's paper-trail backlog and is paid at the housekeeping checkpoint |
| class 5 | **ESCALATE**, beats everything |
| class 7 marked urgent | **BLOCK** |

Report the `[docs]` ones anyway — they are collected, not discarded — but spend your budget on the thing being built.
<!-- marks-inline:end -->

**Reach axis.** A `[code]` finding fails the attempt only when the PM **measures** that it has reach: an occurrence in the corpus today, in the real execution of the checkpoint, or on the CI path. A finding reachable only by an edit outside the canonical form — the form the project's entry templates and doc lint keep from being written — becomes a known-issue entry with a trigger and does not fail. The measurement is a row of the consolidation table, and **without it the finding counts as having real reach.** Without this axis the surface of constructible anomalies is unbounded and the attempt series does not converge.

**Convergence.** An attempt with no finding that fails is a PASS. Comparing symbols between attempts is a **secondary** criterion, used to spot a repeated finding — not the verdict algorithm.

**The matrix changes when paperwork is paid, not whether.** A backlog that never reaches CP5 is a regression of the rule, not a saving: carry it forward in the round report at every attempt.

## Loop cap

- **Maximum 3 review attempts per round, and 3 rounds of plan review.** This section is the only place in the framework that states the number; every other file cites it instead of repeating it. Every attempt runs the full ensemble (Opus + Sonnet + Codex; if Codex is unavailable, ask the user rather than substituting), unless the user explicitly requests a different schedule. The cap and the convergence check apply at CP5 too.

- **Mechanical stop.** On attempt 3 without a PASS — or on round 3 of a plan review without a SHIP — the PM **stops and hands the work back to the user**. Only the user authorizes the next attempt, and the `DECISIONS.md` entry recording that authorization and its reason is written **before** it. The agent does not continue on its own; that is what makes the stop mechanical.

- **Cap reached (last attempt still without PASS):** stop with message:
  > "Auto-review hit the attempt cap without a PASS. Handing this back: review the remaining findings and tell me whether to authorize another attempt (I will write the DECISIONS entry first), continue the fixes manually, open a separate work item, or accept the remainder as KNOWN_ISSUES entries."

- **Convergence check (escalation before the cap).** If the last 2 attempts produced findings with the **same class in the same file on the same symbol, or a few lines apart**, the loop is stuck in lazy fix — the code moved, the root cause did not. Escalate: "Finding {class} in {file} ({symbol or line}) persisted in attempts N-1 and N despite a fix. Lazy fix or root cause misunderstood — requesting input." Match on symbols the reviewer put in backticks or quotes, falling back to the line range it cited, comparing both sides the same way. This is a **secondary** criterion for spotting a repeated finding, deliberately not an algorithm: the verdict comes from the mark matrix. For it to run at all, the PM must **not** delete `docs/reviews/round-XN-attempt-(N-1)-*.md` mid-loop — cleanup happens at loop close, and the preflight already allows those files uncommitted.

- **What counts against the cap:** a fix attempt that addresses at least one reviewer finding, or that modifies production code in the round's diff. **What doesn't:** a doc-only commit correcting a typo in the commit B paper trail — wrong SHA, prose typo, broken link — committed as `round X/CN report fix: <typo>`, distinct from `round X/CN fix N report: …`, which is the report half of a real fix. Heuristic: touches only `docs/reviews/round-*report.md` and zero code → no slot consumed.

## Auto-review history in round report

Every auto-reviewed round records the history **by link** — one row per reviewer per attempt (verdict, totals by mark, path to that reviewer's committed file at `docs/reviews/round-XN-attempt-N-{reviewer}.md`), never the reports pasted inline. Under the table go the merged verdict and the mark that decided it, the reach measurement for every `[code]` finding that failed, the Decision Bundle action, the fix commit SHAs, and any runtime note (degraded mode, timeout, a recorded Codex→Haiku authorization, a convergence trigger, a user authorization past the cap).

The report also carries `## Decisões desta rodada`: one line per `DECISIONS.md` / `KNOWN_ISSUES.md` entry written in the round, or "Nenhuma". Exact shapes: `round-report-template.md`.

## Invocation — Anthropic subagents (Agent tool)

Opus and Sonnet — and Haiku **only if the user authorized it as the Codex substitute** — run via the Agent tool with `subagent_type: general-purpose` and an explicit `model`, so the subagent runs the scheduled model whatever the parent session's is. `description` is short (`Round B/C2 attempt 1 review`); `prompt` is the entire substituted contents of `.sdi-review-prompt-tmp.txt`. The subagent inherits file/Bash tools so it can `git diff`, read and grep; its text response is the review, which the PM writes to the attempt file.

If the runtime has no Agent tool or cannot select the model, record "`<model>` subagent unavailable: <reason>" and apply reviewer fallback. A subagent on the parent's own model still runs as a separate process with no shared context — that independence is the load-bearing part.

## Invocation — Codex CLI (codex exec)

**Two-step invocation — do not skip step 1.** With the prompt as a positional argument and stdin not a TTY (which it never is under a Bash tool, CI, or a background wrapper), codex appends stdin to the prompt and **hangs forever** on an EOF that never comes: process spawns, 0 bytes out, 0 session files. Redirecting the prompt from a file avoids it, because the file closes on EOF.

### Step 1 — write the substituted prompt to a file

```
cat > .sdi-review-prompt-tmp.txt <<'PROMPT_EOF'
<the full substituted adversarial review prompt — all placeholders replaced>
PROMPT_EOF
```

The heredoc delimiter MUST be quoted (`'PROMPT_EOF'`) so bash does not expand `$variables`, backticks, or `[BASE_SHA]`-style placeholders inside the prompt.

### Step 2 — invoke codex with stdin redirected from the file

```
codex exec --ephemeral \
  --sandbox read-only \
  --output-last-message docs/reviews/round-XN-attempt-N-codex.md \
  -C [REPO_ROOT] \
  - < .sdi-review-prompt-tmp.txt
```

- `--ephemeral` — the run is not persisted as a session. `-C [REPO_ROOT]` — sets the working directory explicitly, instead of `cd … && codex exec …`.
- `--sandbox read-only` — do not switch to a writable sandbox so Codex can rerun cache-writing tests; those are the Engineer's, evidenced in the report.
- `--output-last-message <FILE>` — captures only the final message, and **its parent dir must exist**: codex exits 0 even when the write fails, so `mkdir -p docs/reviews` before the round's first attempt or the output is silently absent.
- `- < <prompt-file>` — **the load-bearing piece.** Never replace it with a positional prompt.

**Validate success by `exit code == 0` AND a non-empty `--output-last-message` file. Never by stderr** — codex writes its session banner there by design, and on Windows PowerShell may wrap it in `NativeCommandError` records, or ConstrainedLanguage mode may add `[Console]::OutputEncoding` errors; all of those coexist with a clean exit 0 and a valid review.

**Shell notes.** The command is POSIX-shell syntax; on Windows without Bash, call `cmd /c "<command on one line>"` so cmd.exe handles the redirection — PowerShell's pipe and its `< file` both fail here. Do not switch to `codex review`: it rejects a custom prompt when `--base`/`--commit` is set, which is why this protocol uses `codex exec`.

A run typically takes 3-10 minutes at `xhigh`. Run it in the background, record start time, apply the 20-minute timeout.

## Parallel orchestration

On each attempt the PM fires the scheduled reviewers **in parallel** — serial execution multiplies wall-clock latency for no benefit. Order: report draft (with the Testing evidence) → clean-state preflight → `mkdir -p docs/reviews` → substituted prompt into `.sdi-review-prompt-tmp.txt` → packet checklist → subagents spawned in the background with start time recorded → `codex exec … - < .sdi-review-prompt-tmp.txt` in the background → wait under the timeout policy, parse each VERDICT, merge, and apply reviewer fallback for any that failed. **If Codex is unavailable or fails, STOP and ask the user** before spawning anything in its place.

After the round closes, append the final history, delete `.sdi-review-prompt-tmp.txt`, and commit the report plus the per-attempt files as `round X/CN review artifacts: <verdict>`. Do **not** delete the per-attempt files — they are the audit trail.

## Common pitfalls

- **Vague gate criteria.** "Verify the integration tests pass" is not a gate; say what counts as ✓, or even an adversarial prompt rubber-stamps.
- **Thin verification evidence.** Without the generated block, the exact command and the skips, FAIL the evidence rather than assume the checks happened.
- **Dirty workspace at review time**, which makes `git diff BASE_SHA..HEAD` stop describing what the reviewer sees on disk.
- **Forgetting to substitute placeholders**, which wastes the whole attempt — no reviewer expands `[BASE_SHA]`.
- **Waiting forever on a reviewer** instead of applying the timeout.
- **Assuming shared context.** Each reviewer is a fresh process and the packet must be self-contained; a diff too large for its context means the round was too big.
- **Treating PASS as "skip the round report".**
- **`--amend` on the code commit**, which orphans commit B — make a new `fix N` commit. Same reason not to consolidate A and B.
- **Ignoring an escalation trigger, or pre-resolving one to reach auto-review.** Walk the pre-review checklist *before* invoking reviewers.
- **Treating ESCALATE as FAIL** — above all, writing the DECISIONS entry silently before retrying, which defeats the escalation.
- **Aborting Codex on stderr noise** instead of validating by exit code and output file.
- **Letting reviewers edit the code they review.**
- **Assuming the Codex or Agent-tool setup exists.** The framework configures neither; a missing piece goes through reviewer fallback.

## When auto-review is wrong

Keep a checkpoint user-gated for **high-uncertainty work** (new domain or stack, exploratory architecture — an auto-pass on a poorly-understood checkpoint costs more than the friction saved), for a **release candidate**, and **after a series of FAILs** in the phase. The PM should propose it when it sees the pattern: "Three recent rounds needed retries — recommend user-gating the rest of this phase. OK?"
