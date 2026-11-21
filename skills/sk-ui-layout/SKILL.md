---
name: sk-ui-layout
description: >
  Compose page layouts and page region layouts using the three @analygo/ui
  layout primitives (Container, Stack, Grid) plus Surface and HeroSurface
  for background treatment. Use when asked to lay out a page, arrange region
  zones, fix hand-rolled layout divs (like min-h-dvh flex flex-col), set up
  a three-column sidebar+content layout, compose a full page from Container
  to Stack to Grid to Card, or audit a consumer PR for layout violations
  (no Section, no TwoColumn, no hand-rolled max-w mx-auto). Also use when
  the user asks about how to achieve a specific arrangement like "cards in
  a responsive grid", "centered content with sidebar", or "hero with background".
  NOT for building the primitives themselves (they exist), NOT for building
  page archetypes (see sk-ui-archetypes), and NOT for general React
  layout knowledge.
license: MIT
compatibility: "@analygo/ui · Tailwind CSS 3.4+ · Base UI · CVA"
metadata:
  author: Analygo Team
  version: 1.0.0
---

# sk-ui-layout — composing with layout primitives

The layout system has **exactly three primitives** plus two surface wrappers.
Each owns exactly one concern:

| Primitive | Barrel | Owns | Never owns |
|---|---|---|---|
| `Container` | `@analygo/ui/layouts` | max-width + centering + edge padding | height, background, vertical rhythm |
| `Stack` | `@analygo/ui/layouts` | vertical gap between children | box (border/background), horizontal layouts, internal card spacing |
| `Grid` | `@analygo/ui/layouts` | responsive column count (2/3/4) | one-item layouts, asymmetric widths, tables |
| `Surface` | `@analygo/ui/atoms` | small-region paint (accent border + tint + glow) | layout, full-bleed hero, structure (use Card) |
| `HeroSurface` | `@analygo/ui/atoms` | full-bleed page-region paint (hero/grid/glow or tinted band) + min-height | content width/layout |

---

## Shell Responsibility Model — the ONE rule

> **Shells (Chrome/SidebarAppShell) own structural chrome positioning. They do NOT own content width constraints or padding.**

| Level | Owns | Does NOT own |
|---|---|---|
| **Chrome** (Chrome, SidebarAppShell) | SidebarProvider, sidebar positions, topbar zone, main content slot, viewport height | Content max-width, content padding, children's column widths |
| **Layout primitives** (Container, Stack, Grid) | Max-width tokens, horizontal padding, vertical rhythm, responsive columns | Background treatment, chrome effects |
| **Surface paint** (Surface, HeroSurface) | Accent border + tinted background + glow | Layout, structure, content |
| **Consumer page** (page.tsx, FeatureView) | Choice of primitives, composition order, which components to use | — |

**Every archetype and page follows this.** If you find a layout div in `apps/platform/app/` with `px-6 max-w-6xl mx-auto`, that's a violation — Container owns that. If Chrome has `px-8` on its `<main>` slot, that's a violation — the page owns padding via Container.

---

## The three primitives

### Container — horizontal width

Container is how you constrain content width. It applies `max-w-<size>`, `mx-auto`, and
`px-4 sm:px-6 lg:px-8` — everything you'd otherwise hand-roll.

```tsx
import { Container } from "@analygo/ui/layouts";

<Container width="7xl">  {/* sm | md | lg | xl | 2xl | 3xl | 4xl | 5xl | 6xl | 7xl | full | none */}
  {/* children are centered with edge padding */}
</Container>
```

**Width scale:** Tailwind's own step names: `"sm"` = 24rem, `"7xl"` = 80rem (default),
`"full"` = no max-width (edge padding only), `"none"` = zero padding + no max-width.

Container is always the outer frame of a page region:
```
Page region = Container(width) → Stack(gap) → { content }
```

### Stack — vertical rhythm

