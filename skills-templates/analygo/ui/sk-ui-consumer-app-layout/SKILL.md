---
name: sk-ui-consumer-app-layout
description: >-
  Architect and refactor the Next.js App Router layout hierarchy across route
  groups in the Analygo Platform (apps/platform). Covers the root → route-group
  → per-route → page four-layer hierarchy, independent route-group experiences
  (auth, platform, onboarding), the boundary between Next.js layout ownership
  and @analygo/ui shell components, and how to avoid conditional chrome via
  route-group isolation. Use when creating or evaluating route-group layouts,
  deciding whether a shell belongs in @analygo/ui or the consumer app, reviewing
  a layout refactoring PR, or diagnosing layout issues like auth pages inheriting
  sidebar chrome. NOT for the page.tsx → *View.tsx → components/ assembly
  pattern (see sk-ui-consumer-page-layout), NOT for using Container/Stack/Grid
  (see sk-ui-layout), and NOT for choosing which @analygo/ui component fills a
  slot (see sk-ui-consumer-guide).
license: MIT
compatibility: "@analygo/ui · Next.js 16 (App Router) · apps/platform"
metadata:
  version: "1.0"
  applies_to: "apps/platform/app/"
---

# Analygo Platform — App Layout Architecture

## Core Principle

**Route groups are independent experiences. Do not share a single AppShell with
pathname checks to conditionally hide the sidebar.** Each route group owns its
own visual shell.

```
app/
├── layout.tsx                  # Root: html, body, global providers (no chrome)
├── (auth)/layout.tsx           # AuthShell: centered form, brand logo, no nav
├── (platform)/layout.tsx       # AppShell: sidebar, topbar, workspace chrome
├── (onboarding)/layout.tsx     # OnboardingShell: step indicator, focused flow
└── (standalone)/layout.tsx     # MinimalShell: invite token pages
```

This gives you independent visual experiences **without introducing conditional
rendering** into any layout.

---

## 1. The Three Responsibilities

| Level | What it owns | Code location |
|---|---|---|
| **Root layout** | HTML shell, global providers, fonts, CSS | `app/layout.tsx` |
| **Route-group layout** | Auth gates, chrome shell, session, app-level context | `app/(group)/layout.tsx` |
| **Page component** | SSR entry, Suspense boundary | `app/(group)/{route}/page.tsx` |

### Root layout — keep it minimal

The root layout provides the HTML document shell and global infrastructure.
It does NOT add chrome, sidebar, auth gates, or page-level content width.

```tsx
// app/layout.tsx — minimal root layout
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

| ✅ Root owns | 🚫 Root does NOT own |
|---|---|
| `<html>`, `<body>` | Sidebar, topbar, nav |
| ThemeProvider | Auth session checks |
| Global providers (React contexts) | Centered form layout |
| Font preconnects, global CSS | Workspace navigation |
| Telemetry bootstrap | Page content width or padding |

### Route-group layout — owns the experience

Each route group has its own layout that owns the visual shell for that
experience. This is where auth gates, chrome variants, and session checks
live.

```tsx
// app/(platform)/layout.tsx — platform experience with chrome
export default async function PlatformLayout({ children }) {
  const session = await requireSession();
  return (
    <AppShell>
      <AppSidebar />
      <AppMain>{children}</AppMain>
    </AppShell>
  );
}

// app/(auth)/layout.tsx — auth experience, centered, no nav
export default async function AuthGroupLayout({ children }) {
  const session = await getSession();
  if (session) redirect("/workspace");
  return <AuthShell>{children}</AuthShell>;
}
```

### Page component — thin SSR entry

The page is just the SSR entry point. It does NOT set up chrome, layout,
or visual shells — those come from the route-group layout.

```tsx
// app/(auth)/auth/login/page.tsx
"use client";
import { Auth } from "@analygo/ui/auth";

export default function LoginPage() {
  return <Auth view="signIn" />;
}
```

---

## 2. Where Visual Shells Live

### In @analygo/ui/shells/ — reusable visual experiences

Any visual shell that is shared across routes should live in
`@analygo/ui/shells/`. Examples:

| Shell | Purpose | Example use |
|---|---|---|
| `AuthShell` | Centered form, brand logo, constrained width, no nav | Login, signup, forgot-password, reset-password, verify-email |
| `AppShell` | Sidebar + topbar + content area, full chrome | Dashboard, sources, contracts, settings |
| `OnboardingShell` | Step progress indicator, focused content | Setup wizard, first-run flow |
| `MinimalShell` | Bare content, no nav or sidebar | Invite token pages, shared links |

### In app/ route-group layout — routing and session ownership

Next.js route groups own **routing decisions and session enforcement**,
not visual shells. The visual shell is imported from `@analygo/ui/shells`.
This separation means:

- `@analygo/ui` does NOT know about Next.js route groups, redirects, or sessions
- The consumer app does NOT reimplement visual chrome — it composes from shells

```tsx
// ✅ Correct — layout imports shell, owns routing
import { AuthShell } from "@analygo/ui/shells";

export default function AuthLayout({ children }) {
  // routing & session logic only
  return <AuthShell>{children}</AuthShell>;
}

// ❌ Wrong — layout reimplementing visual chrome
<div className="flex min-h-dvh items-center justify-center">
  <div className="max-w-sm mx-auto py-12 px-4">
    {children}
  </div>
