---
name: sk-ui-archetypes
description: >
  Build, fix, review, register, and write Storybook stories for page archetype
  factory components (Explorer, Detail, Canvas) in @analygo/ui — the reusable
  three-zone compositions that eliminate hand-rolled layout divs from consumer
  code. Use when asked to create a new page archetype, fix an existing one that
  uses raw <div> or invalid Surface variants (variant="base"), write Storybook
  stories for an archetype ("produce once in Storybook, import everywhere"),
  register an archetype in the public API, audit a PR for archetype compliance,
  or compose the Explorer's sidebar+content+inspector pattern. Also use when
  the user asks for a reusable page layout template — archetypes are the answer.
  NOT for composing page regions from primitives (see sk-ui-layout), NOT for
  general Storybook story writing (see sk-storybook-component-testing), and NOT
  for building atoms or molecules.
license: MIT
compatibility: Storybook 10.5 · CSF 3 · React-Vite · @analygo/ui primitives · CVA
metadata:
  author: Analygo Team
  version: 1.0.0
---

# sk-ui-archetypes — page archetype factories

Page archetypes are **layout factory components** that capture a proven page
composition pattern once and export it for consumers. They replace hand-rolled
`<div className="flex min-h-dvh">…` with a typed, primitives-only, Storybook-verified
component.

The three archetypes:

| Archetype | Zone layout | Story file |
|---|---|---|
| **Explorer** | header + toolbar + [sidebar | content | inspector] + footer | `recipes/archetypes/ArchetypeExplorer.stories.tsx` |
| **Detail** | breadcrumbs + heading + actions + metadata grid + tabs + content | `recipes/archetypes/ArchetypeDetail.stories.tsx` |
| **Canvas** | toolbar + full-bleed canvas area + status bar | `recipes/archetypes/ArchetypeCanvas.stories.tsx` |

---

## File structure

```
src/features/archetypes/<name>/
├── <Name>.tsx          ← Factory component (primitives only)
├── <Name>.types.ts     ← Props interface (ReactNode slots)
├── <Name>.stories.tsx  ← Storybook stories (co-located)
└── index.ts            ← Barrel export
```

Registered in `src/features/index.ts` (add to the barrel chain) + optionally
`src/registry.ts` for CVA schema audit.

---

## The composition hierarchy

Every archetype follows this enforced nesting:

```
Container width="full"     ← horizontal max-width + edge padding
  Stack gap="0"            ← vertical rhythm (zero gap between zones)
    Surface variant="white"  ← header zone (optional)
    Surface variant="white"  ← toolbar zone (optional)

    {/* One allowed flex-row div */}
    <div className="flex flex-1 min-h-dvh overflow-hidden">
      Surface variant="muted"  ← sidebar (w-60, hidden < lg, optional)
      Surface variant="white"  ← content (flex-1, always present)
        Stack gap="4"          ← content internal vertical rhythm
      Surface variant="muted"  ← inspector (w-80, hidden < lg, optional)
    </div>

    Surface variant="white"  ← footer zone (optional)
```

### Why this hierarchy

| Layer | Primitive | Purpose | Cannot be replaced by |
|---|---|---|---|
| Outer frame | `Container width="full"` | Constrain width, center content, edge padding | A `<div>` with `max-w-* mx-auto px-*` |
| Zone vertical stack | `Stack gap="0"` | Arrange zones (header/toolbar/row/footer) vertically | `space-y-*` or `flex-col gap-*` on a div |
| Each zone | `Surface variant="…"` | Consistent paint (border, background, scroll) | A `<div>` with `border-* bg-* p-*` |
| Content internal spacing | `Stack gap="4"` | Vertical gap between content items | `space-y-4` or `[&>*+*]:mt-4` |

### The one allowed raw `<div>`

The three-column row (sidebar | content | inspector) must use a single flex div.
The reason: no layout primitive handles asymmetric column widths (w-60 / flex-1 / w-80)
with independent overflow-y per column. Grid handles equal-width columns only.

When you write this div, annotate the reason:

```tsx
{/* Three-column row: sidebar | content | inspector.
    Raw flex div required — no Grid variant handles
    asymmetric widths (w-60 / flex-1 / w-80) with
    independent overflow-y per column. */}
<div className="flex flex-1 min-h-dvh overflow-hidden">
```

This is the **ONLY** acceptable raw `<div>` in any archetype.

---

## Zone rules

| Zone | Surface variant | Width | Hidden | Spacing pattern |
|---|---|---|---|---|
| header | `"white"` | full (Container) | n/a | `<Surface>{header}</Surface>` |
| toolbar | `"white"` | full (Container) | n/a | `<Surface>{toolbar}</Surface>` |
| sidebar | `"muted"` | `w-60 shrink-0` | `hidden lg:block` | `<Surface className="p-4"><Stack gap="3">{sidebar}</Stack></Surface>` |
| content | `"white"` | `flex-1 min-w-0` | n/a | `<Surface className="py-6"><Stack gap="4">{content}</Stack></Surface>` |
| inspector | `"muted"` | `w-80 shrink-0` | `hidden lg:block` | `<Surface className="p-4"><Stack gap="3">{inspector}</Stack></Surface>` |
| footer | `"white"` | full (Container) | n/a | `<Surface className="border-t">{footer}</Surface>` |

