---
name: sk-ui-consumer-page-skeleton
description: >-
  Build a reusable page skeleton for the Analygo Platform following the
  canonical four-layer layout hierarchy (RootLayout → route-group → archetype/per-route layout → page).
  Use when creating a new route, page, or layout in apps/platform; when
  composing a page from Container → Stack → Grid → Card; when deciding which
  archetype (Explorer, Detail, Canvas) a page needs; when building a
  *View.tsx orchestrator; or when requested to "sketch a page layout",
  "define a page skeleton", "set up a route", "create the page structure",
  or "layout the page regions". Also use when reviewing an existing page
  for structural violations like hand-rolled chrome or missing archetype use.
  NOT for building @analygo/ui atoms or molecules themselves (see sk-ui-build),
  NOT for writing domain feature section content (see sk-ui-consumer-feature),
  and NOT for general React/Next.js routing knowledge.
license: MIT
compatibility: "@analygo/ui · Next.js 16 · apps/platform"
metadata:
  version: "1.0"
  applies_to: "apps/platform/app/"
---

# define-page-skeleton — Analygo Platform Page Skeleton Builder

## Gotchas

### The layout stack must be followed bottom-up, not chosen top-down

Do NOT start with Container and work outward. Start with the **route structure**
(app layout hierarchy), then the **archetype** (if three-zone), then the **page
region composition** (Container → Stack → Grid), then the **choice of atoms**
to fill each slot. Each layer constrains the ones below it.

```
Route structure  →  Archetype?  →  Region composition  →  Atom selection
     ↓                    ↓                ↓                     ↓
   app/layout        Explorer/Detail    Container→Stack→      Card, Badge,
   (app)/layout      /Canvas?           Grid→Surface          Button, Field
```

Skipping the archetype decision is the most common mistake. If the page has
a sidebar | content | inspector pattern, it needs Explorer — NOT hand-rolled
`<div className="flex">` with max-w-/w-60 utilities.

### Chrome owns chrome; Container owns width; Surface owns paint

These three ownerships are the most common source of violations:

| Concern | Owned by | If you're writing this... |
|---|---|---|
| Sidebar, topbar, main-content slot | `Chrome` from `@analygo/ui/features/chrome` | `<div className="flex min-h-dvh">` → violation |
| Max-width + centering + edge padding | `Container` from `@analygo/ui/layouts` | `mx-auto max-w-7xl px-6` → violation |
| Vertical gap between children | `Stack` from `@analygo/ui/layouts` | `space-y-*` or `flex flex-col gap-*` → violation |
| Background tint + border + glow on a card/panel | `Surface` from `@analygo/ui/atoms` | `<div className="rounded-xl bg-muted border p-6">` → violation |
| Background tint on a full-bleed page region | `HeroSurface` from `@analygo/ui/atoms` | `bg-gradient-to-r` hero band → violation |
| Internal card padding | `Card` from `@analygo/ui/card` | `<div className="rounded-lg border p-6">` → violation |

### Container is NOT optional in page regions

Every page region must start with a Container. The only exception is the
three-column flex row inside an Explorer archetype (sidebar | content | inspector),
which deliberately uses a raw `<div>` because no primitive handles asymmetric
column widths with independent overflow-y per column.

If you write `mx-auto max-w-7xl px-6` anywhere in a consumer file, you're
hand-rolling what Container provides. Same goes for `w-full` on a page region
that should use Container.

### Three-zone = Explorer; detail/record = Detail; full-bleed canvas = Canvas

These three archetypes from `@analygo/ui` cover the vast majority of page shapes:

| Page shape | Archetype | Zones |
|---|---|---|
| List/search with inspector | Explorer | header + toolbar + [sidebar | content | inspector] + footer |
| Record/detail with tabs | Detail | breadcrumbs + heading + actions + metadata + tabs + content |
| Full-bleed interactive area | Canvas | toolbar + full-bleed canvas + status bar |

If the page fits one of these, use the archetype directly in the *View.tsx.
Do NOT hand-roll the zone layout. Each archetype is a Storybook-verified
factory component with typed props for every zone slot.

