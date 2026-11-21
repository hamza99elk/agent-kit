---
name: sk-ui-consumer-page-layout
description: >-
  Build, review, or refactor consumer page layouts in the Analygo Platform
  (apps/platform). Covers the Next.js layout hierarchy (root → route-group →
  per-route → page), the page.tsx → *View.tsx → components/ assembly pattern,
  app-owned layout components (WorkspaceSettings, page orchestrators), and
  the boundary between app-owned layout and shared @analygo/ui layout primitives.
  Use when creating or editing any page.tsx, layout.tsx, *View.tsx, or
  route-group layout in apps/platform. Also use when deciding what goes in
  (app)/layout.tsx vs a page-level layout component.
  NOT for using Container/Stack/Grid/Surface (see sk-ui-layout), NOT for
  choosing which @analygo/ui component to fill a slot (see sk-ui-consumer-guide),
  and NOT for building domain feature sections (see sk-ui-consumer-feature).
license: MIT
metadata:
  version: "1.0"
---

# Analygo Platform — Consumer App Layout

## Purpose and Boundary

This skill is about **how the consumer app owns page-level structure using Next.js routing**, not about how to use layout primitives. The distinction:

| Concern | Owner | Skill |
|---|---|---|
| Next.js route hierarchy (layout.tsx → page.tsx) | Consumer app | **← this skill** |
| App-owned page assembly (page.tsx → *View.tsx → components/) | Consumer app | **← this skill** |
| App-level layout components (chrome orchestration, page orchestrators) | Consumer app | **← this skill** |
| Using Container/Stack/Grid/Surface/HeroSurface | `@analygo/ui` | `sk-ui-layout` |
| Choosing which @analygo/ui component to use in a slot | `@analygo/ui` | `sk-ui-consumer-guide` |
| Building domain feature sections with state contracts | Consumer feature | `sk-ui-consumer-feature` |

**Apply `sk-ui-consumer-guide` and `sk-ui-layout` alongside this skill** — they cover the layout primitives and component selection rules. This skill covers the app-level orchestration layer that owns *which* primitives compose *where*.

NOT related to `sk-ui-layout`'s five-layer architecture — that model is about the *component* stack (page → feature view → components → hooks → lib). This skill is about the *routing* stack (app/ → (app)/ → route/ → page).

---

## 1. The Next.js Layout Hierarchy (4 Layers)

Every page in the platform passes through exactly four layers of layout nesting:

```
Layer 1:  apps/platform/app/layout.tsx        RootLayout
Layer 2:  apps/platform/app/(app)/layout.tsx  Route-group chrome
Layer 3:  apps/platform/app/(app)/{route}/layout.tsx   Per-route layout (rare)
Layer 4:  apps/platform/app/(app)/{route}/page.tsx     Page entry point
```

### Layer 1: RootLayout (`app/layout.tsx`)

**Responsibilities:** HTML shell, providers, fonts, global CSS.
**Owns:** `<html>`, `<body>`, ThemeProvider, NuqsAdapter, RootProviders, telemetry bootstrap.
**Does NOT own:** Chrome, sidebar, auth gates, page padding, content layout.

```tsx
// app/layout.tsx — server component, minimal
export default function RootLayout({ children }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <ThemeProvider attribute="class" defaultTheme="light" enableSystem>
          <RootProviders>
            {children}
          </RootProviders>
        </ThemeProvider>
      </body>
    </html>
  );
}
```

### Layer 2: Route-group layout (`app/(app)/layout.tsx`)

**Responsibilities:** Auth gates, chrome shell (sidebar + topbar), user menu, org bootstrap.
**Owns:** `Chrome` component from `@analygo/ui/features/chrome`, sidebar content, auth gates, app-level context.
**Does NOT own:** Page content width, page padding, page-level spacing, navigation within the page.

```tsx
// Typical (app)/layout.tsx — client component
export default function AppHomeLayout({ children }) {
  return (
    <BootstrapAndOrgGate>
      <Chrome variant="two-pane"
        primary={<AnalygoSidebar />}
        topbar={<Header><SidebarTrigger /><AppUserMenu /></Header>}
      >
        {children}  {/* <- pages render here */}
      </Chrome>
    </BootstrapAndOrgGate>
  );
}
```

The `Chrome` component provides the sidebar + main content area. Pages render inside the main content slot — they do NOT need to set up sidebar or topbar.

### Layer 3: Per-route layout (`app/(app)/{route}/layout.tsx`)

**Rarely needed.** Only when a route needs route-level context providers or a custom wrapper that differs from the route-group default. The settings route uses a pass-through layout:

```tsx
// app/(app)/settings/layout.tsx — typically empty pass-through
export default function Layout({ children }) {
  return <>{children}</>;
}
```

**Do NOT create a per-route layout unless you need:** route-specific context providers, a different chrome variant, or route-level Suspense boundaries that differ from the route-group default.

### Layer 4: Page entry point (`app/(app)/{route}/page.tsx`)

