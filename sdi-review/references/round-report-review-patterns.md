# Round report review patterns

Patterns for `sdi-review` Modes 2, 3, 4 (round report review, fork decision, bug found). The agent loaded with `sdi-review` runs these reviews itself.

> **For review of an implementation plan document, use `plan-review-protocol.md` — same agent, different framework (deeper artifact reading, plan-specific checks).**

## Round X review

Round report on your desk. Check:

- **Does the delivery match the scope the round was supposed to cover?** Sometimes agents over-deliver (scope creep) or under-deliver (silently deferred work). Both are worth flagging.
- **Are the decisions in the report defensible?** Go through each one. "Chose X because Y" — is Y accurate? Is X the right choice given Y?
- **Did the agent catch risks that the implementation introduces?** If the round added a new external dependency, did it discuss security/failure modes? If it introduced a feature flag, did it say when to flip it?
- **Did the agent update KNOWN_ISSUES when needed?** New out-of-scope bugs/debt/security gaps need `KI-NNN` entries; fixed KIs need `Resolved (commit, date)`.
- **Test coverage — real or performative?** 20 tests green sounds good, but if they're all shallow, coverage is weak. Ask about specific edge cases that matter.
- **Anything not said that should be?** Important patterns include: newly introduced side effects, breaking changes to contracts, perf regressions.

Response shape:
- Findings first. Do not summarize what works.
- Specific issues, graded: blocker / non-blocker / nice-to-have.
- For non-blockers, recommend whether to fix now or defer to hardening.
- End with `VERDICT: PASS / FAIL / ESCALATE`.

Verdict rules:
- `PASS` = no blockers and no required changes before the next round.
- `FAIL` = at least one blocker or required mechanical fix before the next round.
- `ESCALATE` = the review surfaced a DECISIONS-worthy choice, scope change, architecture conflict, or anything requiring user judgment.

## A or B fork

The agent surfaced a fork; you're being asked to pick. Usually the agent has a view — read for signs of preference.

- If the agent's preference is reasonable and well-argued, affirm and explain why.
- If the agent's preference is risky, push back with specifics.
- If both options are viable, pick based on planning context (what does the PRD/ARCHITECTURE prefer?) and explain.
- Sometimes there's a better third option — suggest it.

Don't say "I trust your judgment." The user came to you precisely because they want a second opinion.

## Bug found

Usually during audit or mid-round. The agent discovered something you might have missed in planning.

- **Acknowledge fairly.** If the plan was wrong, own it. Don't blame the agent for surfacing it.
- **Decide the fix direction.** Plan updates? DECISIONS.md entry? Revision note?
- **Ensure the paper trail.** The user should be able to trace, in 6 months, why a thing is the way it is. If the bug/debt is real but out of current scope, add or propose a `KNOWN_ISSUES.md` entry rather than burying it in the review conversation.

## User isn't sure

The user has a concern but isn't articulating it precisely. Ask:

- "Which specific piece feels off?"
- "What outcome are you afraid of?"
- "Does the agent's reasoning feel complete, or hand-wavy?"

Then read the actual artifact (code, plan, decision). Don't work from the summary.

## What NOT to do

- **Don't rubber-stamp.** Tests passing doesn't mean design is right.
- **Don't be generic.** "Looks good" helps nobody. Specific observations — specific approvals.
- **Don't improvise architecture mid-round.** If the agent surfaces a real architectural issue, pause, discuss, decide. Don't fold it silently into the current round.
- **Don't defend the planner's prior output out of ego.** If the plan was wrong and the agent caught it, good. Update and move on.
- **Don't try to re-do the audit yourself from scratch.** The agent audited; you're reviewing the audit, not re-running it.

## Tone

Direct, specific, ready to defend. The user is short on time and surrounded by artifact-heavy context. Concise review is a gift.

## When to pull planning back open

Occasionally mid-implementation, something the user learns forces a scope change. Signals:

- A customer has changed a key requirement.
- A technical surprise invalidates a load-bearing assumption.
- A feature turns out to be much bigger or smaller than estimated.

In these cases, don't just patch the current phase — step back to scope. Ask:

- Does the ROADMAP need to change?
- Does PRD need to change?
- Does ARCHITECTURE need to change?

A short scope reopening is cheap; a scope reopening that wasn't done and causes cascading rework later is expensive. Don't avoid it out of fear of the delay. If the answer is yes to any of these, the user should return to `mvp-architect` for the appropriate phase, not patch this skill.