### page.tsx is 20 lines max — data fetching goes in *View.tsx

If page.tsx has data fetching, useQuery calls, or business logic, it's wrong.
Move that to `{RouteName}View.tsx` (client component) or its hooks/.
page.tsx should only import Suspense and the View component.

---

## Procedure

### Step 1 — Determine route structure

```
apps/platform/app/                        ← RootLayout (HTML shell, providers)
  (app)/                                  ← Route-group layout (Chrome, auth, sidebar)
    {route-name}/                         ← New route directory
      page.tsx                            ← SSR entry (20 lines, Suspense only)
      {RouteName}View.tsx                 ← Client orchestrator (data hooks + layout)
      components/                         ← Feature section components
      hooks/                              ← Data-fetching hooks
```

1. Create the directory: `apps/platform/app/(app)/{route-name}/`
2. Check if a per-route `layout.tsx` is needed — only if the route needs a different
   chrome variant or route-specific context providers. Otherwise skip it.
3. Create `page.tsx` as a server component with Suspense + View import.
4. Create `{RouteName}View.tsx` as a client component.
5. Create empty `components/` and `hooks/` directories.

**Checklist:**
- [ ] Does the route need a different chrome variant than (app)/layout.tsx?
- [ ] If yes: create `layout.tsx` that wraps children in the variant
- [ ] If no: no per-route layout needed

### Step 2 — Choose the right archetype or composition shape

```
What kind of page is this?
  ├── Sidebar + content + inspector (three-zone)?
  │     → Use Explorer archetype from @analygo/ui
  ├── Record/detail with tabs and metadata?
  │     → Use Detail archetype from @analygo/ui
  ├── Full-bleed interactive canvas with toolbar?
  │     → Use Canvas archetype from @analygo/ui
  └── Simple single-column page (settings, profile)?
        → Compose manually from Container → Stack → Card
```

**Load `sk-ui-archetypes` if the page fits two or three zones.**

### Step 3 — Compose page regions

For each page region, follow this exact nesting:

```
<HeroSurface tone="muted" height="auto">    ← optional; only for full-bleed paint (hero, accent, muted band)
  <Container width="7xl">                   ← REQUIRED; owns width + centering + padding
    <Stack gap="6">                         ← REQUIRED; owns vertical rhythm
      <Card>                                ← or Grid, Surface, /Heading/Text
        <CardHeader>
          <Stack gap="2">
            <CardTitle>…</CardTitle>
            <CardDescription>…</CardDescription>
          </Stack>
        </CardHeader>
        <CardContent>
          <Stack gap="4">
            <Field>…</Field>
            <MetaRow>…</MetaRow>
          </Stack>
        </CardContent>
      </Card>
    </Stack>
  </Container>
</HeroSurface>
```

**Rules:**
- `Container` is always the outer frame of a region
- `Stack` is always the direct child of Container
- Add `Grid cols={N}` between Stack and Card for columnar data
- Add `Surface variant="…"` around a region for per-item paint only
- **Never** put `border`, `bg-*`, `rounded`, `shadow`, or `p-*` on a Stack
- **Never** wrap Container inside anything that constrains its width

### Step 4 — Fill zones with content

Zone content follows the `sk-ui-consumer-guide` contracts:

| Instead of | Use |
|---|---|
| `<h2 className="text-lg font-semibold">` | `<Heading level="h2">` |
| `<p className="text-sm font-medium text-muted-foreground">` | `<Text preset="body-sm">` or `FieldLabel` |
| `<label> + <Input> + error <p>` | `<Field>` molecule |
| `z.object({...})` in component | Schema in `@analygo/contracts` |
| hand-rolled status pill | `BillingStatusBadge` / `StatusBadge` |
| `flex flex-col gap-*` or `space-y-*` | `<Stack gap="*">` |
| `grid grid-cols-*` for data | `<Grid cols={N}>` or `<Table>` |
| `animate-pulse` placeholder | `<Skeleton className="...">` |
| `Loader2` centered spinner | `<Skeleton>` placeholders |
| `AppIcon` | `<Icon icon={…}>` from lucide-react |
| `border-b border-border` separator | `<Separator />` |