**Responsibilities:** SSR entry, Suspense boundary, delegates to View component.
**Owns:** Minimal wrappers. 15–20 lines max.
**Does NOT own:** Data fetching, layout composition, rendering logic.

The page file follows the **page.tsx → *View.tsx pattern** (see §2).

---

## 2. The page.tsx → *View.tsx → components/ Pattern

Every non-trivial page follows the same three-part decomposition:

```
page.tsx                          (Layer 4: SSR entry, Suspense, import View)
  └── *View.tsx                   (Layer 5: client composition, data hooks, slot arrangement)
        ├── components/           (Layer 6: feature components, each ~150 lines)
        └── hooks/                (Layer 7: data fetching, state)
```

### page.tsx — SSR entry point

**20 lines max.** Imports the View component, wraps in Suspense. No data fetching, no styles, no logic.

```tsx
// app/(app)/home/page.tsx
import { Suspense } from "react";
import { HomeView } from "./HomeView";

export default function HomePage() {
  return (
    <Suspense
      fallback={
        <div className="flex items-center justify-center min-h-[200px] text-text-muted">
          Loading workspace...
        </div>
      }
    >
      <HomeView />
    </Suspense>
  );
}
```

**Rules:**
- Server component (default — no `"use client"`)
- Only imports the View and Suspense
- Fallback is minimal (can be inline div or a Skeleton import)
- No route-level data fetching in page.tsx — use the View or its hooks

### *View.tsx — client composition orchestrator

**100–200 lines.** The one place in the route that:
1. Calls data hooks (useQuery, useMe, custom hooks)
2. Handles loading/error/empty states at the page level
3. Arranges feature sections using Container → Stack → Grid → Card
4. Passes data down to feature components via props

```tsx
// app/(app)/home/HomeView.tsx
"use client";

import { Container } from "@analygo/ui/container";
import { Stack } from "@analygo/ui/stack";
import { Skeleton } from "@analygo/ui/skeleton";
import { useHomeData } from "./hooks";
import { HeroSection, DecisionSection, EcosystemSection } from "./components";

export function HomeView() {
  const { data, isLoading, error } = useHomeData();

  if (error) {
    return (
      <Container width="7xl">
        <Stack gap="3" align="center" className="py-20 text-center">
          <p className="text-destructive text-sm">Failed to load workspace data</p>
        </Stack>
      </Container>
    );
  }

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

  return (
    <Container width="7xl">
      <Stack gap="6">
        <HeroSection data={data.hero} />
        <DecisionSection items={data.decisions} />
        <Grid cols={3} gap="6">
          <EcosystemSection data={data.ecosystem} />
        </Grid>
      </Stack>
    </Container>
  );
}
```

**Rules:**
- Client component (`"use client"`)
- Uses `@analygo/ui` layout primitives (Container, Stack, Grid) — never hand-rolled layout
- Imports feature sections from `./components`
- Co-located with the route: `app/(app)/{route}/*View.tsx`
- Named `{RouteName}View.tsx` (HomeView, RunsView, SettingsView, etc.)

### components/ — feature section components

Each component is a **domain-specific pure render component** receiving typed props. They use `@analygo/ui` atoms/molecules for visual presentation. See `sk-ui-consumer-feature` for detailed guidance.

---

## 3. App-Owned Layout Components

Some layout concerns are **consumer-owned** and live outside `@analygo/ui`. These are application-level arrangements that know about domain-specific navigation, chrome structure, and page composition.

### What the consumer owns

| Component | Purpose | Where it lives | Example |
|---|---|---|---|
| Route-group chrome wrapper | Auth, sidebar, topbar, org gate | `app/(app)/layout.tsx` | `Chrome` + sidebar |
| App-level navigation | Primary nav items, workspace switcher | `app/(app)/components/` | `AnalygoSidebar` |
| Page-level orchestrator | Data hooks, section arrangement, state handling | `app/(app)/{route}/*View.tsx` | `HomeView`, `RunsView` |
| Route layout (rare) | Per-route wrapper or context | `app/(app)/{route}/layout.tsx` | Pass-through (typically) |

### What the consumer does NOT own

| Concern | Owner | Source |
|---|---|---|
| Layout primitives (Container, Stack, Grid) | `@analygo/ui` | `@analygo/ui/layouts` |
| Surface paint (Surface, HeroSurface) | `@analygo/ui` | `@analygo/ui/atoms` |
| Page chrome shell (Chrome, SidebarAppShell) | `@analygo/ui` | `@analygo/ui/features/chrome` |
| Reusable page archetypes (Explorer, Detail, Canvas) | `@analygo/ui` | `sk-ui-archetypes` |
| Sidebar rail, header, topbar components | `@analygo/ui` | `@analygo/ui/features/chrome` |

**The consumer may compose these in its layout.tsx (choosing chrome variant, providing sidebar content), but must NOT reimplement them.**

### How (app)/layout.tsx owns chrome orchestration

The route-group layout chooses the chrome variant and fills its slots. It does NOT reimplement chrome internals:

