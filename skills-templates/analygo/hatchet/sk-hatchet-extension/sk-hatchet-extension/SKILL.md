---
name: sk-hatchet-extension
description: Extend Pi with new Hatchet tools (CLI-offload pattern). Use when adding a tool to the analygo-hatchet Pi extension — creating the CLI back-end in packages/hatchet and the extension tool in ~/.pi/agent/extensions/analygo-hatchet.
license: MIT OR Apache-2.0
compatibility: Requires a Pi agent installation with extensions support and the analygo-hatchet extension configured
---

# Hatchet Pi Extension Tool Authoring

Read `../sk-hatchet-pi-extensions/SKILL.md` first if not already in context — this is the
focused recipe for one tool.

Every new hatchet tool = **two files**:

1. **CLI back-end** — `packages/hatchet/src/cli/{script}.ts` — standalone tsx script
2. **Extension tool** — `~/.pi/agent/extensions/analygo-hatchet/{name}.ts` — registers the Pi tool via `pi.registerTool()`

Plus: register in the barrel (`index.ts`).

---

## 1. CLI back-end (`packages/hatchet/src/cli/{script}.ts`)

Pattern — standalone tsx script that reads `argv[1]` as a JSON payload path, prints a single JSON line to stdout:

```ts
// src/cli/{script}.ts — <one-line purpose>
//
// Env: HATCHET_CLIENT_TOKEN, HATCHET_TENANT, HATCHET_ADDRESS, HATCHET_API_URL
//
// Run: node_modules/.bin/tsx src/cli/{script}.ts /tmp/payload.json
import fs from "node:fs";
import { HatchetClient } from "@hatchet-dev/typescript-sdk/v1";

const [, , payloadPath] = process.argv;

function fatal(msg: string): never {
  console.log(JSON.stringify({ ok: false, error: msg }));
  process.exit(1);
}

function main(): void {
  if (!payloadPath) fatal("missing payload path argv[1]");
  let input: Record<string, unknown>;
  try {
    const parsed = JSON.parse(fs.readFileSync(payloadPath, "utf8"));
    input = typeof parsed === "object" && parsed !== null ? parsed as Record<string, unknown> : {};
  } catch (e) {
    fatal(`unreadable payload: ${e instanceof Error ? e.message : String(e)}`);
  }

  // Validate required env vars
  const token = process.env.HATCHET_CLIENT_TOKEN ?? "";
  const tenant = process.env.HATCHET_TENANT ?? "";
  if (!token || !tenant) fatal("HATCHET_CLIENT_TOKEN / HATCHET_TENANT not set");

  const client = HatchetClient.init({
    token,
    ...(tenant ? { tenant_id: tenant } : {}),
    host_port: process.env.HATCHET_ADDRESS ?? "localhost:7077",
    api_url: process.env.HATCHET_API_URL ?? "http://localhost:8888",
    tls_config: { tls_strategy: "none" as const },
  });

  // … work with HatchetClient …

  console.log(JSON.stringify({ ok: true, /* … result fields … */ }));
}

main().catch((e) => fatal(`failed: ${e instanceof Error ? e.message : String(e)}`));
```

### Rules

- Always output `{ ok, error? }` as a single compact JSON line.
- Always `import { HatchetClient } from "@hatchet-dev/typescript-sdk/v1"`.
- The `HatchetClient` exposes `client.admin.runWorkflow()`, `client.api` (REST API).
- `fatal()` wraps errors into the JSON contract and `process.exit(1)`.
- Environment variables are always required — fail early with a descriptive message.
- No Zod schemas (the plain JSON contract is sufficient).

---

## 2. Extension tool (`~/.pi/agent/extensions/analygo-hatchet/{name}.ts`)

Pattern — calls the CLI via `runCli()` from `./cli.ts`, formats the JSON result:

