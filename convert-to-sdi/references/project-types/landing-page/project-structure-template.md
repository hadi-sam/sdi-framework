# PROJECT_STRUCTURE Template — Landing page / marketing site

Repo layout for a marketing site. Adapt to the chosen framework (Astro, Next.js static, SvelteKit, etc.).

Target length: 150–250 lines.

## Structure

```markdown
# [Product] — Project Structure & Conventions

> Folder layout and conventions for the [Astro / Next.js / etc.] marketing site. Read by the coding agent as context when generating code.

## Top-Level Layout

\`\`\`
[repo-root]/
├── .github/                # CI workflows
├── public/                 # static assets — favicons, OG images, robots.txt
├── src/
│   ├── pages/              # routes (file-based)
│   ├── layouts/            # shared layouts (default, blog, doc)
│   ├── components/         # reusable UI (Hero, CTA, Pricing, Feature, FAQ)
│   ├── content/            # markdown/MDX content if local-source
│   ├── lib/                # utility modules (CMS client, form handlers, analytics)
│   ├── styles/             # globals, tokens, fonts
│   └── types/              # TS types for CMS schemas, etc.
├── content/                # CMS-drafts or local content (if not in src/)
├── tests/                  # smoke + visual tests
├── docs/                   # PRD, ARCHITECTURE, DECISIONS, KNOWN_ISSUES, MEMORY, etc.
└── [config files]
\`\`\`

## src/pages/ — Routes

\`\`\`
[tree of pages — index, pricing, about, blog, blog/[slug], legal/privacy, legal/terms, etc.]
\`\`\`

### Page conventions

- One file per page. No deep dynamic routing for marketing pages — keep URLs predictable.
- Each page exports: title, meta description, OG image (or generates one), structured data block.
- A page that needs server-side data fetches at build time (SSG) by default.

## src/components/ — UI building blocks

\`\`\`
[tree — Hero, Section, FeatureGrid, PricingTable, CTA, FAQ, TestimonialCarousel, Newsletter, Footer]
\`\`\`

### Component conventions

- Components are content-driven: props match CMS schema fields.
- No business logic in components beyond basic state (open/closed accordion, form state).
- Forms are isolated components that wrap the form handler from `src/lib/forms.ts`.

## src/content/ — Content (if local)

\`\`\`
[tree — blog/, case-studies/, etc., each with markdown/MDX files]
\`\`\`

## src/lib/ — Domain logic

\`\`\`
[tree]
\`\`\`

- `cms.ts` — CMS client, query helpers, response typing.
- `forms.ts` — form submission, validation, error mapping.
- `analytics.ts` — event tracking wrapper (consent-aware).
- `seo.ts` — metadata helpers, canonical URL builder, structured data generators.

## src/styles/

\`\`\`
[tree — globals.css, tokens.css, fonts/]
\`\`\`

Tokens align with `DESIGN_SYSTEM.md` exactly.

## Coding Conventions

### Framework idioms
- [Astro: prefer `.astro` for layout + static, islands for interactive bits]
- [Next.js: app router, RSC by default, client components only when needed]
- [Use the framework's image optimization — never raw `<img>` for above-the-fold images]

### TypeScript
- Strict mode. CMS responses typed at the boundary. No `any` in production code.

### Forms
- All forms go through `src/lib/forms.ts`. Direct fetch calls in components are not allowed.
- Submission state is local; success state may navigate to a thank-you page.

### SEO
- Every page sets `title`, `description`, `og:image`. The site has a fallback global meta config.
- Canonical URL is set on every page.

### Performance
- Lighthouse CI runs on every PR; perf score must be ≥ baseline.
- No third-party scripts above the fold without explicit reason.
- Fonts loaded via the framework's font optimizer; no FOUT/FOIT.

### Testing
- Smoke: a Playwright run that visits each page and asserts a known string.
- Visual regression (optional Phase 2): Chromatic or Percy.

### Commits & Branches
- [conventional commits, branch naming]

### Environment Variables
- CMS keys: `CMS_PROJECT_ID`, `CMS_TOKEN`.
- Form integrations: `RESEND_API_KEY`, `HUBSPOT_API_KEY`, etc.
- Analytics: `NEXT_PUBLIC_GA_ID`, `POSTHOG_KEY`.

## Coding agent kickoff prompt template

[End-of-doc prompt template — what the user pastes into the coding agent on day one.]
```

## Writing tips

- **Pages directory is the spine.** Keep it readable at a glance.
- **Components are content-shaped.** If a component has heavy logic, it probably belongs in `lib/`.
- **Performance conventions are non-negotiable.** State them and enforce in CI.
- **Form discipline matters.** Marketing teams add forms quickly; without a single chokepoint, validation and analytics drift.