Stack owns the gap between vertically arranged children. It renders `flex flex-col` plus the
gap class. It does NOT add border, background, or width — that's Container's job or the
children's.

```tsx
import { Stack } from "@analygo/ui/layouts";

<Stack gap="4" align="center">
  <div>item 1</div>
  <div>item 2</div>
</Stack>
```

**Props:**
- `gap`: `"0" | "0.5" | "1" | "1.5" | "2" | "2.5" | "3" | "4" | "5" | "6" | "8" | "10" | "12"` — Tailwind gap step. Default `"3"`.
- `align`: `"stretch"` (default) | `"start"` | `"center"` | `"end"`.

**Stack is NOT a box.** Never put `border`, `bg-*`, or `rounded` on a Stack. If a region
needs a background, wrap it in `Surface` or `HeroSurface`:

```tsx
// ❌ Stack used as a box
<Stack className="rounded-xl border bg-card">…</Stack>

// ✅ Stack spaces; Surface paints
<Surface variant="muted">
  <Stack gap="4">…</Stack>
</Surface>
```

### Grid — responsive columns

Grid owns responsive column counts. It handles `1 col → 2 cols → N cols` across breakpoints
without hand-rolling `grid-cols-1 sm:grid-cols-2 lg:grid-cols-3`.

```tsx
import { Grid } from "@analygo/ui/layouts";

<Grid cols={3} gap="6">
  <Card>…</Card>
  <Card>…</Card>
  <Card>…</Card>
</Grid>
```

**Props:**
- `cols`: `2 | 3 | 4`. `3` is default. Breakpoints: cols=3 → `1 col on base, 2 on sm, 3 on lg`.
- `gap`: same Tailwind gap scale as Stack. Default `"6"`.

Grid handles: loading placeholders (maintain grid rhythm with skeleton divs), empty (renders
nothing), and variable children count (children wrap to new rows).

**Grid does NOT handle** asymmetric column widths. If you need a `240px sidebar | flex-1 content`
or `w-60 | flex-1 | w-80` (Explorer), use raw `flex` + `Surface` — no Grid primitive exists
for that (see sk-ui-archetypes for the Explorer pattern).

---

## Surface paint primitives

### Surface — small-region accent paint

Used when a single card/callout/panel needs a tinted background, accent border, and optional
hover treatment.

```tsx
import { Surface } from "@analygo/ui/atoms";

<Surface variant="blue" interactive>
  <p>Info callout</p>
</Surface>
```

**Valid variants:** `"white"` (default) · `"glass-white"` · `"blue"` · `"glass-blue"` ·
`"red"` · `"glass-red"` · `"success"` · `"glass-success"` · `"warning"` · `"glass-warning"` ·
`"muted"` · `"glass-muted"` · `"glass-slate"`.

**`variant="base"` does NOT exist.** TypeScript will reject it. Always use `"white"` for
neutral content regions, `"muted"` for sidebar/inspector panels.

### HeroSurface — full-bleed page-region paint

Used for hero bands, muted/accent page sections, or full-viewport landing blocks. Content
inside must be wrapped in Container → Stack → Grid.

```tsx
import { HeroSurface } from "@analygo/ui/atoms";
import { Container } from "@analygo/ui/layouts";
import { Stack } from "@analygo/ui/layouts";
import { Grid } from "@analygo/ui/layouts";

<HeroSurface tone="muted" height="auto">
  <Container width="7xl">
    <Stack gap="4">
      <Grid cols={3} gap="6">
        <Card>…</Card>
      </Grid>
    </Stack>
  </Container>
</HeroSurface>
```

**Props:**
- `tone`: `"hero"` (grid+glow), `"plain"` (transparent), `"muted"` (bg-muted/30), `"accent"` (bg-primary/5)
- `height`: `"svh"` (full viewport, default), `"auto"` (content-sized), `"auto-min"` (≥ viewport)

---

## Composition rules — the hierarchy you must follow

