---
name: sk-ui-build
description: >-
  Build, edit, or review @analygo/ui components for the Analygo platform. Use
  when the user asks to add a new component, fix a UI bug, change a component's
  variants or styling, create a Storybook story, audit a PR for UI rule
  violations, or write tests for an existing component. Also use when the user
  asks why a component looks wrong, how to compose two components together, or
  how to expose a new component through the package's export map. NOT for
  general React knowledge, CSS fundamentals, or non-Analygo design system work.
license: MIT
metadata:
  version: "1.1"
---

# @analygo/ui — Design System Skill

## Composition Over Variants — How to Decide

**Tone belongs on the component's own CVA where the component has visual identity. Surface tints the container. They compose.**

Ask the litmus test: **does this component gain a panel frame from the treatment?**

| If the answer is… | That means… | Do this |
|---|---|---|
| **Yes** — the treatment adds padding, border, background that frames the whole component | The treatment is a *container* concern | Use `<Surface>` to wrap it, or apply `surface-*` / `bg-*` utility classes to the container element |
| **No** — the treatment is just a color / glass / accent on the element itself | The treatment is a *visual identity* concern | Add it as a CVA variant on the component, or use a raw utility class |

```tsx
// ✅ Correct — Surface wraps Card (gets panel frame)
<Surface variant="glass-white" interactive>
  <Card size="sm"><CardContent>…</CardContent></Card>
</Surface>

// ✅ Correct — utility class on a button (no panel frame)
<Button variant="ghost" className="surface-glass-white"><Plus /></Button>

// ❌ Wrong — Card with variant="glass" (Card owns structure, not surface)
<Card variant="glass" glassTone="primary" />

// ❌ Wrong — Button wrapped in Surface (adds panel padding + border)
<Surface variant="glass-white"><Button>Click</Button></Surface>
```

**Concrete examples of components that OWN their variants:**
- **Button** — `default`/`destructive`/`outline`/`secondary`/`ghost`/`link`
- **Badge** — `default`/`secondary`/`destructive`/`outline`/`glassWhite`/…

**Concrete example of Surface as container tint:**
- **Surface** — `white`/`blue`/`red`/`success`/`warning`/`muted` + glass forms (`glass-white`, `glass-blue`, etc.)

## Props Over Wrapper Components

**No consumer-facing wrapper components. Compose public primitives directly.** A `PageHero` that hardcodes `HeroSurface` plus specific text styles is wrong — the wrapper owns the template instead of letting the consumer compose from primitives.

**Exception: `recipes/`** — opinionated, domain-complete assemblies with concrete defaults (Carousel, Chart, Sonner). Justified only when they substantially reduce boilerplate for a complex pattern.

## How to Choose Which Tier

