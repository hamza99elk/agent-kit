---
name: sk-hatchet-task-new
description: >
  Author one self-contained Hatchet task file. Use when creating task-*.ts,
  choosing the kind prefix (task- vs task-C- context), picking upstream
  contracts, and putting task signal on every return path. Canonical root
  example: task-C-scout-context. Canonical parented example:
  task-oxc-index-repo.
license: MIT OR Apache-2.0
compatibility: Works within the Analygo Hatchet execution engine (packages/hatchet/src/tasks/)
---

# Task Authoring

One task = one file = one `defineTask()` + its handler. No separate contract file, no inline
Zod, no `dag.task()`.

Authoritative sources (read them, they win):
`packages/contracts/src/templates/task/{define-task,naming,kind-prefixes,validate,types}.ts`.

---

## 1. Pick the kind — this decides the name prefix and the vector

| You are writing… | kind | prefix | reads |
|---|---|---|---|
| the **root** of an event-sourced DAG, shaping the event into context | `context` | `task-C-` | `event` |
| a plain atomic step, **including a regular root** | `regular` | `task-` | `event` (if root) / `upstream` |
| a checkpointed loop/wait | `durable` | `task-D-` | — |
| a task that awaits one child DAG | `spawn` | `task-S-` | — |
| a task that fires N children | `fanout` | `task-F-` | — |
| an LLM call | `ai` | `task-ai-` | — |
| a JEV read/write | `jev` | `task-jev-` | — |

`task-C-` means **context, always**: the single task that may read `event` in an event-sourced
DAG and project it into the context every child consumes. `check:task-event-read` rejects a
non-root task that reads `event`. A *regular* root (`task-git-repo-resolve`) is also allowed to
read `event` by virtue of `withEvent: "external"` — but prefer `task-C-` when the task's job
is "normalise the trigger for children".

Name = `task-{kind-prefix}{platform}-{action}`; `{platform}` from `PLATFORM_NAMES`
(`naming.ts`). `task-C-git-context` ✅ · `task-git-context` ❌ (context kind without prefix).

---

## 2. Skeleton — root vs parented

```ts
// =============================================================================
// tasks/task-C-git-context.ts — <one line>
//
// VECTOR:    root (event) | parented — reads upstream.<key>
// DEPENDS:   <parent task> | none
// PRODUCES:  <OutputType>
// =============================================================================
import { defineTask, signal } from "@analygo/contracts/templates";
import { SomeSchema, TicketFetchResultSchema } from "@analygo/contracts/workflows";
import { someDomainFn } from "../domains/<area>/<name>.js";

export const taskCGitContext = defineTask({
  name: "task-C-git-context",
  category: "generic",                       // REQUIRED
  withEvent: "external",                     // root only
  output: { ticket: SomeSchema, fetch: TicketFetchResultSchema },  // registered primitives
  adapt: (raw) => raw,                       // REQUIRED iff output declared
  execute: async ({ event, log }) => {
    // ── root: unwrap the event ONCE, then validate ──
    const outer = (event as Record<string, unknown> | undefined);
    if (!outer) throw new Error("task-C-git-context: no event payload");
    const payload = (outer.input as Record<string, unknown> | undefined) ?? outer;

    const r = someDomainFn(payload);          // pure domain atom does the work
    return { ticket: r.ticket, fetch: r.fetch, task: signal("ok", `…`) };
  },
  executionTimeout: "30s",
  retries: 0,
});
```

### Parented variant — read upstream by CONTRACT KEY

```ts
  upstream: { repoResolve: RepoResolveResultSchema, index: RepoIndexSchema },
  execute: async ({ upstream, log }) => {
    const worktree = upstream.repoResolve?.worktree;
    if (!worktree) throw new Error("task-X: missing worktree from upstream task-git-repo-resolve");
    // return { index, task: signal(...) }
  },
```

The handler NEVER names the parent task — the DAG's `parentsMap` binds contract key → task
name. Reading `upstream.<contractKey>` is the only correct access.

---

## 3. `signal` — the rule that bites

Every `execute` return path needs `task: signal(status, reason)`:

```ts
signal("ok",       "fetched acme/widget#42 (2 labels)")
signal("partial",  "fetched but returned no title")
signal("error",    "fetch failed: gh 404")
```

The `execute` return TYPE omits `task` (the template appends it at parse time), so **`tsc`
will not catch a missing signal** — only `check:task-signal`. If a handler has 3 branches,
it has 3 signals. No exceptions (including early-return guards and catch branches).

Other rules:
- **Never default a missing upstream** (`?? {}`, `?? "low"`, `?? 0`). Throw — a missing
  required upstream means the topology is broken. `check:dag-defaults` flags masked defaults.
- All `output`/`upstream` values are **registered** primitives. Tool schemas
  (`@analygo/tools/*`) are NOT registered — normalise tool output into a contracts schema in
  the handler; never put a tool schema in `output`.
- Business logic lives in a pure domain atom (`src/domains/**`): no ctx/env/SDK, never throws.
- Handler returns **domain fields only** — `task`/`dag`/`runId` are injected by the template.

---

## 4. Checklist

- [ ] One file, `defineTask()` only — no `dag.task()`, no inline Zod.
- [ ] kind/prefix correct (`task-C-` only for the context root).
- [ ] `category` present.
- [ ] `adapt: (raw) => raw` if `output` declared.
- [ ] `signal(...)` on EVERY return path (3 branches → 3 signals).
- [ ] Every upstream read guarded with `if (!x) throw` — no silent defaults.
- [ ] All I/O schemas registered primitives; tool output normalised, not wired directly.
- [ ] Non-trivial logic is a pure domain atom.
- [ ] Boundary spec exists: `tests/workflow/<basename>.task.spec.ts` (`check:task-coverage`).
      See `sk-hatchet-test-new`.

## Gotchas

- **`tsc` does not catch a missing `signal`** — only `check:task-signal` does. Every path needs `task: signal("ok"|"partial"|"error", "reason")`.
- **Never default a missing upstream.** `?? {}` masks a broken topology. Throw with a clear message.
- **`adapt: (raw) => raw` is required when `output` is declared.** The template rejects output schemas without an adapter fn.
- **Domain types must not end with Schema/Input/Output/Result.** The `check:contracts` gate treats these suffixes as violations unless from `@analygo/contracts`.
- **Tool schemas are NOT registered.** Normalise tool output into a contracts schema in the handler.

## Procedures

### Write a new task handler
- [ ] Determine kind: `context` (`task-C-`) for event-sourced roots, `regular` (`task-`) for everything else
- [ ] Create `tasks/task-{kind}{platform}-{action}.ts`
- [ ] Import `defineTask`, `signal` from `@analygo/contracts/templates`
- [ ] Import output/upstream schemas from `@analygo/contracts/workflows` or `@analygo/contracts/projections`
- [ ] Import domain fn from `../domains/<area>/<name>.js`
- [ ] Declare `withEvent: "external"` or `upstream: { key: Schema }`
- [ ] Add `adapt: (raw) => raw`
- [ ] Write `execute` handler with `task: signal(...)` on every return path
- [ ] Guard every upstream read: `if (!x) throw`

## References

See `/.patterns/hatchet/hatchet-task/` for the canonical task pattern. See `/.patterns/hatchet/reusable-task-upstream-contract/` for the parented task pattern.
