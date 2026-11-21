---
name: sk-platform-nav
description: "⚠️ DEPRECATED — Use the APPEND_SYSTEM.md design-system recap and sk-route-consolidation instead. This skill references the old shadcn/ui + FRONTEND_RULES.md architecture which has been replaced by @analygo/ui and the RFC route consolidation."
---

# Platform Navigation

## Overview

The Analygo Platform is a Next.js 16 frontend (App Router, TypeScript, Tailwind CSS, shadcn/ui) for the GTM/GA4 audit UI. It lives at `apps/platform/` in the Analygo monorepo.

This skill helps you find files, understand the architecture, and write code that follows the project's conventions — without needing to re-read `FRONTEND_RULES.md` and `docs/ARCHITECTURE.md` every time.

## Directory quick reference

```
apps/platform/
├── app/                          # Next.js App Router pages + features
│   ├── features/{name}/          # Feature-First: components/, pages/, hooks/, api.ts
│   ├── (app)/                    # Authenticated layout group
│   ├── auth/                     # Auth pages (login, signup, forgot-password)
│   ├── api/                      # Next.js API route handlers
│   ├── components/               # Layout components (AppShell, Sidebar)
│   ├── config/                   # Breakpoints, label config, utilities
│   ├── contexts/                 # Global React contexts (Dashboard, Header)
│   ├── hooks/                    # Shared React hooks
│   ├── data/                     # Mock data & API clients
│   └── globals.css               # CSS variables + Tailwind base
├── components/
│   ├── ui/                       # shadcn/ui primitives (button, card, input, table, etc.)
│   ├── blocks/                   # Reusable composites: DataTable, FormPattern, FormField
│   └── layouts/                  # (legacy, prefer app/(app) layout)
├── lib/                          # cn() utility, proxy helpers
├── types/                        # Shared TS type definitions
├── docs/                         # Architecture docs, patterns guides
├── api/                          # Python backend (separate workspace)
├── services/                     # Auth service, API client wrappers
├── scripts/                      # Build-time scripts (validate-env, prerender-check)
├── config/                       # ESLint, tsconfig
├── docs/ARCHITECTURE.md          # Read for full architecture
├── FRONTEND_RULES.md             # Read for coding conventions
├── SERVICE.md                    # Runtime contract (ports, health endpoint, env vars)
├── README.md                     # Project README
└── package.json                  # Dependencies & scripts
```

## Component hierarchy (3-tier)

```
components/ui/ (shadcn primitives)
    ↓ compose
components/blocks/ (reusable composites, 2+ features)
    ↓ compose
app/features/{name}/components/ (single-feature)
```

### When to use each layer

| Layer | Purpose | Imports from | Example |
|-------|---------|-------------|---------|
| `components/ui/button` | Atomic, generic, no business logic | nothing feature-specific | `<Button variant="default">` |
| `components/blocks/DataTable` | Cross-feature composite | `ui/*` only | `<DataTable columns={...} data={...} />` |
| `app/features/gtm/components/GtmCard` | Single-feature logic | `ui/*`, `blocks/*` | GTM-specific inner card |

**Promotion rule.** If a feature component is used by a second feature, promote it to `components/blocks/`.

## Forms pattern

Always use the established pattern — never invent a new one:

```tsx
import { FormPattern, FormField } from "@/components/blocks";
import { Input } from "@/components/ui/input";
import { z } from "zod";

const schema = z.object({ email: z.string().email() });

function MyForm() {
  return (
    <FormPattern schema={schema} defaultValues={{ email: "" }}
      onSubmit={async (data) => { /* ... */ }}
    >
      {(form) => (
        <FormField name="email" label="Email" form={form}>
          <Input type="email" />
        </FormField>
      )}
    </FormPattern>
  );
}
```

## Tables pattern

Always use TanStack Table + `DataTable` block:

```tsx
import { DataTable } from "@/components/blocks";
import { ColumnDef } from "@tanstack/react-table";

const columns: ColumnDef<Row>[] = [
  { accessorKey: "name", header: "Name" },
];

function MyTable({ data }: { data: Row[] }) {
  return (
    <DataTable columns={columns} data={data} searchKey="name" showPagination />
  );
}
```

## Import path conventions

