---
name: sk-route-consolidation
description: "Consolidate Next.js App Router pages into Route Groups ((auth), (public), (app)) — detect duplicate routes, create route-group layouts, relocate pages without breaking URLs, replace client redirects with next.config redirects(), clean dead prototypes. Use when cleaning up app/ directory sprawl or onboarding to a Next.js 16 project."
---

# Route Consolidation (Next.js App Router)

## When to use this skill

- `app/` directory has scattered pages at both root level and inside route groups like `(auth)/`, `(public)/`, `(app)/`
- Build fails with: `"You cannot have two parallel pages that resolve to the same path"`
- You need to move pages between route groups without breaking URLs
- You want to replace a client-side redirect component (`useEffect` → `window.location.replace`) with a server-side `redirects()` in `next.config`

## Core rules

1. **Route groups are invisible in the URL.** `(auth)/login` and `login` both resolve to `/login`.
2. **Duplicate paths cause build failures.** Two files resolving to the same URL path will crash the build.
3. **Layouts cascade — nearest layout wins.** A page inside `(auth)/forgot-password` gets `(auth)/layout.tsx`, not `app/layout.tsx` (unless `(auth)` has no layout).
4. **URLs must not change when moving pages between groups.** The file moves; the URL stays the same.

## Canonical route group structure

```
app/
├── layout.tsx                          # Root: HTML shell, providers, fonts
├── (app)/                              # Authenticated (auth gate + sidebar)
│   ├── layout.tsx                      #   Auth check + sidebar shell
│   ├── page.tsx                        #   / (dashboard)
│   ├── {feature}/                      #   /{feature}
│   └── checkout/                       #   Payment/billing flow
├── (auth)/                             # Auth pages (card layout, redirect-if-authenticated)
│   ├── layout.tsx                      #   Auth card shell + redirect guard
│   ├── auth/login/                     #   /auth/login — login form
│   ├── forgot-password/                #   /forgot-password
│   ├── reset-password/                 #   /reset-password
│   ├── signup/                         #   /signup
│   └── verify-email/[token]/           #   /verify-email/:token
├── (public)/                           # Public/info pages (minimal layout, no auth gate)
│   ├── layout.tsx                      #   Minimal layout (optional)
│   ├── audit/free/                     #   /audit/free
│   ├── data-deletion/                  #   /data-deletion
│   ├── terms/                          #   /terms
│   └── try/[token]/                    #   /try/:token
└── bare/                               # Unstyled embed views
```

## Workflow

### Step 1 — Detect duplicate routes

```bash
npx next build --turbo 2>&1 | grep -i "duplicate\|parallel pages\|cannot have two"
```

This catches all path conflicts in one pass.

### Step 2 — Identify canonical home for each page

| Route belongs in… | Layout | Auth gate | Examples |
|---|---|---|---|
| `(app)` | Full sidebar+topbar chrome | Yes | dashboard, workspace, settings, runs, targets |
| `(auth)` | Centered card (or none) | Yes (redirect if authed) | login, signup, forgot-password, verify-email |
| `(public)` | Minimal / none | No | terms, data-deletion, audit/free, try |
| `bare/` | None (unstyled) | No | embed views |

### Step 3 — Create missing route-group layouts

```ts
// (auth)/layout.tsx — redirect authenticated users away, wrap in card shell
import { redirect } from "next/navigation";
import { headers } from "next/headers";

export default async function AuthLayout({ children }) {
  const h = await headers();
  if (h.get("cookie")?.includes("better-auth-session")) redirect("/workspace");
  return <>{children}</>;
}
```

```ts
// (public)/layout.tsx — minimal pass-through (no gate needed)
export default function PublicLayout({ children }) {
  return <>{children}</>;
}
```

### Step 4 — Move pages into route groups

Use `mv` with absolute paths to avoid bash issues with parentheses in directory names:

```bash
mv /path/to/app/verify-email /path/to/app/\(auth\)/
```

**Key principle:** moving a page into a route group **does not change its URL path**. A page at `verify-email/[token]` stays at `/verify-email/[token]` whether it's in `app/verify-email/[token]/` or `app/(auth)/verify-email/[token]/`.

### Step 5 — Replace client-side redirects with `next.config`

Before (client-side redirect component):
```tsx
// app/login/page.tsx — renders, then redirects on the client
export default function LoginRedirectPage() {
  useEffect(() => window.location.replace("/auth/login"), []);
  return <div>Redirecting...</div>;
}
```

After (server-side, in `next.config.mjs`):
```js
async redirects() {
  return [
    { source: "/login", destination: "/auth/login", permanent: false },
  ];
}
```

Benefits: no flash of content, works before JS loads, faster, no client bundle.

### Step 6 — Clean dead routes

```bash
rm -rf app/(app)/.ignored-pages/   # Dead prototypes
rm -rf app/login/                  # Replaced by redirect
```

### Step 7 — Move API routes from `app/auth/` to `app/api/auth/`

Better Auth handler and sibling routes (`callback`, `confirm`) should live under `app/api/auth/`:

```bash
mv app/auth/callback/route.ts app/api/auth/callback/
mv app/auth/confirm/route.ts app/api/auth/confirm/
```

### Step 8 — Verify

```bash
# 1. No duplicate route errors
npx next build --turbo 2>&1 | grep -i "duplicate\|parallel pages\|cannot have two"

# 2. All routes resolve
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/auth/login     # 200
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/login          # 307 (redirect)
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/forgot-password # 200

# 3. Type check
pnpm typecheck
pnpm check:deps
```

## Anti-patterns to avoid

| Anti-pattern | Why | Fix |
|---|---|---|
| Client redirect page (`/login` → `useEffect` → `window.location.replace`) | Flash of content, JS-dependent, slow | `next.config.mjs` `redirects()` |
| Same page in both root and route group | Build error | Remove one |
| Page inside route group that doesn't need its layout | Layout cascades — they get whatever `(group)/layout.tsx` provides | Move to correct group or make layout pass-through (`<>{children}</>`) |
| `.ignored-` prefix directories | Git preserves them anyway, but they clutter `app/` | Delete them |
| API routes (`route.ts`) alongside page routes | Mixed concerns | Move to `app/api/` |