### Step 5 — Write page.tsx (20 lines max)

```tsx
// apps/platform/app/(app)/{route-name}/page.tsx
import { Suspense } from "react";
import { Skeleton } from "@analygo/ui/skeleton";
import { RouteNameView } from "./RouteNameView";

export default function RouteNamePage() {
  return (
    <Suspense fallback={<Skeleton className="h-96 w-full rounded-xl" />}>
      <RouteNameView />
    </Suspense>
  );
}
```

- Server component (no `"use client"`)
- Only Suspense + View import + optional Skeleton fallback
- No data fetching, no styles, no layout, no business logic

### Step 6 — Write *View.tsx (100-200 lines)

```tsx
"use client";

import { Container } from "@analygo/ui/layouts";
import { Stack } from "@analygo/ui/layouts";
import { Grid } from "@analygo/ui/layouts";
import { Skeleton } from "@analygo/ui/skeleton";
import { Heading } from "@analygo/ui/heading";
// import data hooks from ./hooks
// import feature sections from ./components

export function RouteNameView() {
  // 1. Call data hooks
  const { data, isLoading, error } = useRouteData();

  // 2. Handle error state
  if (error) {
    return (
      <Container width="7xl">
        <Stack gap="3" align="center" className="py-20 text-center">
          <p className="text-destructive text-sm">Failed to load data</p>
        </Stack>
      </Container>
    );
  }

  // 3. Handle loading state with Skeleton
  if (isLoading || !data) {
    return (
      <Container width="7xl">
        <Stack gap="6" className="py-8">
          <Skeleton className="h-48 w-full rounded-xl" />
          <Skeleton className="h-64 w-full rounded-xl" />
        </Stack>
      </Container>
    );
  }

  // 4. Main content: Container → Stack → { sections }
  return (
    <Container width="7xl">
      <Stack gap="6">
        <Heading level="h2">Page Title</Heading>
        {/* Feature sections go here as props-receiving components */}
      </Stack>
    </Container>
  );
}
```

- `"use client"` — always a client component
- Uses `@analygo/ui` layout primitives exclusively
- Data hooks called at the View level, not in feature sections
- Error/loading/empty states handled before main content
- Feature sections imported from `./components` receive typed props

### Step 7 — Audit before committing

Before finalizing the page skeleton:

```typescript
// Call these tools to verify:
// 1. depcruise_check_import — for every new import added
// 2. review_layout — scan the page files for pattern violations
// 3. audit_ui — run the real ESLint rules against the new files
```

Check specifically for:
- [ ] No hand-rolled chrome (`<div className="flex min-h-dvh">`)
- [ ] No Container wrapping another Container
- [ ] No space-y-* or flex flex-col gap-* (use Stack)
- [ ] No mx-auto / max-w-* (use Container)
- [ ] No font-semibold / font-bold (use Heading/Text)
- [ ] No raw hex colors
- [ ] No bare `border` without a border-color token
- [ ] Import paths use `@analygo/ui/<subpath>` not root barrel
- [ ] Component files don't import from other features' components/ or lib/
- [ ] page.tsx ≤ 20 lines, no data fetching
- [ ] *View.tsx handles error/loading/empty states

---

## Output Format

When asked to "define a page skeleton", produce:

1. **Route structure** — directory layout under `apps/platform/app/(app)/{route}/`
2. **Archetype decision** — which archetype (Explorer/Detail/Canvas) or manual composition
3. **page.tsx** — complete SSR entry file
4. **{RouteName}View.tsx** — complete client orchestrator with Container → Stack → Grid composition
5. **Audit checklist** — what to verify before committing

If the user wants a single region (not a full page), output just the
Container → Stack → Grid → Card nesting for that region with the archetype
decision noted.

---

## Examples

### Example 1: Settings page (single-column, no archetype)

```
Route: apps/platform/app/(app)/settings/
Archetype: none (simple single-column)
```

