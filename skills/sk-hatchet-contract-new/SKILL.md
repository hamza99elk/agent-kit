---
name: sk-hatchet-contract-new
description: >
  Author contracts — place every schema in the right layer, register it, and
  compose task/DAG I/O envelopes. The core rule is data-schema
  (concepts/projections) vs envelope (workflows). Canonical examples:
  concepts/ticket-fetch.ts + workflows/git-ticket-read-contracts.ts.
license: MIT OR Apache-2.0
compatibility: Works within the Analygo contracts layer (packages/contracts/src/)
---


# Contract Authoring

Contracts are Zod-only, in `packages/contracts/src`. Authoritative sources:
`src/primitives|concepts|projections|workflows/`, `src/domains/registery.ts`,
`src/templates/task/validate.ts`.

---

## 1. Two things, never confused

| | **DATA SCHEMA** | **I/O ENVELOPE** |
|---|---|---|
| what | the actual `.strict()` shape | `{ key: DataSchema }` handed to a task/DAG |
| where | `concepts/` or `projections/` | `workflows/` |
| defined | once, canonically | composes data schemas (never redefines) |
| registered | **YES** (`registery.ts`) | no |
| example | `TicketFetchResultSchema` | `TaskGitContextOutputSchema` |

The envelope is what `defineTask({ output })` / `checkDag` see. The data schema is what the
envelope keys. A schema used in a task `output`/`upstream` **must** be a registered data
schema — the template's `validateFields()` checks registry identity and throws otherwise.

---

## 2. Pick the layer (primitives → concepts → projections → workflows)

| Shape | Layer | e.g. |
|---|---|---|
| atomic field | `primitives/` | `RepoPathSchema`, `CountSchema` |
| domain noun | `concepts/` | `RepoResolveResultSchema`, `TicketFetchResultSchema` |
| derived output with cross-field invariant | `projections/` | `NeighborhoodSchema` |
| task/DAG envelope | `workflows/` | `TaskGitContextOutputSchema`, `DagGitTicketReadOutputSchema` |

Layer N imports only from N or lower (`check:deps`).

---

## 3. Data schema (concepts/)

```ts
// concepts/ticket-fetch.ts
import { z } from "zod";

export const TicketFetchResultSchema = z.object({
  ok: z.boolean(),
  state: z.string(),
  error: z.string().nullable(),    // null on success — explicit, not optional
  number: z.number().int().nonnegative(),
  repo: z.string(),
}).strict();
```

Rules: `.strict()` at every boundary · types are `z.infer<typeof Schema>` in a `*-types.ts`
companion (no-god-file) · **no `.default()`** to mask a missing required field (Zod default
hides "unset" — let it error) · `.passthrough()` only for raw external payloads (webhook /
API), flagged with a comment containing "external" · cross-field invariants via
`.superRefine()` with a field-precise `path`.

---

## 4. Task/DAG envelope (workflows/)

Name a family file after the DAG: `dag-{family}.ts` → `{family}-contracts.ts`
(`check:workflow-contracts`). Compose, don't redefine:

```ts
// workflows/git-ticket-read-contracts.ts
import { z } from "zod";
import { GitHubTicketSchema } from "../domains/github/types.js";
import { GitSchema } from "../concepts/repository.js";
import { TicketFetchResultSchema } from "../concepts/ticket-fetch.js";
import { TaskSignalSchema, TaskEventsSchema } from "../primitives/task.js";

export { GitHubTicketSchema, GitSchema, TicketFetchResultSchema };  // re-export for tasks

export const TaskGitContextOutputSchema = z.object({
  ticket: GitHubTicketSchema,
  git: GitSchema,
  fetch: TicketFetchResultSchema,
  task: TaskSignalSchema,
  events: TaskEventsSchema,
}).strict();
```

Add the family file to `workflows/index.ts`. (TS's `export *` doesn't propagate *named
re-exports* — if consumers need a schema that a contracts file only re-exports, add an explicit
`export { X } from "./…"`.)

---

## 5. Register the data schema

```ts
// domains/registery.ts — imports
import { TicketFetchResultSchema as _TicketFetchResultSchema } from "../concepts/ticket-fetch.js";
// registery.ts — register
register("TicketFetchResultSchema", _TicketFetchResultSchema);
```

`validateFields()` in the task template matches by **identity** (`regSchema === schema`), so a
schema defined inline in `workflows/` and never registered throws at module load. Register
from the layer it's defined in — never from `workflows/`.

---

## 6. Anti-patterns (these all fail a gate or throw at load)

- ❌ Data schema defined in `workflows/` → unregistered → task throws at load.
- ❌ Tool schema (`@analygo/tools/...`) in a task `output` → not registered → throws.
- ❌ `z.string().default("")` masking a required field → silent empty propagates.
- ❌ `.passthrough()` on an internal shape → shadow state; use `.strict()`.
- ❌ Hand-typed `type X = { … }` → use `z.infer<typeof XSchema>`.
- ❌ `dag-*.ts` with no `{family}-contracts.ts` → `check:workflow-contracts` fails.

---

## 7. Checklist

- [ ] Data schema in `concepts/`/`projections/`, `.strict()`, registered in `registery.ts`.
- [ ] Type in a `*-types.ts` companion via `z.infer` (no value+type mix in one file).
- [ ] Envelope in `workflows/`, composing data schemas; re-exported from the family file.
- [ ] Family file name matches the DAG; exported from `workflows/index.ts`.
- [ ] No `.default()` masking, `.passthrough()` only on external payloads.
- [ ] Invariants via `.superRefine()` with field-precise paths.

## Gotchas

- **Every schema must be registered.** `register()` calls in `domains/registery.ts` are mandatory. An unregistered schema passes `tsc` but fails the contract-validate gate.
- **Task/DAG I/O schemas go in `workflows/`, not `concepts/` or `projections/`.** The workflow file is an envelope — never define new data shapes there.
- **`z.infer` types go in companion `*-types.ts`.** The `no-god-file` ESLint rule rejects mixed value+type exports.
- **`.strict()` before `.nullable()`.** Zod requires `.strict()` called on the object before `.nullable()`.
- **No `.default({})` on health/dashboard schemas.** Empty record = "no data"; null = "not yet computed".

## Procedures

### Add a new contract schema
- [ ] Determine layer: `primitives/`, `concepts/`, `projections/`, or `workflows/`
- [ ] Create `<layer>/<name>.ts` with `.strict()` Zod object
- [ ] Create companion `<layer>/<name>-types.ts` with `z.infer` types
- [ ] Export from the layer's barrel (`index.ts`)
- [ ] Register in `domains/registery.ts` with `register("SchemaName", _SchemaName)`
- [ ] Run `tsc --noEmit` — must pass

## References

See `/.patterns/hatchet/hatchet-contract/` for the canonical contract pattern with intent, spec, anti-patterns, and tests.
