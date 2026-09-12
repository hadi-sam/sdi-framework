# DESIGN_SYSTEM Template — Dashboard / admin / internal tool

Dashboards have specific design pressures: density and scannability matter more than brand expression, data viz consistency is critical, and the kit is dominated by tables, charts, KPI tiles, and forms.

Target length: 250–400 lines.

## Structure

```markdown
# [Product] — Design System

> Visual language for the dashboard.

## 1. Design intent

[One paragraph. What should the dashboard feel like? Reference apps that nailed the tone (Linear, Attio, Height, Retool, Posthog, Vercel) — for tone, not literal copying. What to avoid (e.g. "do not feel cluttered like a legacy admin tool", "do not feel sparse like a marketing site").]

## 2. Typography

- **UI font:** [name + weight] — used for everything; keep one font family for cohesion
- **Monospace:** [name] — used for IDs, codes, technical fields, numbers in tables
- **Type scale:** explicit ladder (e.g. 11, 12, 13, 14, 16, 20, 24, 32) — note: dashboard scales are tighter than marketing
- **Line height:** comfortable for tables (1.5), tighter for KPI tiles (1.2)
- **Numeric typography:** tabular figures for tables and charts (`font-variant-numeric: tabular-nums`)

## 3. Color system

Dashboards lean heavily on neutrals; brand color is reserved for accent.

- **Brand:** primary (used sparingly — focus rings, primary CTAs, current selection)
- **Semantic:** success, warning, danger, info — used in badges, alerts, chart series
- **Neutrals:** ramp from background → border → muted → strong foreground
- **Chart palette:** discrete categorical palette (sequential preferred for ordered data; categorical for unordered)

### Token definitions

\`\`\`css
:root {
  --bg: ...;          /* page background */
  --bg-surface: ...;  /* cards, panels */
  --bg-muted: ...;    /* zebra stripes, hover */
  --fg: ...;
  --fg-muted: ...;
  --fg-subtle: ...;
  --border: ...;
  --border-strong: ...;
  --primary: ...;
  --success: ...;
  --warning: ...;
  --danger: ...;

  /* chart palette */
  --chart-1: ...;
  --chart-2: ...;
  /* ... at least 6, ideally 8 */
}

.dark { /* dark variants */ }
\`\`\`

### Semantic usage

| Token | Where used |
|---|---|
| `--bg-surface` | Card, panel, modal backgrounds |
| `--bg-muted` | Table zebra, hover row, section dividers |
| `--fg-muted` | Secondary text, axis labels, table headers |
| `--primary` | Selected state, focus ring, primary CTA |
| `--chart-1..N` | Series colors in stable order |
| ... | ... |

## 4. Spacing and layout

- **Grid base:** 4px or 8px (commit to one)
- **Card padding:** consistent — 16px or 24px
- **Section gaps:** 16/24/32 — chosen scale
- **Container:** dashboard often uses fluid width with padding; sidebar reserves fixed pixel column

## 5. Radii and elevation

- **Border radius:** restrained — 4 or 6 for inputs/buttons, 8 for cards, 12 for modals
- **Shadow usage:** very restrained on dashboards — borders carry the work; shadow only for floating menus and modals

## 6. Iconography

- **Library:** [Lucide / Heroicons / Phosphor / custom]
- **Default size:** 16px in line with text, 20px standalone
- **Stroke weight:** consistent across the app

## 7. Data visualization

The most consequential design decision in a dashboard.

### 7.1 Chart kit

Standardize on these chart types for these purposes:

| Purpose | Chart |
|---|---|
| Trend over time | Line |
| Compare categories | Bar |
| Part-to-whole | Stacked bar (avoid pie except for ≤4 segments) |
| Distribution | Histogram or violin |
| Single number with context | KPI tile + sparkline |
| Funnel | Dedicated funnel chart |

### 7.2 Series colors

Ordered list of palette colors used in stable order across all charts. First series always uses `--chart-1`.

### 7.3 Axis and grid

- Y-axis: gridlines subtle (`--border` at low opacity), labels muted
- X-axis: dates formatted consistently (e.g. `MMM d` for short range, `MMM` for long)
- Tooltip: appears on hover with all series values; consistent layout across charts

### 7.4 Empty/loading/error states

- Loading: skeleton matching final chart shape, no spinner
- Empty: centered message with icon, suggestion for action
- Error: centered message; add retry or an error code only when the flow supports recovery or operations consume the code

## 8. Component patterns

Dashboard kit:

- **KPI tile:** large number + label + delta (color-coded) + sparkline
- **Data table:** column headers (sortable), rows, hover, selection, pagination, bulk actions
- **Filter bar:** date range + dimension selectors + saved views menu
- **Drawer/Sheet:** slide-in for record detail, action confirmations
- **Modal:** confirmations, configuration, multi-step flows
- **Toast / inline alert:** transient feedback after actions
- **Empty state card:** illustrated empty state for collections

## 9. Forms

- **Field layout:** label above, input full-width within container
- **Validation feedback:** inline below field, real-time after first blur
- **Multi-field forms:** grouped logically, with section headers if >5 fields
- **Buttons:** primary right-aligned, secondary left of primary (or top-left for back)

## 10. Accessibility

- **WCAG 2.2 AA** as floor
- **Keyboard navigation:** every action reachable; visible focus rings
- **Color is never the only indicator:** charts and badges also use icons or text
- **Contrast ratios:** body ≥ 4.5:1, UI controls ≥ 3:1
- **Reduced motion:** all animations have static fallback

## 11. Dark mode

Omit this section when dark mode is unsupported. When it is required, identify the affected components and the smallest evidence that proves the theme contract; keep mode-specific values in tokens.

## 12. Implementation notes

- **CSS strategy:** [Tailwind / CSS modules / vanilla-extract]
- **Component primitives:** [shadcn / Radix / Headless UI]
- **Chart abstraction:** use a shared wrapper only when repeated theme/behavior contracts justify one; otherwise use the library directly with documented tokens
- **Where tokens live:** `src/styles/tokens.css` — single source of truth
```

## Writing tips

- **Density beats expressiveness.** Dashboards reward scannability over flair.
- **Chart kit is finite.** Define it; resist inventing custom charts without a strong reason.
- **Tabular numerals are non-negotiable** for tables and KPI tiles — alignment matters.
- **Empty/loading/error are first-class.** Most dashboards skip these and feel broken in real conditions.

## Common failure modes

- **Brand color overused.** Primary should be rare; neutrals do the work.
- **Chart inconsistency.** Centralize only the shared options needed to enforce the chosen chart contract.
- **Accessibility deferred.** Internal tools often skip accessibility, then can't onboard a colleague who needs it.
- **Tokens drift from code.** End-of-phase audit of `globals.css` vs documented tokens prevents this.
