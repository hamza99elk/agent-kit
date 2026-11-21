---
name: sk-storybook-component-testing
description: >
  Write, review, debug, and audit Storybook stories and interaction tests for React components
  in @analygo/ui. Use when asked to create or add new stories, fix broken or missing stories,
  set up interaction tests with @storybook/test, audit a component's story coverage (missing
  states, conditionals inside stories, stale snapshots), or integrate Storybook tests into CI
  with Chromatic. Also useful when reviewing a component PR that has no story file — treat
  that as a gap to fill.
license: MIT
compatibility: Storybook 10.5 · CSF 3 · React-Vite framework · @storybook/addon-mcp
metadata:
  author: Analygo Team
  version: 1.1.0
---

# sk-storybook-component-testing — Storybook stories for @analygo/ui

Write, audit, and maintain Storybook stories and interaction tests for the @analygo/ui React
component library. Stories here use **CSF 3** (React + Vite, Storybook 10.5) with the
`@storybook/addon-mcp` MCP server enabled for AI manifests.

---

## Workflow

Progress:
- [ ] Step 1: Find the component and its existing story file (co-located at `<Name>/<Name>.stories.tsx`)
- [ ] Step 2: Identify all relevant states (default, loading, empty, error, disabled, edge cases)
- [ ] Step 3: Write or update stories — one per state, no conditional logic inside stories
- [ ] Step 4: Tag each story correctly (`"autodocs"` + tier tag + framework tag)
- [ ] Step 5: Add interaction tests (`play` function) for interactive components (forms, dialogs, dropdowns)
- [ ] Step 6: Verify stories render locally (`pnpm storybook`) or run interaction tests (`pnpm test-storybook`)

### Step details

**Locate.** Stories are co-located with their component — `src/atoms/Button/Button.stories.tsx`, not a separate `stories/` directory. If no `.stories.tsx` file exists next to a component, create one there.

**Write one story per state.** Every story represents one specific, named state:

```tsx
export const Default: Story = {};
export const Checked: Story = { args: { defaultChecked: true } };
export const Disabled: Story = { args: { disabled: true, defaultChecked: true } };
export const DisabledUnchecked: Story = { args: { disabled: true } };
```

Do **not** use `if`/ternary/conditional logic inside stories. If you need to show multiple variants, write separate stories. The reason: agents and Chromatic use individual stories as discrete testable units — combining states blurs the manifest and produces unreliable visual diffs.

Cover these states when applicable:
- **Default** — initial state
- **Checked/Active/Selected** — toggled state
- **Disabled** — non-interactive
- **Disabled + checked** — combined state
- **Empty** — no data (for lists, tables)
- **Loading** — spinner/intermediate state
- **Error** — validation or input error
- **With data** — realistic production-like values (not `id: 1`, `name: 'Test'`)
- **Long content** — edge case for overflow
- **Icons / addons** — icon or addon slots

**Prefer `args` over `render`.** Use `args` for simple prop-driven components. Only switch to `render` when the component needs children, slots, or composition patterns:

```tsx
// args is sufficient — use it
export const Success: Story = { args: { variant: "success", label: "Verified" } };

// render needed — children/slots required
export const WithActions: Story = {
  render: (args) => (
    <Card {...args}>
      <template #header>Card Title</template>
      <p>Content here.</p>
      <template #footer>
        <Button variant="primary">Confirm</Button>
      </template>
    </Card>
  ),
};
```

**Tag correctly.** Every story gets `"autodocs"` + exactly one tier tag + one framework tag. Tags control sidebar organization and Chromatic filtering:

| Tier tags | Framework tags |
|---|---|
| `atom` — basic component (Button, Input) | `base-ui` — current library (**preferred**) |
| `molecule` — compound component (Card, MenuBar) | `radix` — Radix UI (excluded from sidebar) |
| `recipe` — composable pattern | `plain` — HTML/CSS only |
| `layout` — layout component (Header, Sidebar) | `cmdk` / `recharts` / `embla` / `third-party` |

Lifecycle tag: `deprecated` excludes from sidebar.

**Add JSDoc on every story.** Describe *why* the story exists, not just *what* it shows. The `@storybook/addon-mcp` MCP server includes these descriptions in the AI manifest, so agents can understand when to use each variant:

```tsx
/** The default badge — used for static labels and status indicators. */
export const Default: Story = { args: { label: "New" } };

/** Success variant — communicates a positive state (verified, completed). */
export const Success: Story = { args: { variant: "success", label: "Verified" } };
```

**Interaction tests.** Interactive components (forms, dialogs, dropdowns) must have a `play` function:

```tsx
import { within, userEvent, expect } from "@storybook/test";

export const SuccessfulLogin: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.type(canvas.getByLabelText("Email"), "user@analygo.co");
    await userEvent.type(canvas.getByLabelText("Password"), "secret123");
    await userEvent.click(canvas.getByRole("button", { name: "Sign in" }));
    await expect(canvas.getByRole("button")).toHaveAttribute("aria-busy", "true");
  },
};
```

Always cover: happy path, validation errors (empty/invalid input), and edge cases (disabled state cannot be interacted with).

### Validation

1. Run `pnpm storybook` and visually check each new story renders.
2. For interaction tests: `pnpm test-storybook --url http://localhost:6006`.
3. Verify all expected states appear in the Storybook sidebar under the correct heading.
4. Confirm tags are correct — wrong tags break sidebar organization and Chromatic filtering.

## Gotchas

- **Stories are co-located.** The project puts `Button.stories.tsx` next to `Button.tsx`, not in a `stories/` directory. If you create a story file somewhere else, Storybook won't find it — the config glob is `../src/**/*.stories.@(ts|tsx)`.
- **The `"autodocs"` tag is mandatory on every story.** Without it, the story won't appear in auto-generated documentation pages. This is easy to forget because the story still renders in the sidebar.
- **`radix`-tagged stories are hidden from the sidebar by default** (`defaultFilterSelection: "exclude"`). They're visible only when the user explicitly enables them. Don't remove the tag thinking it's broken — that's the intended behavior for deprecated Radix UI primitives.
- **Use realistic data, not placeholders.** `id: 1`, `name: 'Test'` are anti-patterns. Use production-like values (`"user@analygo.co"`, `"Permission denied"`, `"Acme Corp"`) because story data feeds the AI manifest that agents read to understand component usage.
- **The MCP server includes JSDoc descriptions in the manifest.** If you write a story without JSDoc, the agent gets the first 60 characters of the story's source code as its description. Always add a JSDoc comment describing *why* someone would use this variant.

## References

- `.pi/docs/agent-guide.md` — full project conventions: Storybook setup, decorator patterns, CI with Chromatic, a11y testing, the CSF 3 template with argTypes, and the audit checklist
- `src/atoms/Input/Input.stories.tsx` — minimal atom with args only (simplest starting template)
- `src/atoms/checkbox/Checkbox.stories.tsx` — state variants pattern (default → checked → disabled → disabled+checked)
- `src/atoms/Tabs/Tabs.stories.tsx` — compound component with render + multiple variants + JSDoc on each story
- `src/molecules/AlertDialog/AlertDialog.stories.tsx` — compound component with render (slots)
- `src/molecules/ChatInputArea/ChatInputArea.stories.tsx` — args + component addons (left/right addon slots)
- `src/sections/PageBlueprint.stories.tsx` — interaction test with `play` + `within` + `expect`

---

*Generated by sk-build-skill*