| If the component is… | It belongs in… |
|---|---|
| A single-element primitive (Button, Input, Tooltip) | *atoms/* |
| A composition of atoms (Combobox = Input + Popover + List, AlertDialog = Dialog + Button group) | *molecules/* |
| An opinionated, domain-specific assembly that saves lots of boilerplate (Carousel, Chart) | *recipes/* |
| A page layout primitive (AppShell, Grid, Stack, Container, Rail) | *layouts/* |
| App chrome — Sidebar, Sheet/Drawer, ContextSheet, TwoColumnFormShell | *shells/* |

Cards (`Card`, `CardHeader`, `CardContent`, `CardFooter`) live at `packages/ui/src/card/` — a cross-cutting layout primitive not owned by any tier.

## Adding a New Component — Procedure

```bash
# 1. Scaffold via CLI
pnpm --filter @analygo/ui components:create

# 2. It passes three registry gates automatically:
#    Gate 1 — Purpose keyword match (warning on collision)
#    Gate 2 — CVA base class exact match (hard block — extend, don't duplicate)
#    Gate 3 — Dice coefficient > 85% (warning on near-duplicate)
#
# 3. Verify CI: pnpm --filter @analygo/ui audit:components
```

**After scaffolding, you still need to:**
- Register the export path in `package.json` exports map (unless the CLI does it)
- Run `just doc-refresh` to regenerate auto-generated docs in `docs/ui/`
- Push exports — the new component becomes available at `@analygo/ui/<kebab-name>`

## How to Structure a Component File

Every component gets its own directory with these files:

```
ComponentName/
├── index.ts               # barrel: `export * from "./ComponentName"`
├── ComponentName.tsx       # component implementation
├── ComponentName.styles.ts # CVA variants + @registry comments
├── ComponentName.stories.tsx  # Storybook stories
└── ComponentName.test.tsx     # tests
```

### ComponentName.tsx

**If it wraps a Base UI primitive:** use the Base UI `render`-prop pattern:

```tsx
import { Button as ButtonPrimitive } from "@base-ui/react/button";
import { cn } from "../../utils";
import { buttonVariants, type ButtonVariants } from "./Button.styles";

function Button({ className, variant = "default", size = "default", ...props }: ButtonPrimitive.Props & ButtonVariants) {
  return (
    <ButtonPrimitive
      data-slot="button"
      className={cn(buttonVariants({ variant, size }), className)}
      {...props}
    />
  );
}
```

**If it's a plain React component (no Base UI):** use standard React patterns:

```tsx
function Badge({ className, variant, ...props }: React.HTMLAttributes<HTMLSpanElement> & BadgeVariants) {
  return <span className={cn(badgeVariants({ variant }), className)} {...props} />;
}
```

### ComponentName.styles.ts

Every styles file carries `@registry` comments AND a CVA definition:

```ts
// @registry id: button
// @registry purpose: Triggers an action or navigates to a destination
// @registry cvaBase: inline-flex items-center justify-center gap-2 rounded-lg text-sm font-light ...

import { cva, type VariantProps } from "class-variance-authority";

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-lg text-sm font-light ...",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive: "bg-destructive text-destructive-foreground hover:bg-destructive/80",
        outline: "border border-input bg-background hover:bg-accent hover:text-accent-foreground",
        secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost: "",
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default: "h-10 px-4 py-2",
        sm: "h-9 rounded-md px-3",
        lg: "h-11 rounded-md px-8",
        icon: "h-10 w-10",
      },
    },
    defaultVariants: { variant: "default", size: "default" },
  }
);
```

The `@registry` comments are scanned by the registry audit gate AND the auto-doc generator. They must match the registry entry in `src/registry.ts`.

## Consumer Importing — How to Choose

Use per-component subpaths by default. Tier barrels are available but prefer explicit imports:

| Preferred | Available but avoid |
|---|---|
| `import { Button } from "@analygo/ui/button"` | `import { Button } from "@analygo/ui/atoms"` |
| `import { Card } from "@analygo/ui/card"` | `import { Card } from "@analygo/ui/shells"` |

## Framework Integration — Render Props

Components avoid framework-specific imports (`next/link`, `next/image`). Use render props for bridging:

| Prop | Consumer Provides |
|---|---|
| `renderLink` | Next.js `Link` or React Router `Link` |
| `renderImage` | Next.js `Image` or `<img>` |
| `renderBreadcrumbLink` | Usually Next.js `Link` |
| `renderAuditAction` | Framework-specific handler wrappers |

## Styling — How to Make Each Decision

**When choosing *how* to style a component, go through these checks in order:**

1. **Does it wrap a Base UI primitive?** → Use the Base UI `data-slot` attribute pattern: `<Component data-slot="component-name" className={cn(...)}>`
2. **Does it need color?** → Use Tailwind utilities (`bg-primary`, `text-muted-foreground`, `border-destructive`). Never raw hex, `rgb()`, or `hsl()`.
3. **Does it need spacing?** → Use native Tailwind spacing (`p-4`, `gap-6`). The only component-owned spacing variable is `--card-spacing` (for Card layout gaps).
4. **Does it need animations?** → Use Tailwind v4 animation utilities:
   ```tsx
   className="data-open:animate-in data-open:fade-in-0 data-open:zoom-in-95 data-closed:animate-out data-closed:fade-out-0 data-closed:zoom-out-95"
   ```
5. **Does it expose sub-components?** → Export them from the same file with the parent name prefix: `DialogTrigger`, `DialogContent`, etc.

## Known Gotchas

1. **CVA multi-line strings in registry.ts** — The `cvaBaseClass` field can span two lines (opening `"` on one line, value + closing `"` on the next). Any parser scanning `registry.ts` must handle this. The doc generator at `packages/ui/scripts/generate-ui-docs.ts` does; homegrown parsers may not.

2. **Registry name collisions** — Two entries can share the same `name` field (`button` and `shell-button` both have `name: "Button"`). If you index by `name.toLowerCase()`, the second entry overwrites the first. Always look up by `id` (kebab-case), never by `name`.

3. **Card has no variant="glass"** — Card owns structure (header/content/footer slots + spacing). Surface treatment wraps *around* Card. If you need a tinted, glass, or elevated card, use `<Surface variant="glass-white"><Card>…</Card></Surface>` — never add a variant to Card.

4. **Tailwind v4 Storybook blank styling** — If Storybook renders unstyled HTML (no `bg-primary`, no `flex`), the `@source` directive is missing from the CSS entry OR the Tailwind Vite plugin isn't loaded in `.storybook/main.ts`. See `TAILWIND_V4.md` for the fix.

5. **`layouts/` vs `shells/` — the moby-dick of PR reviews** — Layout primitives live in `src/layouts/` (page structure: AppShell, Grid, Stack, Container, Rail). App chrome lives in `src/shells/` (overlays: Sidebar, Sheet, Drawer, ContextSheet). A page wrapper for data display → Layout. A modal overlay → Shell. Getting this wrong is the most common CI fail for new components.

## When Things Go Wrong

| Symptom | Likely cause | Check |
|---|---|---|
| CI audit fails on component | Registry gate violation | Run `pnpm --filter @analygo/ui audit:components` to see which gate |
| Docs show wrong purpose text | Registry lookup hit `name` instead of `id` | See Gotcha #2 — fix the parser |
| Storybook shows no styles | Missing `@source` or Vite plugin | Check `TAILWIND_V4.md` for the fix |
| Consumer can't import component | Missing export in `package.json` | Add `"./<name>": "./src/<tier>/<Name>/index.ts"` to exports map |
| `just doc-refresh` doesn't update UI docs | Generator not wired | Verify `justfile` has the UI doc generation step (it should after the recent update) |

## Related Docs

- `packages/ui/README.md` — Consumer-facing README (framework integration, design tokens, import setup)
- `packages/ui/LAYOUT_COMPONENTS.md` — Layout components integration guide (AppShell, Sidebar, etc.)
- `packages/ui/MIGRATION.md` — Migration guide for version bumps
- `docs/ui/README.md` — Auto-generated component index (regenerate with `just doc-refresh`)