```ts
// .pi/agent/extensions/analygo-hatchet/{name}.ts — Tool: <one-line description>
//
// Maps to: packages/hatchet/src/cli/{script}.ts

import { type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { runCli } from "./cli.ts";

export default function register(pi: ExtensionAPI) {
  pi.registerTool({
    name: "hatchet_{name}",
    label: "Hatchet: …",
    description: "…",
    parameters: Type.Object({ /* … */ }),
    promptSnippet: "…",
    promptGuidelines: ["…"],

    async execute(_toolCallId, params) {
      const result = await runCli("{script}.ts", { /* payload */ }, 30_000);
      if (!result.ok) { /* error formatting */ }
      return {
        content: [{ type: "text", text: formattedLines }],
        details: { ok: true, /* … */ },
      };
    },
  });
}
```

### Rules

- Tool name: `hatchet_list_flows` — snake_case, `hatchet_` prefix.
- Use `runCli(scriptName, payload, timeoutMs)` from `./cli.ts`.
- `runCli` handles temp file creation, process execution, JSON parsing.
- Max timeout for `runCli`: 30s for queries, up to 5min for dispatch+wait.
- Format output as readable markdown with status icons (✅ ❌ ⏳).
- Return raw data in `details` for downstream use.

---

## 3. Barrel registration

Add to `~/.pi/agent/extensions/analygo-hatchet/index.ts`:

```ts
import registerMyTool from "./my-tool.ts";

export default function registerAll(pi: ExtensionAPI) {
  // …
  registerMyTool(pi);
}
```

---

## 4. Existing CLI Scripts (reference)

| Extension Tool | CLI Script | Purpose |
|---|---|---|
| `hatchet_workflow_scout` | `delegate-scout.ts` | Dispatch dag-scout + poll result |
| `hatchet_workflow_plan` | `delegate-plan.ts` | Dispatch dag-plan + poll result |
| `hatchet_workflow_code_lane` | `delegate-coding.ts` | Dispatch dag-code-new-lane + poll result |
| `hatchet_run_status` | `get-run.ts` | Lightweight run status by runId |
| `hatchet_run_detail` | `run-detail.ts` | Full run detail by runId (step outputs, errors) |
| `hatchet_list_flows` | `list-runs.ts` | List active/recent workflow runs (REST API) |

---

## 5. Post-write checklist

- [ ] CLI script follows the fatal/exit pattern
- [ ] CLI script reads env vars: `HATCHET_CLIENT_TOKEN`, `HATCHET_TENANT`, … 
- [ ] CLI script outputs single JSON line with `{ ok, error?, … }`
- [ ] Extension tool registers via `pi.registerTool()` with `hatchet_` prefix
- [ ] Extension tool registered in barrel `index.ts`
- [ ] Extension tool uses `runCli()` from `./cli.ts` (no direct SDK import)
- [ ] Extension handles both `result.ok` and `!result.ok` paths
- [ ] Extension formats readable markdown output with status icons

## Gotchas

- **Two files, always.** A CLI back-end in `packages/hatchet/` and a tool wrapper in `~/.pi/agent/extensions/analygo-hatchet/`.
- **The CLI back-end must have `#!/usr/bin/env node`** and be executable. Without the shebang, the extension can't spawn it.
- **The tool name must match the CLI command.** The extension framework dispatches by name.
- **Polling strategy: return immediately, poll later.** Don't block on workflow completion — return the `runId` and use a separate poll tool.
- **Credentials come from the extension config, not from the CLI.** The extension's `config.toml` stores the token.

## Procedures

### Add a new Hatchet tool
- [ ] Write CLI back-end: `packages/hatchet/scripts/<tool-name>.ts`, with `#!/usr/bin/env node`, accepts args, calls Hatchet API, outputs JSON to stdout
- [ ] Make executable: `chmod +x`
- [ ] Create extension tool: `~/.pi/agent/extensions/analygo-hatchet/tools/<tool-name>.ts`, with tool definition + `execute` that spawns the CLI
- [ ] Register in the extension's tool manifest
- [ ] Test: run the CLI directly, then trigger through Pi

## References

See `/.patterns/hatchet/` for the underlying task and DAG patterns the CLI tool interacts with.
