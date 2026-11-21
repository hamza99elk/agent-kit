---
name: sk-pi-extension
description: >
  Build, debug, and fix Pi coding agent extensions — custom tools, event handlers, command registration.
  Use this skill when the user asks to create a Pi extension, fix an extension bug, register a tool
  callable by the LLM, add event hooks, or debug extension loading/execution issues. Also use when
  working with ~/.pi/agent/extensions/ or reviewing the extension docs, examples, or API.
compatibility:
  - pi-coding-agent >= 1.5.0
---

# sk-pi-extension — Pi Extension Development

References:
- Full docs: `~/.pi/agent/install/releases/1.5.2/node_modules/@earendil-works/pi-coding-agent/docs/extensions.md`
- Examples: `~/.pi/agent/install/releases/1.5.2/node_modules/@earendil-works/pi-coding-agent/examples/extensions/`

---

## Gotchas

### 1. `ctx.cwd` in custom tool `execute()` may be wrong

When an LLM calls a custom tool registered via `pi.registerTool()`, the `ctx` parameter's `ctx.cwd` is set to the **pi process working directory** (`~/.pi`), NOT the user's project root. This differs from built-in tools where the runtime passes the project cwd.

**✅ Fix — always resolve relative paths with a fallback:**
```typescript
async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
  if (!params.path.startsWith("/")) {
    const base = ctx?.cwd ?? process.cwd();
    let tryPath = pathModule.resolve(base, params.path);
    if (!fs.existsSync(tryPath) || !fs.statSync(tryPath).isFile()) {
      // ctx.cwd is ~/.pi, not the project root. Fall back to known repo root.
      tryPath = pathModule.resolve("/Users/pro/Projects/analygo", params.path);
    }
    params.path = tryPath;
  }
  // ... read file, process, etc.
}
```

**Alternatively, accept an explicit `projectRoot` parameter** in the tool's schema (like `depcruise_check_import` does).

### 2. Extensions are cached — `/reload` is needed after edits

The pi runtime caches extension modules by file path. After editing an extension file, `/reload` must be called to pick up changes. Without a reload, the old cached version runs.

### 3. Tool `execute()` signature requires all 5 parameters

The correct signature for `pi.registerTool({ execute: ... })` is:
```typescript
async execute(
  toolCallId: string,
  params: { /* your params */ },
  signal?: AbortSignal,
  onUpdate?: (update: { content: ...; details?: ... }) => void,
  ctx?: ExtensionToolContext,  // has .cwd, .tools, .executeTool(), .ui, .sessionManager, etc.
): Promise<{ content: Array<{ type: string; text: string }>; details: Record<string, unknown> }>
```

Omitting `ctx` or later parameters from the function signature means you won't receive them even though the runtime passes them.

### 4. Extension imports — use `typebox`, not `@sinclair/typebox`

The pi runtime provides `typebox` (and `typebox/compile`, `typebox/value`) as host-provided packages. Import from `typebox`, not `@sinclair/typebox`. The legacy `@sinclair/typebox` alias also works but `typebox` is preferred.

### 5. `?? ""` (empty string fallback) triggers a lint warning

The extension code is checked against the analygo-project ESLint rules, which flag `?? ""` as hiding missing upstream data. Use explicit `if/else` or ternary instead:
```typescript
// ❌ Avoid:
let content = params.content ?? "";

// ✅ Use:
let content: string;
if (params.content !== undefined) {
  content = params.content;
} else {
  content = "";
}
```

Effective only when the extension is in the analygo repo workspace or checked by analygo's eslint config.

---

## Procedures

### [ ] Step 1: Register a custom tool

```typescript
import { type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "my_tool",
    label: "My Tool",
    description: "Tool description shown to LLM",
    parameters: Type.Object({
      path: Type.String({ description: "File path" }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      // Use ctx.cwd with fallback (see Gotcha #1)
      return {
        content: [{ type: "text", text: "result" }],
        details: {},
      };
    },
  });
}
```

### [ ] Step 2: Resolve file paths correctly

Always resolve relative paths against `ctx.cwd` first, then fall back:
```typescript
import { resolve } from "node:path";

async execute(..., ctx) {
  const baseDir = ctx?.cwd ?? process.cwd();
  const absPath = resolve(baseDir, paramPath);
  if (!fs.existsSync(absPath)) {
    // Fallback to known repo root
    const repoRoot = "/Users/pro/Projects/analygo";
    const altPath = resolve(repoRoot, paramPath);
    if (fs.existsSync(altPath)) {
      // use altPath
    }
  }
}
```

### [ ] Step 3: Subscribe to events

```typescript
pi.on("session_start", async (_event, ctx) => {
  ctx.ui.notify("Extension loaded!", "info");
});

pi.on("tool_call", async (event, ctx) => {
  if (isToolCallEventType("bash", event) && event.input.command.includes("rm -rf")) {
    return { block: true, reason: "Dangerous command" };
  }
});
```

### [ ] Step 4: Register a command

```typescript
pi.registerCommand("hello", {
  description: "Say hello",
  handler: async (args, ctx) => {
    ctx.ui.notify(`Hello ${args || "world"}!`, "info");
  },
});
```

### [ ] Step 5: Debug extension issues

1. Check the extension file for syntax errors: `node --check path/to/extension.ts`
2. Run `/reload` after editing an extension
3. Verify imports resolve: the pi runtime provides `typebox`, `@earendil-works/pi-coding-agent`, `@earendil-works/pi-tui`, `@earendil-works/pi-ai`, `@earendil-works/pi-agent-core`
4. Check for conflicting tool names (two extensions cannot register the same tool name)
5. Add `console.error()` logging — it appears in the pi process output

---

## Extension File Structure

```
~/.pi/agent/extensions/          # Global extensions (all projects)
├── my-extension.ts              # Single file extension
└── my-extension/                # Multi-file extension
    ├── index.ts                 # Entry point (exports default function)
    ├── utils.ts                 # Support modules
    └── package.json             # Optional: for npm dependencies

.pi/extensions/                  # Project-local extensions (requires trust)
```

## Key Imports

| Import | Purpose |
|--------|---------|
| `@earendil-works/pi-coding-agent` | `ExtensionAPI`, `ExtensionContext`, `ExtensionToolContext`, events, `isToolCallEventType`, `withFileMutationQueue`, `resolveToCwd`, `CONFIG_DIR_NAME` |
| `typebox` | `Type`, `Static` — schema definitions for tool parameters |
| `@earendil-works/pi-tui` | TUI components for custom renderers |
| `@earendil-works/pi-ai` | `StringEnum`, model types, provider helpers |
| `node:fs`, `node:path`, etc. | Node.js built-ins |
