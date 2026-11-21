---
name: sk-hatchet-pi-extensions
description: Hatchet Pi extension architecture reference — CLI-offload pattern, polling strategy, prompt design, and credentials. Read this BEFORE writing a new tool (then read sk-hatchet-extension for the per-tool recipe).
license: MIT OR Apache-2.0
compatibility: Requires a Pi agent installation with extensions support
---

# Skill: Hatchet Pi Extension Skeleton

Extend Pi with Hatchet workflow dispatch/query tools using **CLI-offload** pattern.

## Architecture

```
/Users/pro/.pi/agent/extensions/analygo-hatchet/
├── index.ts               # barrel: registers all tools
├── cli.ts                 # shared: run hatchet CLI via tsx, parse JSON result
├── workflow-scout.ts      # tool: dispatch dag-scout + poll result
├── workflow-plan.ts       # tool: dispatch dag-plan + poll result
├── workflow-code-lane.ts  # tool: dispatch dag-code-new-lane + poll result
├── run-status.ts          # tool: fetch run status (lightweight query)
├── run-detail.ts          # tool: fetch run detail (full step dump with errors)
├── types.ts               # shared: TypeBox schemas for all tool params
└── prompts.ts             # shared: prompt snippets and guidelines
```

## CLI-Offload Pattern (DO THIS)

Every tool calls an **existing hatchet CLI script** via `tsx`. The extension never imports the Hatchet SDK.

```
Tool(params) → write JSON to /tmp/hatchet-XXX/payload.json
            → exec(`npx tsx packages/hatchet/src/cli/{script}.ts /tmp/hatchet-XXX/payload.json`)
            → parse stdout JSON line
            → return formatted summary + raw details
```

## Existing CLI Scripts (the back-ends)

| Extension Tool | CLI Script | Input | Output |
|---|---|---|---|
| `hatchet_workflow_scout` | `delegate-scout.ts` | `{ goal, repoRoot, inventory?, lanes? }` | `{ ok, runId, text }` |
| `hatchet_workflow_plan` | `delegate-plan.ts` | `{ goal?, spec?, repoRoot?, allowedDirs?, ticket?, planId? }` | `{ ok, runId, text }` |
| `hatchet_workflow_code_lane` | `delegate-coding.ts` | `{ scope, instructions, targetPath, repoRoot }` | `{ ok, runId, text }` |
| `hatchet_run_status` | `get-run.ts` | `{ runId }` | `{ ok, runId, status, steps }` |
| `hatchet_run_detail` | `run-detail.ts` | `{ runId }` | `{ ok, runId, workflow, status, summary, stepResults }` |

## Portability / CWD

The extension resolves all paths relative to `HATCHET_DIR = "/Users/pro/Projects/analygo/packages/hatchet"`. The `tsx` binary is at `node_modules/.bin/tsx` relative to that dir. This is hardcoded (will be configurable later).

## Prompt Design

- Each tool must include the workflow's input schema shape in its prompt snippet so I know what to pass.
- `hatchet_run_status` is for quick health checks (is the run done/failed?).
- `hatchet_run_detail` is for debugging failures (which step failed? what was the error message?).
- `hatchet_workflow_scout/plan/code_lane` dispatch then poll — one call gets the full result.

## Credentials

All tools read `HATCHET_CLIENT_TOKEN`, `HATCHET_TENANT`, `HATCHET_ADDRESS`, `HATCHET_API_URL` from `process.env`. Always `fatal()` with a clear message when missing. Tools must check early and return a clear `error` string.

## Polling Strategy

For dispatch tools (scout/plan/code-lane):

1. Dispatch via CLI → get `runId`
2. Poll `run-detail` every 2-3 seconds via `hatchet_run_detail` (or just call the CLI in a loop)
3. Max 5 minutes (configurable per workflow type)
4. On completion: return full stepResults summary
5. On timeout: return partial results + runId for manual follow-up

## Rules

- Every new hatchet tool = one file. No inline SDK imports.
- Shared helpers (runCli, polling) go in `cli.ts`.
- Tool parameter schemas go in `types.ts`, imported.
- Export a default factory function (as in the existing `analygo-code-review` pattern).
- Use `Type.Object(...)` from `typebox` for parameter schemas (matching Pi's extension API conventions).

## Gotchas

- **CLI-offload means the extension spawns a process, not an import.** The tool does NOT `import` from `@analygo/hatchet`. It spawns `npx tsx scripts/<tool>.ts`.
- **Polling is external.** The tool always returns immediately with a `runId`. Never block inside the tool's `execute`.
- **Prompt design: return JSON with `{ runId, workflow, status, message }`.**
- **Credentials are per-extension, not per-tool.** `config.toml` at the extension root holds `HATCHET_CLIENT_TOKEN`.

## Procedures

### Architecture check before adding a tool
- [ ] Is there an existing Hatchet DAG that does this work? If not, build the DAG first (see `sk-hatchet-dag-new`).
- [ ] Does a CLI back-end script exist? If not, create it in `packages/hatchet/scripts/` (see `sk-hatchet-extension`).
- [ ] Does the extension config have the right credentials? Verify `config.toml`.
- [ ] Test: `npx tsx packages/hatchet/scripts/<tool>.ts --help` works before wiring.

## References

See `sk-hatchet-extension` for the per-tool recipe. See `/.patterns/hatchet/` for the underlying domain/task/DAG patterns.
