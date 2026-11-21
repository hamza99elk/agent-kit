---
name: sk-hatchet-cli
description: Hatchet CLI skills for managing workflows, workers, and runs. Use when triggering workflows, starting workers, debugging runs, replaying runs, running Hatchet locally in embedded mode, or setting up the CLI and profiles.
license: MIT OR Apache-2.0
compatibility: Requires Hatchet CLI, access to a Hatchet server or local embedded mode
---


# Hatchet CLI — Agent Skills

Use this skill when performing Hatchet CLI tasks: installing, profiling, running embedded mode, starting workers, triggering workflows, debugging runs, or replaying runs.

## Quick reference

| Task | Section |
|------|---------|
| Install CLI / create profile | [Setup CLI](#1-setup-cli-install-and-profiles) |
| Run locally with no token | [Embedded mode](#2-embedded-mode) |
| Start a dev worker | [Start worker](#3-start-a-worker) |
| Trigger workflow + poll | [Trigger & watch](#4-trigger-and-watch) |
| Diagnose failure | [Debug run](#5-debug-a-run) |
| Re-run with same/new input | [Replay run](#6-replay-a-run) |

## Conventions

- Local development → embedded mode (no token, account, or server needed).
- Use `-o json` for machine-readable output when parsing responses.
- Write workflow input to a temp file: `/tmp/hatchet-input-$(date +%s)-$$.json`.
- Always clean up temp files after use.

---

## 1. Setup CLI (install and profiles)

### Check if installed

```bash
hatchet --version
```

### Install

**macOS, Linux, WSL:**

```bash
curl -fsSL https://install.hatchet.run/install.sh | bash
```

**macOS via Homebrew:**

```bash
brew install hatchet-dev/hatchet/hatchet --cask
```

### Check existing profiles

```bash
hatchet profile list
```

### Create a profile

```bash
hatchet profile add --name HATCHET_PROFILE --token <API_TOKEN>
```

### Set default profile

```bash
hatchet profile set-default --name HATCHET_PROFILE
```

### Verify connectivity

```bash
hatchet runs list -o json -p HATCHET_PROFILE --since 1h --limit 1
```

### Troubleshooting

- **"command not found"**: Check `~/.local/bin/hatchet` or re-run the install script.
- **Authentication error**: Token may be invalid/expired. Get a new token and run `hatchet profile update`.
- **Connection refused**: Profile points at a server that is not running. Prefer embedded mode for local dev.

---

## 2. Embedded mode

Embedded mode boots a full Hatchet engine inside the worker process, backed by bundled Postgres. No API token, no account, no Docker, no separate server.

**Use embedded mode by default for local development and CI.**

### Create an embedded client

Write a separate one-off script/test file for the embedded dev loop. Do not modify production code.

**TypeScript:**

```typescript
import { HatchetEmbeddedClient } from "@hatchet-dev/typescript-sdk/v1/embedded";

const hatchet = await HatchetEmbeddedClient.init();
```

**Python:**

```python
from hatchet_sdk import Hatchet

hatchet = Hatchet.from_embedded()
```

**Go:**

```go
import (
  hatchet "github.com/hatchet-dev/hatchet/sdks/go"
  _ "github.com/hatchet-dev/hatchet-embedded"
)

client, err := hatchet.NewClient(hatchet.WithEmbedded())
```

### Dev loop

1. Define tasks and start a worker on the embedded client.
2. Trigger a task from the **same process** after the worker has started.
3. Stop the engine before exit:
   - TypeScript: `await hatchet.stopEmbedded()`
   - Python: `hatchet.stop_embedded()`
   - Go: `client.Close(ctx)`

A second process using the embedded entry point boots a **second engine** instead of connecting to the first.

### Traps

- **`HATCHET_CLIENT_TOKEN` overrides embedded mode.** Unset it for embedded runs.
- **Go: engine overwrites `DATABASE_URL`.** Read it before `hatchet.NewClient` if your app uses its own database.
- **First run is slow.** Downloads a sidecar + Postgres (~tens of MB), takes up to 5 minutes. Subsequent runs start in seconds.
- **Pin engine version for reproducibility.** Python/TypeScript download latest by default; use `version` option or `HATCHET_CLIENT_EMBEDDED_VERSION`.

### Optional dashboard

```bash
hatchet embedded-ui
```

---

## 3. Start a worker

### Prerequisites

- A profile pointing at a Hatchet deployment (skip for embedded mode).
- A `hatchet.yaml` in the project root:

```yaml
dev:
  runCmd: "npx ts-node src/worker.ts"
  files:
    - "**/*.ts"
  reload: true
```

Adjust `runCmd` per language:

- Python: `poetry run python src/worker.py`
- TypeScript: `npx ts-node src/worker.ts`
- Go: `go run ./cmd/worker`

### Start in background terminal

```bash
hatchet worker dev -p HATCHET_PROFILE
```

### Notes

- Worker **must be running** before triggering workflows.
- `reload: true` auto-restarts on file changes.
- Stop auto-reload: `--no-reload`.
- Override run command: `--run-cmd "your command here"`.
- Optional `preCmds` in `hatchet.yaml` run before the worker starts.

---

## 4. Trigger and watch

### Prerequisites

- A running worker.
- Known workflow name and input JSON.

### Write input to temp file

```bash
HATCHET_INPUT_FILE="/tmp/hatchet-input-$(date +%s)-$$.json"
cat > "$HATCHET_INPUT_FILE" << 'ENDJSON'
INPUT_JSON
ENDJSON
```

### Trigger

```bash
RUN_ID=$(hatchet trigger manual -w WORKFLOW_NAME -j "$HATCHET_INPUT_FILE" -p HATCHET_PROFILE -o json | jq -r '.runId')
```

### Poll until terminal

```bash
hatchet runs get $RUN_ID -o json -p HATCHET_PROFILE
```

Terminal statuses: `COMPLETED`, `FAILED`, `CANCELLED`.
Non-terminal: `QUEUED`, `RUNNING`.

### Handle failure

```bash
hatchet runs logs $RUN_ID -p HATCHET_PROFILE
hatchet runs events $RUN_ID -o json -p HATCHET_PROFILE
```

### Clean up

```bash
rm -f "$HATCHET_INPUT_FILE"
```

### Common issues

- **Task stays QUEUED**: No worker running, or task name mismatch.
- **Task FAILED immediately**: Check logs for stack trace.
- **Task CANCELLED**: External cancellation — check events.

---

## 5. Debug a run

### Get run state

```bash
hatchet runs get RUN_ID -o json -p HATCHET_PROFILE
```

Check: `.run.status`, `.run.displayName`, `.run.input`, `.tasks[]` (status, output, errorMessage, timing).

### Get event log

```bash
hatchet runs events RUN_ID -o json -p HATCHET_PROFILE
```

Events have: `eventType`, `message`, `taskDisplayName`, `timestamp`.

### Get application logs

```bash
hatchet runs logs RUN_ID -p HATCHET_PROFILE
```

### Diagnostic cheat sheet

| Symptom | Cause |
|---------|-------|
| Task QUEUED (no STARTED) | No worker running, task name mismatch, wrong profile/tenant |
| Task FAILED | Unhandled exception, timeout, dependency unavailable |
| Task CANCELLED | Manual cancellation, parent cancellation, timeout |
| Wrong output | Check `.tasks[].output`, logs, and `.run.input` |
| Slow execution | Compare `startedAt`/`finishedAt` across tasks to find bottleneck |

---

## 6. Replay a run

### Inspect the original

```bash
hatchet runs get RUN_ID -o json -p HATCHET_PROFILE
```

Note `.run.displayName`, `.run.input`, `.run.status`, `.tasks[].errorMessage`.

### Replay with same input

```bash
hatchet runs replay RUN_ID -o json -p HATCHET_PROFILE
```

New run IDs in `.ids[]`.

### Replay with new input

```bash
HATCHET_INPUT_FILE="/tmp/hatchet-input-$(date +%s)-$$.json"
cat > "$HATCHET_INPUT_FILE" << 'ENDJSON'
NEW_INPUT_JSON
ENDJSON
RUN_ID=$(hatchet trigger manual -w WORKFLOW_NAME -j "$HATCHET_INPUT_FILE" -p HATCHET_PROFILE -o json | jq -r '.runId')
rm -f "$HATCHET_INPUT_FILE"
```

### Watch the new run

```bash
hatchet runs get $RUN_ID -o json -p HATCHET_PROFILE
```

## Gotchas

- **`hatchet` commands need a profile or token.** Without `--profile` or `HATCHET_CLIENT_TOKEN`, commands default to the `default` profile. Run `hatchet profile list` first.
- **Embedded mode bypasses the cloud.** `hatchet server start` runs a local lite engine — no token, no account, no internet needed.
- **`-o json` returns stderr warnings.** Redirect stderr (`2>/dev/null`) when parsing programmatically.
- **Workers take seconds to register.** After `hatchet worker start`, wait 5-10s before checking `hatchet worker list`.

## Procedures

### Diagnose a failed run

1. Get the run ID: `hatchet run list -o json`
2. Inspect: `hatchet run get <runId> -o json`
3. Read `steps[].error` for the failing task
4. Replay: `hatchet run replay <runId>`
5. For new input: `hatchet run trigger <dagName> /tmp/input.json`

### Start a local dev environment

- [ ] Start engine: `hatchet server start`
- [ ] Wait for "server listening" log
- [ ] Start worker: `hatchet worker start --name dev-worker`
- [ ] Verify: `hatchet worker list` shows the worker
- [ ] Verify: `hatchet run list -o json | head` shows recent runs

## References

See `/.patterns/hatchet/` for the contract, task, and DAG patterns that define the workflows these CLI commands interact with.
