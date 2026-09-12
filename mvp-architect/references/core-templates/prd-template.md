# PRD Template

The PRD is a **decision record**, not a requirements spec in the heavy sense. It captures what the product is, who it's for, what's in MVP, what's explicitly not, and how you'll know the MVP worked.

Target length: 400–600 lines. Crisp, concrete, defendable.

## Structure

```markdown
# [Product Name] — Product Requirements Document (PRD)

> **Status:** MVP specification · **Last updated:** YYYY-MM-DD

## 1. Product Overview

[One paragraph: what the product is, who it's for, what's the core thesis about why it works. One more paragraph: strategic context — who's paying for the MVP, single-tenant vs multi-tenant, any existing work this builds on.]

## 2. Target Users & Roles

[Table of roles. For each: role name, responsibilities, permissions summary.]

[If there's a cross-org role like Super Admin, separate subsection.]

## 3. Core Features (MVP)

### 3.1 [Feature 1]
[Description. Specific behaviors. Key constraints.]

### 3.2 [Feature 2]
...

[Each subsection is 5–30 lines depending on feature complexity. Enough to remove ambiguity for someone implementing; no more.]

## 4. Non-Functional Requirements

- **Language (UI)**: [English only / multilingual / etc.]
- **Latency**: [targets for user-facing paths]
- **Availability**: [MVP expectation; formal SLA or best-effort]
- **Security**: [auth, authorization, RLS, webhook auth, etc.]
- **Compliance**: [GDPR, LGPD, HIPAA, SOC2, or N/A]
- **Data Retention**: [explicit decision or "TBD post-MVP"]
- **Observability (only if a product/operations requirement)**: [named need and surface, or N/A]

## 5. Out of Scope for MVP

[Bulleted list. Items the user has confirmed are explicitly NOT in MVP. Each item stands alone — don't group by "theme" if it obscures what's being deferred.]

## 6. Success Metrics

[How will you know the MVP worked? 2–5 concrete, measurable criteria. At least one should be a qualitative acceptance metric ("salespeople find the funnel usable without training"), others should be quantitative.]

[Optionally: a time-bounded evaluation window, e.g. "After 90 days of production use, we expect..."]
```

## Writing tips

- **Users are real roles.** "Admin", "Manager", "Salesperson", "Viewer" — not "user" everywhere.
- **Every feature has an explicit owner in the RBAC.** If you say "leads can be moved", the reader should know *who* can move them from the PRD alone.
- **Out of scope is a contract, not a wish list.** If the customer is pushing back on something being out of scope, that's a real conversation to have — don't soft-mark it.
- **Success metrics force clarity.** "Platform is easy to use" is not a success metric. "Follow-up pickup rate ≥ 15pp higher than baseline after 90 days" is.

## Common failure modes

- **Too many features.** MVP ≠ complete product. If the PRD has 15 features in section 3, most of them are Phase 2.
- **Vague roles.** "Users can do things" — no. Specific people, specific actions, specific constraints.
- **Missing out-of-scope.** If section 5 is short, either the MVP is unusually minimal or (more likely) the section is underdeveloped. Push the user to name deferrals.
- **Aspirational non-functional targets.** "99.99% uptime" without a reliability plan is a fantasy. Best-effort is fine for MVP; say so.

## The opening paragraph

The first paragraph is the single most re-read sentence in the bundle. Invest effort. It should:

- Name the product.
- State what it does in one concrete sentence.
- State the core product hypothesis (why this works, what metric it should move).
- Hint at the audience.

Example template:

> [Product] is a [category] that [concrete mechanism]. The core thesis is that [X produces Y measurable outcome]. MVP is deployed for [first customer]; designed from day one for [scaling characteristic].

## After drafting

Before moving to ARCHITECTURE, check:

- Can a stranger read the PRD and know what's being built?
- Does every feature in §3 tie to a user role in §2?
- Is §5 long enough to feel real? (2 items = probably too soft)
- Are success metrics something you could check in 90 days?

If any answer is "no," revise before generating the next artifact.