### Canonical page region

```
<HeroSurface tone="muted" height="auto">   ← optional; only if the region needs paint
  <Container width="7xl">                   ← ALWAYS present; owns width
    <Stack gap="4">                         ← ALWAYS present; owns vertical rhythm
      <div>                                 ← heading area (or Grid, or Card)
      <Grid cols={3} gap="6">               ← optional; only for columnar content
        <Card>…</Card>
        <Card>…</Card>
      </Grid>
      <Stack gap="2">                       ← nested Stack for within-group rhythm
        <Surface variant="muted">            ← optional; only for per-item paint
          <Card size="sm">…</Card>
        </Surface>
      </Stack>
    </Stack>
  </Container>
</HeroSurface>
```

### The decision flow

When composing a layout block, ask in order:

1. **Does it need a background treatment?** → Wrap in `HeroSurface` (full-bleed page region)
   or `Surface` (small region). No? Skip.
2. **Does it need a horizontal width cap?** → `<Container width="…">`. Always yes for page content.
3. **Does it have multiple vertical blocks?** → `<Stack gap="…">`. Almost always yes.
4. **Is it a columnar repeat of the same item?** → `<Grid cols={N}>`. Yes for card grids.
5. **Is it a single self-contained unit?** → `<Card>`.

### Invalid patterns — caught by depcruise and review

| Pattern | Why it's wrong | Fix |
|---|---|---|
| `import { Flex } from "@analygo/ui/layouts"` | Flex is internal-only; not exported in public API | Use raw `<div className="flex">` |
| `import { Section } from "@analygo/ui/shells"` | Section is deprecated/removed | Compose `Surface | HeroSurface` + `Container` + `Stack` |
| `import { TwoColumn } from "@analygo/ui/layouts"` | TwoColumn is deprecated — maps 1:1 to CSS grid | Use raw `<div className="grid grid-cols-[240px_1fr]">` |
| `<div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">` | Hand-rolled Container | Replace with `<Container width="7xl">` |
| `<div className="space-y-4 md:space-y-6">` | Hand-rolled vertical rhythm | Replace with `<Stack gap="4">` |
| `<div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">` | Hand-rolled Grid | Replace with `<Grid cols={3} gap="6">` |
| `min-h-[*vh]` | Hardcoded viewport — breaks on mobile (CI script flags it) | Use `min-h-dvh` (dynamic) or `min-h-svh` (small safe), or `HeroSurface` with `height="svh"` |

---

## Page structure: five-layer architecture

Every page follows five layers. The first three are the agent's responsibility here:

| Layer | File | Lines | Owns | Layout primitives used |
|---|---|---|---|---|
| 1 | `page.tsx` | ≤20 | Next.js routing only | None — `export default function Page() { return <FeatureView />; }` |
| 2 | `FeatureView.tsx` | ~150 | Composition, wire hooks to components, layout arrangement | Container, Stack, Grid, Surface |
| 3 | `components/` | ~150/each | Pure render components, props only | Card, Card internals, atoms |
| 4 | `hooks/` | ~100/each | React Query + useState hooks | None |
| 5 | `lib/api/` | — | API client functions | None |

### FeatureView.tsx — where layout lives

```tsx
// ✅ Correct — page compositor, not a render component
import { Container, Stack, Grid } from "@analygo/ui/layouts";
import { Card, CardHeader, CardTitle } from "@analygo/ui/card";
import { MyDataComponent } from "./components";

export function FeatureView() {
  const { data, isLoading } = useData();
  if (isLoading) return <LoadingSkeleton />;
  return (
    <Container width="7xl">
      <Stack gap="4">
        <div className="max-w-3xl">
          <h2 className="text-section-heading">Title</h2>
          <p className="text-section-description">Desc</p>
        </div>
        <Grid cols={3} gap="6">
          {data.map(item => (
            <MyDataComponent key={item.id} data={item} />
          ))}
        </Grid>
      </Stack>
    </Container>
  );
}
```