| Prefix | Resolves to | Example |
|--------|-------------|---------|
| `@/components/ui/` | `apps/platform/components/ui/` | `@/components/ui/button` |
| `@/components/blocks/` | `apps/platform/components/blocks/` | `@/components/blocks` |
| `@/app/config` | `apps/platform/app/config` | `@/app/config` |
| `@/lib/utils` | `apps/platform/lib/utils` | `@/lib/utils` |
| `@/app/features/` | `apps/platform/app/features/` | `@/app/features/gtm/api` |

## Gotchas

- **Don't import from MUI.** `@mui/material` imports are legacy only. Use shadcn/ui components.
- **Don't create wrapper components without behavior.** Compose primitives directly; wrap only to add behavior or enforce constraints.
- **Don't use inline styles or CSS modules.** Always Tailwind CSS with `cn()`.
- **Don't modify shadcn/ui components directly.** They are the foundation; compose them in blocks/features.
- **`app/components/` vs `components/`.** The project has TWO `components/` dirs: `app/components/` (layout components) and `components/` (ui primitives + blocks). They serve different roles.
- **`.pi/` is gitignored.** Session digests stay local. Never commit agent memory.

## pnpm 12 & workspace package facts

The platform migrated from pnpm 10→12 on 2026-11-08. These are the concrete changes you should know:

- **All `@analygo/*` refs must be `workspace:*`, not tarball paths or version ranges.**
  Both `apps/platform/package.json` (frontend) and `apps/platform/api/package.json` (backend)
  were migrated. If you add a new dep on an `@analygo/*` package, use `workspace:*`.

- **3 `@analygo/*` workspace packages were scaffolded from tarballs** — they don't have source
  in `packages/` with a full build pipeline:
  - `@analygo/aegis-client` — pre-built `dist/` from the old tarball. Written as JS, not TS source.
  - `@analygo/api-types` — raw `.ts` source files (no build step).
  - `@analygo/auth-client` — raw `.ts` source files (no build step).
  Location: `packages/aegis-client/`, `packages/api-types/`, `packages/auth-client/`.

- **`.npmrc` must inline the GHCR auth token.** pnpm 12 refuses `${VAR}` expansion for `//npm.pkg.github.com:_authToken`.
  The working token is `GITHUB_ROOT_TOKEN` from Infisical `/github`.
  Also set: `verify-deps-before-run=false`, `minimum-release-age=0`.

- **pnpm-workspace.yaml has `onlyBuiltDependencies`.** After `pnpm approve-builds`, the file stores
  `allowBuilds: { es5-ext: ..., sharp: ..., unrs-resolver: ..., workerd: ... }` and a `permissions` section.

- **`instrumentation.ts` does NOT import `@analygo/observability`.** It was rewritten to use
  `@analygo/hyperdx/otel-config` + `SERVICE_NAMES` + `BasicTracerProvider` (avoids `@opentelemetry/sdk-node`
  which isn't a platform dep). The service name for platform is `SERVICE_NAMES.PLATFORM`.

## Known build issues

- **`@analygo/auth` build breaks** — TS2742 (Zod v4 type inference). Workaround: add explicit type
  annotations to `createBetterAuthClient` / `createIssuer` return types in `packages/auth/src/`.
- **`apps/platform/api/` is a Hono app** with its own boot via `uv`/`deno`, NOT part of Next.js `pnpm dev`.
- **`@useautumn/js` missing** — breaks `apps/platform/api/src/domain/identity/issuer.ts`. If you hit this,
  the dep needs to be added to `apps/platform/api/package.json`.
- **Peer dep warnings** — run `pnpm peers check` and audit after installs.

## Remote package access

`@analygo/*` packages are published to GitHub Packages (`https://npm.pkg.github.com`).
Authentication requires a GitHub token with `read:packages` scope.
The repo-level `.npmrc` has scoped registry:
```
@analygo:registry=https://npm.pkg.github.com
//npm.pkg.github.com:_authToken=<inlined-token>
```

## Infisical secrets

The Infisical MCP (`mcp__infisical`) is available via codemode. Key folders:
- `/github` — `GITHUB_ROOT_TOKEN`, `GITHUB_GHCR_TOKEN`
- `/hyperdx` — OTLP endpoint + auth token
- Platform-specific env vars from Infisical per environment

## When to read which doc

- Architecture questions → `docs/ARCHITECTURE.md`
- Coding conventions → `FRONTEND_RULES.md`
- Component patterns → `docs/README.md` → `FORMS_AND_TABLES_GUIDE.md`
- Runtime config, ports, health → `SERVICE.md`
- Full project overview → `README.md`
- Backend API source → `api/` directory