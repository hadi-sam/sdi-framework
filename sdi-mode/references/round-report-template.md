# Round Report Template

A report is a short factual handoff: fact, evidence, consequence. Link to the
plan, commits, checks and reviewer artifacts instead of copying them. Omit empty
optional sections; do not require a narrative, test-count delta or restatement
of the plan.

```markdown
# Round [X] / [checkpoint or combined scope] — [title]

- **Status:** [complete / blocked / awaiting decision]
- **Plan:** [path + sections]
- **BASE_SHA:** [literal SHA captured before the round]
- **Commit A:** [SHA + summary]
- **Work-item profile:** [link to plan §0]

## Delivered

- `[path or behavior]` — [factual result] — evidence: [commit/check/link].

## Checks

| Command or smoke | Result | Why sufficient |
|---|---|---|
| `[exact command]` | [PASS/FAIL + relevant output] | [contract/risk/AC proved] |

[List skips only when they affect confidence. Counts are optional and included
only when the runner or an acceptance criterion makes them meaningful.]

## Review

[Omit when independent review was not justified or the checkpoint is user-gated.]

| Attempt | Reviewer profile entry | Verdict | Findings | Artifact |
|---|---|---|---|---|
| [N] | [plan §0 pointer] | [PASS/FAIL/ESCALATE] | [brief totals] | [link] |

- **Merged outcome:** [outcome under `auto-review-mode.md`].
- **Action:** [fix, decision, defer with trigger, or advance].

## Decisões desta rodada

- [Decision/KI link] — [fact] — [consequence].

[Write "None" only when this fixed section is required by a project's parser.]

## Deferred or excluded

- [item] — [concrete reason and destination/trigger].

## Open decision

- [question, options and recommendation; omit when none].

## Next

[Exact next action and any gate that must occur first.]
```

## Rules

- Make claims grep-able: name the behavior or path and link its evidence.
- Include unavailable services, skips or partial failures when they change what
  the evidence proves.
- Do not paste code or reviewer reports.
- Do not promote optional instrumentation or prose cleanup into a blocker.
- Record a pre-existing out-of-scope defect in `KNOWN_ISSUES.md` only when it has
  concrete evidence, blast radius and a fix trigger.