**Why `"muted"` for sidebar/inspector:** Subtle background tint that visually separates
navigation/info panels without drawing attention. Neutral enough for any page context.

**Why `"white"` for header/toolbar/content/footer:** These zones blend with the chrome's
background — they don't need visual distinction from the page canvas.

---

## Props contract (types file)

Every slot is optional. The archetype renders zones only when the respective prop
is filled.

```tsx
"use client";
import type { ReactNode } from "react";

export interface ExplorerProps {
  header?: ReactNode;
  toolbar?: ReactNode;
  sidebar?: ReactNode;
  content?: ReactNode;
  inspector?: ReactNode;
  footer?: ReactNode;
}
```

For multi-variant archetypes (e.g., Detail has `breadcrumb` + `heading` + `actions` +
`metadata` + `tabs`), model it with the relevant slot names. If the archetype has
distinct visual treatments, use a **discriminated union** following Chrome's pattern:

```ts
type ExplorerProps =
  | { variant: "full"; sidebar: ReactNode; inspector: ReactNode; content: ReactNode }
  | { variant: "minimal"; content: ReactNode };
```

---

## Storybook — produce once

### Tags

```ts
tags: ["autodocs", "recipe", "base-ui"]
```

- `"autodocs"` — mandatory for auto-generated docs pages
- `"recipe"` — tier: composable pattern (not an atom or molecule)
- `"base-ui"` — framework: built from @analygo/ui primitives

### Meta

```tsx
const meta = {
  component: Explorer,
  title: "Recipes / Archetypes / Explorer",
  parameters: { layout: "fullscreen" },
  tags: ["autodocs", "recipe", "base-ui"],
} satisfies Meta<any>;  // <any> because the component has no typed props (ReactNode slots)

export default meta;
type Story = StoryObj<typeof meta>;
```

The component type in `satisfies Meta<any>` must be `<any>` because the archetype takes
ReactNode slots rather than typed props — TypeScript can't infer the meta type from
slot-only components.

### Required stories

| Story | State | JSDoc |
|---|---|---|
| **Default** | Realistic data through all slots | "Shows all five zones with realistic data. Canonical pattern for list/collection pages." |
| **Minimal** | Only content (no sidebar/inspector) | "No sidebar or inspector — for data-dense pages where every pixel matters." |
| **EmptyState** | Empty content area (Empty component) | "No data yet — shows the Empty primitives to guide the user." |
| **Loading** | Spinner in content zone | "Data is being fetched — spinner in the content region." |
| **NotFound** | Empty with error message | "Entity not found — full-bleed Empty with error guidance." |

### Story pattern

Every story wraps the archetype in a **SidebarAppShell** with demo data. The archetype
is never rendered standalone — without chrome it has no visual context.

```tsx
import { SidebarAppShell } from "../../features/chrome/SidebarAppShell/SidebarAppShell";
import {
  SIDEBAR_RAIL_DEMO_BRAND,
  SIDEBAR_RAIL_DEMO_NAV,
  SIDEBAR_RAIL_DEMO_SECONDARY,
  SIDEBAR_RAIL_DEMO_USER,
} from "../../features/chrome/demo-data";
import { Explorer } from "./Explorer";
import { Container } from "../../layouts/Container";
import { Stack } from "../../layouts/Stack";
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "../../card";
import { Empty, EmptyHeader, EmptyTitle, EmptyDescription, EmptyContent, EmptyMedia } from "../../atoms/Empty";
import { Spinner } from "../../atoms/Spinner";
import { Badge } from "../../atoms/Badge";

/** Default Explorer — shows header, toolbar, sidebar (filters), content (cards),
 *  and inspector (detail preview). Canonical pattern for list/collection pages.
 *  The consumer fills each zone; the archetype owns the layout. */
export const Default: Story = {
  render: () => (
    <SidebarAppShell
      brand={SIDEBAR_RAIL_DEMO_BRAND}
      nav={SIDEBAR_RAIL_DEMO_NAV}
      secondary={SIDEBAR_RAIL_DEMO_SECONDARY}
      user={SIDEBAR_RAIL_DEMO_USER}
    >
      <Explorer
        header={<div className="p-3"><h2 className="text-section-heading">Contracts</h2></div>}
        toolbar={<div className="flex gap-2 p-2" />}
        sidebar={<Stack gap="2" className="p-3"><p className="text-sm font-medium">Filters</p></Stack>}
        content={
          <Stack gap="4">
            {CONTRACTS.map(c => (
              <Card key={c.id}>
                <CardHeader><CardTitle>{c.name}</CardTitle></CardHeader>
                <CardContent>{c.description}</CardContent>
              </Card>
            ))}
          </Stack>
        }
        inspector={<Stack gap="2" className="p-3"><p className="text-sm font-medium">Details</p></Stack>}
      />
    </SidebarAppShell>
  ),
};
```