---

## Gotchas

1. **Container has horizontal padding baked in.** `px-4 sm:px-6 lg:px-8` is part of its CVA base.
   You never add edge padding to a Container.

2. **Stack is `flex flex-col`.** If you pass `className="flex-row"`, you break the component's
   contract. Use a raw `<div className="flex">` for horizontal layouts.

3. **Grid cols=3 breakpoints:** 1 col on base, 2 on sm, 3 on lg. Not configurable. If you need
   different breakpoints, use raw Tailwind grid.

4. **`Container width="full"`** is `max-w-full` (no width constraint) but still has edge padding.
   Use `width="none"` for zero max-width AND zero padding (rarer).

5. **Surface already has `border-border` + `rounded-sm` + `p-[9px_12px]` in its base.** Its
   `className` overrides padding. Archetypes typically override padding to zone-level values
   like `p-4` or `py-6`.

6. **You can put Grid inside Stack.** Stack owns vertical gap between blocks; Grid owns
   column layout within a block. They compose: `<Stack gap="6"><Grid cols={3}>…`.

7. **Don't nest Containers.** One Container per region. The CVA base already includes edge
   padding — nesting adds unwanted double padding.

8. **Surface variants are validated by TypeScript.** `variant="base"` is a compile error.
   If you see it in a file, it was written before the type union was strict. Fix it.

---

## Examples

### Single-column prose page

```tsx
<Container width="3xl">
  <Stack gap="4">
    <h1 className="text-section-heading">Title</h1>
    <p className="text-card-body">Body text…</p>
  </Stack>
</Container>
```

### Dashboard with cards and a full-width activity section

```tsx
<Container width="7xl">
  <Stack gap="6">
    <div className="max-w-3xl">
      <h2 className="text-section-heading">Dashboard</h2>
    </div>
    <Grid cols={3} gap="6">
      <Card><CardContent>…</CardContent></Card>
      <Card><CardContent>…</CardContent></Card>
      <Card><CardContent>…</CardContent></Card>
    </Grid>
    <Card>
      <CardHeader><CardTitle>Activity</CardTitle></CardHeader>
      <CardContent>…</CardContent>
    </Card>
  </Stack>
</Container>
```

### Hero section with grid+glow

```tsx
<HeroSurface tone="hero" height="svh">
  <div className="relative z-10 flex min-h-svh items-center">
    <Container width="7xl">
      <Stack gap="4" align="center" className="max-w-3xl mx-auto text-center">
        <p className="text-section-eyebrow">Platform</p>
        <h1 className="text-hero-heading">Our product</h1>
        <p className="text-hero-subtitle">Tagline</p>
      </Stack>
    </Container>
  </div>
</HeroSurface>
```

---

## References

- `sk-ui-consumer-page-layout` — Consumer page assembly (page.tsx → *View.tsx → components/), Next.js routing hierarchy
- `sk-ui-consumer-guide` — Component discovery, tokens, imports, guardrails (apply alongside for consumer work)
- `src/layouts/Layout.mdx` — Storybook overview doc with live canvases
- `src/layouts/Container/Container.tsx` — Container source + CVA
- `src/layouts/Stack/Stack.tsx` — Stack source + CVA
- `src/layouts/Grid/Grid.tsx` — Grid source + CVA
- `src/atoms/Surface/Surface.mdx` — Surface doc with all variants
- `src/atoms/HeroSurface/HeroSurface.tsx` — HeroSurface source
- `src/foundation/FoundationOverview.mdx` — complete design system reference
- `.dependency-cruiser/platform-deprecated.rules.cjs` — catches Section/TwoColumn/Flex imports
- `scripts/check-viewport-heights.mjs` — CI gate for `min-h-[Nvh]`
- `.pi/skills/sk-ui-archetypes/SKILL.md` — when you need a reusable three-zone layout