```tsx
// page.tsx
import { Suspense } from "react";
import { SettingsView } from "./SettingsView";

export default function SettingsPage() {
  return (
    <Suspense fallback={<div className="min-h-[400px]" />}>
      <SettingsView />
    </Suspense>
  );
}

// SettingsView.tsx
"use client";
import { Container } from "@analygo/ui/layouts";
import { Stack } from "@analygo/ui/layouts";
import { Heading } from "@analygo/ui/heading";
import { Text } from "@analygo/ui/text";

export function SettingsView() {
  return (
    <Container width="7xl">
      <Stack gap="6">
        <Heading level="h2">Settings</Heading>
        <Tabs defaultValue="profile">
          <TabsList variant="line">
            <TabsTrigger value="profile">Profile</TabsTrigger>
          </TabsList>
          <TabsContent value="profile">
            <Stack gap="6">
              <Card>
                <CardHeader>
                  <Stack gap="2">
                    <CardTitle>Your Account</CardTitle>
                    <CardDescription>Profile information</CardDescription>
                  </Stack>
                </CardHeader>
                <CardContent>
                  <Field>{/*...*/}</Field>
                </CardContent>
              </Card>
            </Stack>
          </TabsContent>
        </Tabs>
      </Stack>
    </Container>
  );
}
```

### Example 2: Workspace page with sidebar (Explorer archetype)

```
Route: apps/platform/app/(app)/workspace/
Archetype: Explorer (sidebar | content | inspector)
```

```tsx
// page.tsx
import { Suspense } from "react";
import { WorkspaceView } from "./WorkspaceView";

export default function WorkspacePage() {
  return (
    <Suspense fallback={<div className="min-h-[600px]" />}>
      <WorkspaceView />
    </Suspense>
  );
}

// WorkspaceView.tsx
"use client";
import { Explorer } from "@analygo/ui/archetypes";
import { Container } from "@analygo/ui/layouts";
import { Stack } from "@analygo/ui/layouts";
// import feature sections...

export function WorkspaceView() {
  return (
    <Container width="full">
      <Stack gap="0">
        {/* Header zone — optional */}
        {/* Three-column zone via Explorer */}
        <Explorer
          sidebar={<WorkspaceSidebar />}
          content={
            <Stack gap="6">
              <WorkspaceContent />
            </Stack>
          }
          inspector={<WorkspaceInspector />}
        />
      </Stack>
    </Container>
  );
}
```

---

## When things go wrong

| Symptom | Likely cause | Fix |
|---|---|---|
| ESLint reports `no-handrolled-stack` | Used `flex flex-col gap-*` or `space-y-*` | Replace with `<Stack gap="*">` |
| ESLint reports `no-shell-tier-mismatch` | Hand-rolled `mx-auto max-w-*` | Wrap in `<Container width="*">` |
| ESLint reports `no-hardcoded-font-weight` | `font-semibold`/`font-bold` on heading/text | Use `<Heading level="h*">` or `<Text preset="*">` |
| ESLint reports `no-handrolled-badge` | Hand-rolled status pill span | Use `<Badge>` or `BillingStatusBadge` |
| Depcruise reports `app-no-ui-root-barrel` | `import { X } from "@analygo/ui"` | Use `@analygo/ui/<subpath>` |
| Depcruise reports `app-no-deep-ui-internals-import` | Importing from `packages/ui/src/` | Use `@analygo/ui/<public-export>` |
| Depcruise reports `app-feature-boundaries` | Importing from other feature's `components/` | Import from public API (index.ts/types.ts) |
| Page looks wrong at mobile widths | Missing Container wrapper | Add `<Container width="full">` |

## Related skills

| Skill | When to load |
|---|---|
| `sk-ui-consumer-page-layout` | Understanding the 4-layer Next.js layout hierarchy, the page.tsx → *View.tsx pattern, route-group layout decisions |
| `sk-ui-layout` | Full Container/Stack/Grid/Surface/HeroSurface API docs, responsive behavior, composition hierarchy |
| `sk-ui-consumer-guide` | Token contracts, import paths, ESLint/depcruise guardrails, component selection |
| `sk-ui-archetypes` | Explorer/Detail/Canvas factory component props and zone slots |
| `sk-ui-consumer-feature` | Building the domain-specific feature sections that fill the page skeleton's slots |