```tsx
// ✅ Correct — consumer owns slot content, @analygo/ui owns chrome
export default function Layout({ children }) {
  return (
    <BootstrapAndOrgGate>
      <Chrome variant="two-pane"
        primary={<AnalygoSidebar />}           // consumer-owned nav
        topbar={<Header><SidebarTrigger />
          <AppUserMenu /></Header>}             // consumer-owned user menu
      >
        {children}
      </Chrome>
    </BootstrapAndOrgGate>
  );
}

// ❌ Wrong — reimplementing chrome internals
<div className="flex min-h-dvh">
  <aside className="w-60 bg-muted">...</aside>
  <main className="flex-1">...</main>
</div>
```

---

## 4. When to Create a Page-Level Layout Component

### You need one when:

- The page has a **three-zone layout** (sidebar | content | inspector) — use Explorer archetype
- The page has a **detail/record view** with breadcrumbs, metadata, and tabs — use Detail archetype
- The page has a **full-bleed canvas** with a toolbar — use Canvas archetype
- Multiple routes share the same page structure but differ in chrome variant
- A route needs route-specific context providers (e.g. a WebSocket connection)

### You do NOT need one when:

- The route-group layout already provides the chrome shell
- The page content fits within Container → Stack → Grid
- The route is a single-feature page (just import the feature section in page.tsx)

### Rule of thumb

**If a route needs its own layout component, put it in** `app/(app)/{route}/{RouteName}Layout.tsx` **or use an archetype.** Don't create `app/layouts/{RouteName}Layout.tsx` unless the layout is shared across 2+ routes (and even then, consider whether it belongs in `@analygo/ui`).

---

## 5. Loading State Architecture

### Page-level loading

The page.tsx Suspense boundary handles the SSR → client hydration flash. The *View.tsx handles the data-fetching loading state with skeleton placeholders.

```tsx
// page.tsx — SSR fallback (shows before JS hydrates)
<Suspense fallback={<div>Loading...</div>}>
  <View />
</Suspense>

// *View.tsx — data loading state (shows after JS hydrates)
if (isLoading) return <SkeletonPlaceholder />
```

### Component-level loading

Feature sections receive data as props. They do NOT call data hooks — the View orchestrator does. Individual sections may have local loading states for mutations (button loading, optimistic updates), but not for initial data fetch.

```tsx
// ✅ Correct — View owns data fetching
export function HomeView() {
  const { data, isLoading } = useHomeData();
  if (isLoading) return <HomePageSkeleton />;
  return <HeroSection data={data.hero} />;
}

// ❌ Wrong — feature section fetching its own data
export function HeroSection() {
  const { data } = useHomeData();  // <- duplicate fetch, coupling
}
```

---

## 6. Decision Flow: Building a New Page

When asked to build a new page, follow this flow:

```
1. What route? → app/(app)/{route-name}/
2. Does it need a new route-group layout? → Only if chrome variant differs.
3. Create page.tsx → 20-line SSR entry with Suspense.
4. Create *View.tsx → Client composition with data hooks.
5. Create components/ and hooks/ → Feature sections and queries.
6. Does it need a per-route layout? → Rare. Only for route-specific context.
```

### Concrete checklist

- [ ] Route file structure: `app/(app)/{route}/page.tsx` + `{route}View.tsx` + `components/` + `hooks/`
- [ ] page.tsx is a server component with Suspense only (20 lines max)
- [ ] *View.tsx is a client component that calls data hooks and arranges sections
- [ ] Layout primitives imported from `@analygo/ui/layouts`
- [ ] No hand-rolled chrome, sidebar, or shell structure
- [ ] Loading state uses Skeleton placeholders (not centered spinner)
- [ ] Error state defined in View (not page.tsx)
- [ ] Route-group layout not duplicated per-route unless necessary

---

## 7. Refactoring Guidance

If you see a page violating these patterns:

| Symptom | Likely cause | Fix |
|---|---|---|
| page.tsx has data fetching or business logic | Missing *View.tsx layer | Extract into {RouteName}View.tsx |
| *View.tsx has JSX > 250 lines | Needs component extraction | Split into components/ features |
| Multiple routes duplicate the same Suspense wrapper pattern | Route-group layout | Move up to (app)/layout.tsx |
| Per-route layout.tsx is identical to route-group layout.tsx | Unnecessary nesting | Remove per-route layout, use pass-through |
| Route uses `<div className="flex min-h-dvh">` instead of Chrome | Missing Chrome import | Use `@analygo/ui/features/chrome` |

---

## Related Skills

| Skill | When to use |
|---|---|
| `sk-ui-consumer-guide` | **Apply first** — component selection, token contracts, import paths, lint rules |
| `sk-ui-layout` | Using Container/Stack/Grid/Surface/HeroSurface in the View |
| `sk-ui-consumer-feature` | Building domain-specific feature sections with state contracts |
| `sk-ui-archetypes` | When a page needs a three-zone layout (Explorer, Detail, Canvas) |