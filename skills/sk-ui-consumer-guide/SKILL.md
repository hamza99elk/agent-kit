---
name: sk-ui-consumer-guide
description: >-
  Best practices for BUILDING UI in the Analygo Platform consumer (apps/platform).
  Covers the iron-clad contracts from packages/ui/src/foundation/*.mdx, the ESLint
  and depcruise guardrails, how to discover and prefer higher-level Storybook compositions before primitives,
  and the existing token, layout, import, and lint contracts. Use when
  building or editing any page, feature, or component in apps/platform that renders
  UI — cards, forms, tab strips, tables, page headers, status badges, loading states,
  or any layout. Also use when reviewing a PR for design-system compliance.
  NOT for building @analygo/ui components themselves (that's sk-ui-build).
license: MIT
metadata:
  version: "1.1"
---

# Analygo UI — Consumer Best Practices (apps/platform)

## The Core Principle

**Use the highest-level compatible, documented `@analygo/ui` component.**
Start with approved shells, blocks, sections, and compositions. Only drop to
`Container`, `Stack`, `Grid`, `Card`, and other primitives when an existing
higher-level component does not cover the requirement.

Never hand-roll what the shared UI already provides. Foundation docs
(`packages/ui/src/foundation/*.mdx`) define token-level contracts; exported
component APIs and Storybook stories define composition-level contracts.
ESLint + depcruise enforce existing static guardrails; **do not assume they
already detect duplicated higher-level compositions**.

For authoring domain-specific sections, ALSO use `sk-ui-consumer-feature`.
For app-level page layout and routing structure (the page.tsx → *View.tsx pattern),
see `sk-ui-consumer-page-layout`.

---

## 0. Required Component Discovery and Selection

Before implementing or editing a page/section:

1. Read the nearest existing page and identify its current shell and layout.
2. Inspect `@analygo/ui` public exports and Storybook stories for a matching
   **shell → block/section → composition → primitive**, in that order.
3. Read the selected component's props, slots, documented variants, interaction
   behavior, and responsive examples. Do not guess import paths or APIs.
4. Choose the **highest-level compatible** exported component. Compatibility
   includes semantics, accessibility, layout requirements, and behavior — not
   mere visual similarity.
5. Compose page-specific content into its supported slots; do not reconstruct
   its internal layout with `div`, `span`, or Tailwind.
6. If no matching composition exists, assemble approved primitives in a
   **feature-local component** and record the catalog gap. Do not silently add
   a new public component to `packages/ui`.
7. For new domain sections, apply `sk-ui-consumer-feature` as well.

**Selection ladder**

```text
Existing app shell (if applicable)
  → published layout / block / section
    → published composition / molecule
      → approved primitives (fallback)
        → feature-local custom markup (last resort)
```

**No invented APIs:** `DashboardSection`, `SectionHeader`, `Panel`,
`ResourceGrid`, etc. are candidate concepts, NOT assumed available exports.
Use them only after verifying actual package exports and Storybook examples.

**Decision record (brief, in PR or agent completion):** selected component,
Storybook reference, why it fits; if unavailable, explain the gap and fallback.


---

## 1. Layout Hierarchy

This section covers the **one rule** that governs all page layout in consumer code.
For the full API of each primitive (Container, Stack, Grid, Surface), their props,
responsive behavior, and composition patterns, see `sk-ui-layout`.

### The one rule

**Shells (Chrome, SidebarAppShell) never own content width or padding — the page
region owns them.** Never wrap an existing layout/block in an extra Container/Stack/Grid
without checking whether it already owns width, padding, spacing, or responsive
behavior.

```
Container (horiz max-width + edge padding)
└── Stack gap="4" (vertical rhythm)
    └── Grid cols={3} gap="6" (responsive column grid)
        └── Card (owns its own internal padding)
```

| Primitive | Owns | Import from |
|---|---|---|
| `Container` | max-width + centering + edge padding | `@analygo/ui/layouts` |
| `Stack` | vertical gap between children | `@analygo/ui/layouts` |
| `Grid` | responsive column layout + gaps | `@analygo/ui/layouts` |
| `Card` | internal padding of header/content | `@analygo/ui/card` |
| `Surface` | colored/frosted panel treatment | `@analygo/ui/atoms` |

**Warning sign:** `flex flex-col`, `space-y-*`, or `grid-cols-12` used to
recreate a documented shared layout. First check for an existing higher-level
component; then use `@analygo/ui/layouts` when composing genuinely new content.

For deep layout composition (HeroSurface, five-layer page architecture,
three-column zone layouts), see **`sk-ui-layout`** which is the canonical
source for all layout composition guidance.


---

## 2. Typography Contracts

**Contract from `FoundationTypography.mdx`:** default weight is `font-light` (300).
Never write explicit `font-weight` or raw `font-size` in consumer code.

| Instead of | Use |
|---|---|
| `<h1 className="text-2xl font-semibold">` | `<Heading level="h2">` or `text-section-heading` |
| `<h2 className="text-lg font-bold text-foreground">` | `<Heading level="h3">` |
| `<p className="text-sm font-medium text-muted-foreground">` | `<Text preset="body-sm" className="text-muted-foreground">` |
| `text-[16px]`, `text-4xl font-black` | semantic role utility (`text-card-title`, `text-section-heading`) |
| `<b>`, `<strong>` for hierarchy | size + color, not weight |

**Rule of thumb:** if you're adding `font-medium`, `font-semibold`, or `font-bold`
to a consumer component, you're fighting the design system. Default is `font-light`;
hierarchy comes from **size and color**, not weight.

### The `Text` and `Heading` components

```tsx
import { Heading } from "@analygo/ui/heading";
import { Text } from "@analygo/ui/text";

<Heading level="h2">Account Settings</Heading>   // h2 → text-3xl font-light
<Text preset="body" as="p" className="text-muted-foreground">
  Manage your profile
</Text>
```

Available `Heading` levels: `h1`–`h6`. Available `Text` presets: `h1`–`h4`,
`body`, `body-sm`, `caption`, `overline`, `code`.

---

## 3. Color Contracts

**Contract from `Colors.mdx`:** 100% token-driven. Never write a raw hex, a raw
CSS variable in className, or a named Tailwind color (in consumer code).

| Instead of | Use |
|---|---|
| `className="bg-[<hex value>]"` | `className="bg-background"` |
| `className="text-[var(--color-error)]"` | `className="text-destructive"` or `<Surface tone="error">` |
| `style={{ color: "<hardcoded blue>" }}` | `className="text-primary"` |
| `border-red-500` | `border-border` + `<Surface tone="error">` |
| `bg-red-100/50` | `bg-destructive/10` or `surface-{color}` utility |

**The only border colors that exist:**

| Token | Purpose |
|---|---|
| `border-border` | White-crystal edge (standalone surface) |
| `border-shell-border` | Chrome-shell edge (Sidebar, Header, panels) |
| `border-input` | Form fields |
| `ring-ring` | Focus ring (never `border` for focus) |

There is **no `border-destructive` / `border-success` / `border-warning`**. Tinted
edges go through `Surface tone`. Reaching for `border-red-500` in consumer code is
a signal to use `<Surface tone="error">` instead.

### Status badges — use the token components

If you're rendering a billing status, member status, or service status, check
`@analygo/ui/tokens` FIRST:

| Semantic | Component |
|---|---|
| Billing status (`active`, `past_due`, `trialing`, `canceled`) | `BillingStatusBadge` from `@analygo/ui/billing-status-badge` |
| Generic status (`active`, `pending`, `inactive`, `success`, `warning`) | `StatusBadge` from `@analygo/ui/status-badge` |
| Service health | `ServiceStatusBadge` from `@analygo/ui/service-status-badge` |
| Invoice status | `InvoiceStatusBadge` from `@analygo/ui/invoice-status-badge` |

```tsx
// ✅ Correct
<BillingStatusBadge status="past_due" />

// ❌ Wrong — hand-rolled status pill
<span className="text-[var(--color-error)] bg-[var(--color-error)]/15 rounded-full px-2 py-0.5 text-xs">
  Past due
</span>
```

---

## 4. Spacing Contracts

**Contract from `FoundationPadding.mdx`:** `gap` for structure, `padding` for the
surface. Use `gap` on the container, never per-child `mb-*`.

The ESLint `no-handrolled-stack` rule **errors** on `space-y-*` in consumer code —
it should be `<Stack gap="*">`.

```tsx
// ✅ Correct — Stack owns the gap
<Stack gap="4">
  <Card>…</Card>
  <Card>…</Card>
</Stack>

// ❌ Wrong — space-y anti-pattern
<div className="space-y-4">
  <Card>…</Card>
  <Card>…</Card>
</div>

// ❌ Wrong — per-child margin
<div className="flex flex-col">
  <Row className="mb-4" />
  <Row />
</div>
```

---

## 5. Form Fields — Use the `Field` Molecule

**Never hand-roll a label+input+error combo.** The `Field` molecule from
`@analygo/ui/field` provides the canonical pattern:

```tsx
import { Field, FieldLabel, FieldContent, FieldDescription, FieldError } from "@analygo/ui/field";
import { Input } from "@analygo/ui/input";

<Field>
  <FieldLabel htmlFor="email">Email</FieldLabel>
  <FieldContent>
    <Input id="email" type="email" />
    <FieldDescription>We will never share your email.</FieldDescription>
    <FieldError errors={form.formState.errors.email} />
  </FieldContent>
</Field>
```

**Hard rules:**
- **No inline `z.object()`** in component files — schemas live in `@analygo/contracts`
- **No raw `<label>` + `<Input>` + hand-rolled error `<p>`** — use `Field`
- **No `className="space-y-1"` field wrappers** — use `Field`/`FieldGroup`
- **No `text-sm font-medium text-muted-foreground` label styles** — `FieldLabel` owns them

For key-value display (not forms), use `MetaRow` from `@analygo/ui/meta-row`:

```tsx
// ✅ Correct — MetaRow for display-only data
<MetaRow label="Name" value={userName} />
<MetaRow label="Email" value={userEmail} />

// ❌ Wrong — hand-rolled label/value pair
<p className="text-sm font-medium text-muted-foreground">Name</p>
<p className="text-base font-semibold">{userName}</p>
```

---

## 6. Tables — Use `Table`, Not Hand-Rolled Grids

**Contract:** hand-rolled `grid grid-cols-12` tables for data display are forbidden.

```tsx
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from "@analygo/ui/table";

<Table>
  <TableHeader>
    <TableRow>
      <TableHead>Member</TableHead>
      <TableHead>Role</TableHead>
      <TableHead>Status</TableHead>
    </TableRow>
  </TableHeader>
  <TableBody>
    <TableRow>
      <TableCell>Ada Lovelace</TableCell>
      <TableCell>Owner</TableCell>
      <TableCell>Active</TableCell>
    </TableRow>
  </TableBody>
</Table>
```

The `TeamMembersList.tsx` pattern of `<div className="rounded-md border">` +
`<div className="grid grid-cols-12 ...">` is the anti-pattern to avoid.

---

## 7. Loading States — `Skeleton`, Not Spinners

**Empty spinner centers are not loading states.** For page-level loading, use
`Skeleton` placeholders that show the structure of what's coming.

```tsx
import { Skeleton } from "@analygo/ui/skeleton";

// ✅ Skeleton cards for a settings page
<div className="flex flex-col gap-6">
  <Skeleton className="h-40 w-full rounded-lg" />
  <Skeleton className="h-40 w-full rounded-lg" />
</div>

// ❌ A centered loader with no structural preview
<div className="flex items-center justify-center min-h-[400px]">
  <Loader2 className="h-8 w-8 animate-spin" />
</div>
```

---

## 8. Card Header — The Icon + Title Pattern

When a documented card/panel composition exists for the desired structure,
**use that composition**. The following `CardHeader` + `CardTitle` +
`CardDescription` + `Stack` pattern is the **fallback** when no suitable
higher-level composition is exported:

```tsx
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@analygo/ui/card";
import { Stack } from "@analygo/ui/layouts";

<Card>
  <CardHeader>
    <Stack gap="8" className="w-full">{/* or Stack gap="2" — use the layout primitive */}
      <CardTitle>Your account</CardTitle>
      <CardDescription>Profile information associated with your sign-in</CardDescription>
    </Stack>
  </CardHeader>
  <CardContent>
    {/* Field or MetaRow content */}
  </CardContent>
