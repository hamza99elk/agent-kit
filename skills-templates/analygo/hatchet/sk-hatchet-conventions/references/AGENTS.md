<!-- This is a reference copy. The authoritative engineer persona is embedded
     in the Hatchet worker session (sk-hatchet-engineer). When the AI SDK
     agent loads this file, it gets the full non-negotiables table. -->

# Hatchet Engineer Persona — Full Reference

## Non-negotiables (these fail the build — do not "know better")

1. **No inline Zod.** `import { z }` is FORBIDDEN in any `tasks/` or `workflows/` file.
   All I/O shapes are registered primitives imported from `@analygo/contracts`.
2. **Registered primitives only.** Every schema in `defineTask({ output, upstream })` must be
   in `contracts/src/domains/registery.ts`. The template throws at module load otherwise.
3. **`task: signal(...)` in EVERY return path** of every `execute`. `tsc` cannot catch a miss —
   only `check:task-signal` can. This is the single most common regression.
4. **`adapt: (raw) => raw`** whenever `output` is declared.
5. **Layer N imports from N or lower.** Never up. Enforced by `depcruise`.
6. **Root task reads `event`; children read `upstream`.** Only a `task-C-` (context) root may
   touch the event; `check:task-event-read` enforces it.

## Layers, in one glance

```
primitives/  atoms               path, count, symbol, language, identity, time, collection
concepts/     domain nouns        file, graph, plan, work, judgment, scouting, ticket-facts
projections/  invariants          outputs with cross-field superRefine (neighborhood, skeleton)
workflows/    I/O envelopes       { key: DataSchema } — what tasks/DAGs import
```

## Gates are the spec — run them, don't memorise them

| Gate | Catches |
|---|---|
| `check:contracts` | inline Zod / non-`@analygo/contracts` contract types |
| `check:deps` | layer violations, task→task imports |
| `check:dag-defaults` | `?? "low"` re-defaulting a schema default; `?? {}` masking missing upstream |
| `check:contract-validate` | child `upstream` keys ≠ parent `output` keys |
| `check:task-signal` | any `execute` path missing `task: signal(...)` |
| `check:task-event-read` | a non-root task reading `event` |
| `check:workflow-contracts` | a `dag-*.ts` with no `{family}-contracts.ts` |

## Naming — `task-{kind-prefix}{platform}-{action}`

Kind prefix is the **only** thing before the platform.

| kind | prefix | when |
|---|---|---|
| regular | `task-` | atomic step |
| **context** | `task-C-` | **root of an event-sourced DAG that shapes the event into context** |
| durable | `task-D-` | checkpointed loop / wait |
| spawn | `task-S-` | children.run() one child |
| fanout | `task-F-` | bulk fire-and-forget children |
| ai | `task-ai-` | calls an LLM |
| jev | `task-jev-` | reads/writes JEV domain objects |

## The one snippet that is always true — a task

```ts
export const taskX = defineTask({
  name: "task-{kind}{platform}-{action}",
  category: "generic",
  withEvent: "external",              // root (t0) only
  upstream: { key: RegisteredSchema },
  output:   { key: RegisteredSchema },
  adapt: (raw) => raw,                // REQUIRED iff output declared
  execute: async ({ upstream, event, log }) => {
    const data = upstream.key;        // children: read by CONTRACT KEY
    if (!data) throw new Error("task-X: missing key from upstream task-Y");
    return { key: result, task: signal("ok", "…") };
  },
});
```

## Pre-push checklist

- [ ] `npm run typecheck` clean — `packages/contracts` **and** `packages/hatchet`
- [ ] `npm run check:all` clean
- [ ] `npm run test` green
- [ ] Every task: `signal(...)` on every path, `adapt` if `output`, registered schemas only
- [ ] Every upstream read guarded (`if (!x) throw`), never defaulted
- [ ] DAG: registered in `all-dags.ts`, topology comment matches wiring, `emit`/`onFailure` present
- [ ] Contract family file exists for the DAG; task has a boundary spec (`check:task-coverage`)