### Demo data

Use realistic production-like data from `features/chrome/demo-data.ts`:

```ts
import {
  SIDEBAR_RAIL_DEMO_BRAND,
  SIDEBAR_RAIL_DEMO_NAV,
  SIDEBAR_RAIL_DEMO_SECONDARY,
  SIDEBAR_RAIL_DEMO_USER,
} from "../../features/chrome/demo-data";
```

And define story-local content data (contracts list, entities, etc.) with realistic
values — never `id: 1`, `name: 'Test'`.

---

## Guardrails — what catches what

Archetypes live in `packages/ui/`, which is NOT scanned by consumer-facing ESLint rules
or CI scripts. The guardrail stack for archetypes is:

| Gate | What it catches | Reliability |
|---|---|---|
| **TypeScript** (`tsc --noEmit`) | `variant="base"`, `gap="12"`, mismatched Surface variant | ✅ Catches invalid CVA variants at compile time |
| **Storybook chromatic diff** | Visual regressions from layout changes | ✅ Catches unintended visual changes |
| **Registry audit** (`audit:components`) | Missing `@registry` metadata | ✅ Catches unregistered components |
| **Code review** | `min-h-[*vh]`, raw `<div>` with layout tokens | ❌ Manual — not automated for packages/ui/ |
| **`check-viewport-heights.mjs`** | `min-h-[*vh]` in `apps/platform/` only | ❌ Does not scan packages/ui/ |

**Practical takeaway:** TypeScript is the primary automated gate for archetypes. The
component author must validate correctness manually for layout structure. That's why the
Storybook pattern matters — visual review in the browser catches what auto-gates miss.

---

## Gotchas

1. **`variant="base"` on Surface is always wrong.** Surface's variant union does not include
   `"base"`. If you see it, the author meant `"white"`. TypeScript will reject it.

2. **Stories MUST be co-located in the archetype directory.** Storybook config glob is
   `../src/**/*.stories.@(ts|tsx)` — putting stories in `recipes/archetypes/` for the
   component, they load from `src/recipes/archetypes/`. But the archetype source lives
   in `src/features/archetypes/`. Keep the story next to the source for maintainability.

3. **The org's stories exist in `recipes/archetypes/`** already (ArchetypeExplorer,
   ArchetypeDetail, ArchetypeCanvas). These are the "produce once" reference. The new
   archetype factories in `features/archetypes/` should have their own stories for
   component-specific states, while the recipe stories show full-page patterns (wrapped
   in chrome with sidebar nav).

4. **SidebarAppShell wraps the archetype in a full chrome.** If you nest a story inside
   SidebarAppShell, set `parameters: { layout: "fullscreen" }` — otherwise the chrome
   renders inside a centered preview panel with no height.

5. **Lazy import checks.** The `Unused import Surface` lint error appears if Surface is
   imported but not used in the file — this happens when all zones are optional and a
   story passes only `content`. The import is conditionally used; keep it.

6. **`withChrome` vs SidebarAppShell.** `withChrome` is for layout primitives stories
   (Container, Grid, Stack) that need chrome context. `SidebarAppShell` is for archetype
   stories that need a full app shell (sidebar nav + chrome). Use SidebarAppShell for
   archetypes.

7. **The archetype is a factory, not a page.** Consumers import it and fill its slots.
   Don't add page-level concerns (data fetching, routing, auth) to the archetype. Those
   belong in `FeatureView.tsx`.

---

## References

- `src/features/archetypes/explorer/Explorer.tsx` — the Explorer factory (canonical)
- `src/features/archetypes/explorer/Explorer.types.ts` — Explorer props type
- `src/recipes/archetypes/ArchetypeExplorer.stories.tsx` — canonical Explorer recipe stories
- `src/recipes/archetypes/ArchetypeDetail.stories.tsx` — canonical Detail recipe stories
- `src/recipes/archetypes/ArchetypeCanvas.stories.tsx` — canonical Canvas recipe stories
- `src/features/chrome/SidebarAppShell/SidebarAppShell.tsx` — chrome wrapper for stories
- `src/features/chrome/demo-data.ts` — shared demo nav/brand/user
- `src/atoms/Surface/Surface.styles.ts` — Surface variant union (validate variant names here)
- `.pi/skills/sk-ui-layout/SKILL.md` — composing page regions from Container/Stack/Grid/Surface
- `.pi/skills/sk-storybook-component-testing/SKILL.md` — general Storybook story rules
- `.pi/docs/agent-guide.md` — project conventions, decorator patterns, a11y config