</Card>
```

**Note:** `AppIcon` and other descriptive-wrapper atoms are **deprecated** — use
`Icon` from `@analygo/ui/icon` with a lucide icon instead.

---

## 9. Tab Navigation — Use `Tabs variant="line"`

For page-level tab navigation (settings, evidence, audit center), use:

```tsx
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@analygo/ui/tabs";

<Tabs defaultValue="profile">
  <TabsList variant="line">
    <TabsTrigger value="profile">Profile</TabsTrigger>
    <TabsTrigger value="organization">Organization</TabsTrigger>
  </TabsList>
  <TabsContent value="profile">{/* content */}</TabsContent>
  <TabsContent value="organization">{/* content */}</TabsContent>
</Tabs>
```

**Do NOT** stack layout overrides on `TabsList`:
- ❌ `className="h-auto flex flex-wrap justify-start gap-1 p-1 w-full sm:w-auto"`
- ❌ `className="px-4"` on each `TabsTrigger`
- ❌ `className="mt-0"` on each `TabsContent` (for line variant)

The `variant="line"` already handles all of these.

---

## 10. Import Path Conventions

| Component | Import from | Don't import from |
|---|---|---|
| `Tabs`, `TabsContent`, `TabsList`, `TabsTrigger` | `@analygo/ui/tabs` | `@analygo/ui/shells` (broken barrel) |
| `Heading` | `@analygo/ui/heading` | — |
| `Text` | `@analygo/ui/text` | — |
| `Stack`, `Container`, `Grid` | `@analygo/ui/layouts` | `@analygo/ui/stack` (valid subpath, prefer layouts for all three) |
| `Card` family | `@analygo/ui/card` | — |
| `Field` family | `@analygo/ui/field` | — |
| `MetaRow` | `@analygo/ui/meta-row` | — |
| `Table` family | `@analygo/ui/table` | — |
| `BillingStatusBadge` | `@analygo/ui/billing-status-badge` | hand-rolled span |
| `Skeleton` | `@analygo/ui/skeleton` | Loader2 spinner |
| `Icon` | `@analygo/ui/icon` | `AppIcon` (deprecated) |

**Never use the root barrel `import { X } from "@analygo/ui"`** — it defeats
tree-shaking and is blocked by depcruise rule `app-no-ui-root-barrel`.

---

## 11. The Guardrails (What Fires and Why)

The ESLint plugin `@analygo/eslint-plugin-design-system` enforces the contracts.
Here's the full map:

| Rule | Enforces | Severity |
|---|---|---|
| `no-raw-hex` | No `#hex` anywhere in className/style | error |
| `no-tailwind-color-outside-tokens` | No `bg-red-500`, `text-slate-300` — only token colors | error |
| `no-raw-border-color` | Only `border-border`, `border-shell-border`, `border-input`, `border-primary` | error |
| `no-bare-border` | No bare `border` without a border color token | error |
| `no-border-separator` | No `border-b border-border` as content divider | warn |
| `no-hardcoded-font-weight` | No `font-bold`, `font-semibold`, `text-[16px]` in app/* | error |
| `no-handrolled-card` | No `div + bg-[ + rounded-[` without importing from `@analygo/ui/card` | error |
| `no-handrolled-stack` | No `flex flex-col gap-*` or `space-y-*` without `Stack` | error |
| `no-hardcoded-spacing` | No raw `p-4`, `gap-2` — wants `gap-[var(--space-2)]` | warn |
| `no-deprecated-atoms` | `AppIcon`, `FloatingActionButton`, `MetaRowPanel`, etc. are forbidden | error |
| `no-fixed-layout-width` | No `w-[300px]`, `ml-[300px]` — use layout tokens | error |
| `no-shell-tier-mismatch` | Shells don't own content width constraints | error |
| `no-aschild-radix` | No `asChild` — use `render` prop | error |

### Dependency-cruiser rules

These run in CI (depcruise):

| Rule | Enforces |
|---|---|
| `app-no-deep-ui-internals-import` | No `packages/ui/src/...` deep imports |
| `app-ui-primitive-without-shared-import` | Files exporting primitives must import from `@analygo/ui` |
| `app-no-ui-root-barrel` | No `import { X } from "@analygo/ui"` (root) |
| `app-no-inline-zod-schema` | No `z.object()` in app component files |
| `app-no-local-layout-shim` | No local `components/ui/stack|container|grid` imports |

---

## 12. The Settings-Page Refactor Pattern

The `app/(app)/settings/` page was the case study for primitive-level
violations. The following is a **legacy fallback reference**, not the required
template for every page. Prefer a published page layout or section block when
one exists:

```
Container (from @analygo/ui/layouts)
└── Stack gap="4"
    ├── Heading level="h2" + Text for title/subtitle
    └── Tabs variant="line"
        └── TabsContent
            └── Stack gap="6"
                └── Card
                    ├── CardHeader > Stack > CardTitle + CardDescription
                    └── CardContent
                        └── Field / MetaRow / Table / Badge token
```

**Anti-patterns to check for (from the settings page):**

| Anti-pattern | Fix |
|---|---|
| `<div className="flex gap-6 flex-col">` | `<Stack gap="6">` |
| `<h2 className="text-lg font-semibold">` | `<Heading level="h2">` |
| `<p className="text-sm font-medium text-muted-foreground">` | `FieldLabel` or `text-caption` |
| `<label>` + `<Input>` + error `<p>` | `Field` + `FieldLabel` + `FieldContent` + `FieldError` |
| `z.object({...})` inline in component | Schema in `@analygo/contracts` |
| `AppIcon name="users"` | `Icon` from `@analygo/ui/icon` with lucide |
| `text-[var(--color-error)] bg-[var(--color-error)]/15` | `BillingStatusBadge status="past_due"` |
| `<div className="grid grid-cols-12 ...">` for member list | `<Table>` from `@analygo/ui/table` |
| `min-h-[400px]` + `Loader2` spinner | `<Skeleton>` placeholders |
| `className="space-y-4"` | `<Stack gap="4">` |

---

## When Things Go Wrong

| Symptom | Likely cause | Fix |
|---|---|---|
| ESLint reports `no-deprecated-atoms` | Using `AppIcon` or another descriptive wrapper | Swap to `Icon` from `@analygo/ui/icon` |
| ESLint reports `no-hardcoded-font-weight` | Added `font-semibold`/`font-bold` | Let `Heading`/`Text` manage weight |
| ESLint reports `no-handrolled-stack` | Used `flex flex-col gap-*` or `space-y-*` | Use `<Stack gap="*">` |
| ESLint reports `no-raw-border-color` | Used `border-red-500` or `border-destructive` | Use `<Surface tone="error">` wrapper |
| ESLint reports `no-hardcoded-spacing` | Used raw `p-4`, `gap-2` | Acceptable but noisy — the rule wants `var(--space-*)` |
| Depcruise reports `app-no-inline-zod-schema` | `z.object()` in component file | Move schema to `@analygo/contracts` |
| Import from `@analygo/ui/shells` fails | The barrel has a broken re-export chain | Use per-component subpaths (`@analygo/ui/tabs`, `@analygo/ui/field`) |

## Related Resources

- `packages/ui/src/foundation/*.mdx` — The source contracts (Colors, Borders, Typography, Padding, Glass)
- `packages/ui/src/shells/index.ts` — The canonical shadcn re-export barrel
- `.dependency-cruiser/platform-*.rules.cjs` — Import-graph guardrails
- `packages/eslint-plugin-design-system/rules/` — ESLint guardrail implementations
- `apps/platform/config/eslint.config.cjs` — Platform's enabled guardrail set
- `sk-ui-layout` — Full API docs for Container, Stack, Grid, Surface, HeroSurface and the five-layer page architecture
- `sk-ui-archetypes` — Reusable three-zone page layouts (Explorer, Detail, Canvas)
- `sk-ui-consumer-feature` — Authoring domain-specific feature sections

---

## 13. Higher-Level Composition Acceptance Checks

For every added or substantially changed consumer page, verify:

- [ ] Searched documented Storybook compositions, sections, blocks, and shells first.
- [ ] Confirmed public exports, slot APIs, and supported variants before usage.
- [ ] Avoided recreating an existing SectionHeader, Panel, ActionRow, resource
      pattern, empty/error state, or other documented shared composition.
- [ ] Used shared layout primitives only for gaps not owned by a higher-level block.
- [ ] Preserved semantic heading order and accessible interactions.
- [ ] Used feature-local components for domain-specific mapping/state/actions.
- [ ] Tested narrow and wide layouts, loading/empty/error states where applicable.
- [ ] Ran available typecheck, lint, Storybook interaction/accessibility tests.
- [ ] Reported any missing design-system composition rather than inventing one.

**Do not auto-promote feature-local components into `packages/ui`.** Reuse and
promotion are reviewed using the `packages/ui` authoring skill/RFC.

**Schema boundary:** `@analygo/contracts` continues to own shared/domain
schemas under the existing no-inline-Zod rule. Do not introduce a UI-specific
Zod schema for React nodes, slots, callback props, or ordinary JSX children.