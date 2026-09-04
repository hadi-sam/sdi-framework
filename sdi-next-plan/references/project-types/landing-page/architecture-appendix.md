# Architecture Appendix — Landing page / marketing site

Insert these sections into ARCHITECTURE.md at §2 ("Type-specific architecture") of the core architecture template.

## §2.1 Rendering and build strategy

State the chosen approach explicitly:

- **Approach:** [Fully static (SSG)] / [ISR with revalidation interval N] / [SSR for dynamic pages] / [Hybrid (SSG core + SSR for /pricing or /search)]
- **Framework:** [Astro] / [Next.js with `export`] / [Hugo] / [11ty] / [SvelteKit static] — with rationale tied to content workflow
- **Build trigger:** [push-to-main only] / [CMS webhook → rebuild] / [scheduled rebuild every N hours]
- **Routing:** [file-based] / [config-based]; mention any dynamic segments (`/blog/[slug]`)

## §2.2 Content pipeline

Where copy and assets live and how they flow into the site.

- **Source of truth:** [CMS (Sanity/Notion/Contentful/Storyblok/headless WP)] / [Markdown files in repo] / [Hybrid — copy in CMS, structure in code]
- **Authoring workflow:** who edits, in what tool, with what preview surface?
- **Asset handling:** images via [Cloudinary] / [next/image] / [CDN with `sharp` build step]; videos via [Mux] / [YouTube embed] / [self-hosted]
- **Multi-language (if applicable):** routing strategy (`/en/`, `/pt/`, subdomain), translation source

## §2.3 SEO and metadata

- **Meta strategy:** per-page custom Open Graph + Twitter cards generated from CMS fields; fallback global defaults
- **Sitemap:** auto-generated at build, segmented if >5k URLs, submitted to GSC
- **Structured data:** which Schema.org types are emitted, on which pages
- **Canonical URLs:** strategy for duplicate-content prevention
- **Robots and indexing:** which sections (e.g. /preview/) are noindexed

## §2.4 Performance budget

State the actual numbers, not vague intent.

| Metric | Target |
|---|---|
| LCP | < 2.5s |
| INP | < 200ms |
| CLS | < 0.1 |
| Page weight (JS+CSS, gz) | < N kb |
| Lighthouse Perf score | ≥ 90 |

Mention how these are measured (Lighthouse CI on PRs, real-user PageSpeed Insights, CrUX dashboard).

## §2.5 Forms and lead capture

For each form on the site:

- **Destination:** [CRM API] / [Email service (Mailchimp/Resend)] / [Sheets via Apps Script] / [Custom backend endpoint]
- **Validation:** client-side schema (Zod/yup) + server-side re-validation
- **Spam protection:** [honeypot only] / [hCaptcha/Turnstile] / [rate-limit by IP]
- **Confirmation UX:** inline success message + optional redirect; email confirmation flow if applicable
- **Failure UX:** what the user sees if the upstream destination is down

## §2.6 Analytics and consent

- **Analytics tool:** [GA4 / PostHog / Plausible / Fathom / Vercel Analytics]
- **Event taxonomy:** named events for form submits, CTA clicks, scroll depth (only if useful)
- **Consent flow:** [Cookiebot / OneTrust / custom CMP]; default behavior before consent (no tracking, anon tracking, full tracking)
- **Compliance posture:** GDPR, LGPD, CCPA — which apply, how the site complies

## §2.7 Edge config and personalization (if applicable)

- **Edge runtime:** [Vercel Edge / Cloudflare Workers / none]
- **Use cases:** geo-routing, A/B test bucketing, feature flags from edge config
- **Cache invalidation:** how a flag flip propagates (instant via edge config, eventual via revalidation)