</div>
```

### Shell implementation pattern

Shells are thin visual wrappers. They do not fetch data, check sessions,
or know about routing.

```tsx
// packages/ui/src/shells/AuthShell/AuthShell.tsx
"use client";

import { Container } from "@analygo/ui/layouts";
import { Stack } from "@analygo/ui/layouts";
import { AnalygoLogo } from "@analygo/ui/tokens";

export function AuthShell({ children, className }) {
  return (
    <div className="flex min-h-dvh flex-col items-center justify-center bg-background">
      <Container width="sm" className="py-[var(--space-12)]">
        <Stack gap="8" align="center">
          <AnalygoLogo width={48} height={48} className="shrink-0" />
          {children}
        </Stack>
      </Container>
    </div>
  );
}
```

---

## 3. What NOT to Do

### ❌ One global AppShell with pathname checks

```tsx
// ❌ Wrong — conditional chrome is brittle
export default function Layout({ children }) {
  const path = headers().get("x-pathname");
  if (path.startsWith("/auth")) {
    return <CenteredForm>{children}</CenteredForm>;  // hiding chrome
  }
  return <AppShell>{children}</AppShell>;
}
```

This is brittle because: pathname checks grow stale, every route group
pays the cost of the full AppShell even when it's not shown, and you
cannot have independent loading/error states per experience.

### ❌ A layout per page

```tsx
// ❌ Wrong — unnecessary per-page layout
app/(auth)/auth/login/layout.tsx   // ← subtle centering
app/(auth)/auth/signup/layout.tsx   // ← different padding
```

Route-group layouts exist at the `(group)` level, not per page. If two
pages need different chrome, they belong in different route groups or
the route-group layout handles the variation (e.g., auth pages all
get AuthShell).

### ❌ Reimplementing shells in the consumer app

```tsx
// ❌ Wrong — consumer reimplementing what belongs in @analygo/ui
// app/(auth)/layout.tsx
export default function Layout({ children }) {
  return (
    <div className="flex min-h-dvh flex-col items-center justify-center bg-background py-12">
      <Logo />
      {children}
    </div>
  );
}
```

If the same centered layout appears on login, signup, forgot-password,
and reset-password, extract it as `AuthShell` in `@analygo/ui/shells/`.

---

## 4. Decision Flow

When designing a new route group or diagnosing a layout issue:

```
1. Does this route represent a fundamentally different experience from
   existing route groups (different chrome, navigation, or visual density)?
   → Create a new route group: app/(new-group)/

2. Does the new experience need a reusable visual shell?
   → Add to @analygo/ui/shells/ (e.g., AuthShell, OnboardingShell)

3. What routing decisions does the route-group layout own?
   → Session checks, redirects, auth gates — NOT visual chrome

4. Does a specific journey need a different chrome variant within the
   same route group (e.g., settings has secondary nav)?
   → Consider nested route groups, not per-route layouts

5. Is a new shell reusable across 2+ route groups?
   → Yes: @analygo/ui/shells/
   → No: can remain consumer-owned, but consider if it's truly route-group-specific
```

---

## 5. Concrete: The Auth Shell We Built

The auth route group (`(auth)`) owns:

- **Session check**: redirect authenticated users to `/workspace`
- **AuthShell composition**: import from `@analygo/ui/shells` to provide centered layout + brand

The auth pages own:

- **Auth form content**: `Auth view="signIn"` from `@analygo/ui/auth`
- **No visual layout**: no padding, no centering, no width constraints

The root layout:

- **Global providers only**: fonts, CSS, ThemeProvider, NuqsAdapter
- **No chrome**: no sidebar, no centering, no auth logic

### File structure

```
app/layout.tsx                     # Root: html, body, providers (no chrome)
app/(auth)/layout.tsx              # Route-group: session check + AuthShell
app/(auth)/auth/login/page.tsx     # Page: "use client" + Auth view="signIn"
app/(auth)/signup/page.tsx         # Page: "use client" + Auth view="signUp"
app/(auth)/forgot-password/page.tsx
app/(auth)/reset-password/page.tsx

packages/ui/src/shells/AuthShell/
├── AuthShell.tsx                  # Centered viewport + brand logo + Container
├── AuthShell.types.ts             # Props type (isolated for god-file rule)
└── index.ts                       # Barrel export

packages/ui/src/shells/index.ts    # Re-exports AuthShell in @analygo/ui/shells
```

### Keys to get right

- **AuthShell.types.ts is separate** — the god-file rule bans value+type exports
  in the same file. Types go in a `-types.ts` companion.
- **AuthShell uses Container not hand-rolled max-w** — Container is the
  Level-2 horizontal primitives. Hand-rolled `max-w-sm mx-auto px-4` is
  banned.
- **AuthShell uses Stack not flex-col** — Stack is the Level-2 vertical
  primitive. `flex flex-col gap-4` is banned.
- **Brand logo uses AnalygoLogo from @analygo/ui/tokens** — not a raw SVG
  or external image reference.
- **No `"use server"` in the shell** — shells are client components.
  Server-side session logic stays in the route-group layout.

---

## 6. Related Skills

| Skill | When to apply |
|---|---|
| `sk-ui-consumer-page-layout` | page.tsx → *View.tsx → components/ assembly pattern |
| `sk-ui-layout` | Using Container/Stack/Grid/Surface/HeroSurface |
| `sk-ui-consumer-guide` | Component selection, token contracts, import rules |
| `sk-ui-consumer-feature` | Building domain feature sections with state contracts |
| `sk-ui-build` | Building or editing @analygo/ui components themselves |