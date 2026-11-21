---
name: sk-hatchet-dag-new
description: >
  Author one self-contained Hatchet DAG file. Use when wiring
  parents/parentsMap, choosing the event trigger, and emitting terminal
  CloudEvents via the emit/onFailure hooks. Requires a matching
  {family}-contracts.ts. Canonical examples: dag-git-ticket-read (single
  context root + emit), dag-scout (multi-task).
license: MIT OR Apache-2.0
compatibility: Works within the Analygo Hatchet execution engine (packages/hatchet/src/workflows/)
---

# DAG Authoring

One DAG = `workflows/dag-{family}.ts`, owning metadata + I/O + wiring via `defineDag()`.
Tasks are imported `defineTask()` registrations. No inline tasks, no inline Zod, no hand wiring.

**Every `dag-{family}.ts` needs a matching `contracts/src/workflows/{family}-contracts.ts`**
(exported from its `index.ts`) — `check:workflow-contracts` fails otherwise. The contract file
holds the DAG's `input`/`output` envelopes, composing registered data schemas.

Authoritative sources: `contracts/src/templates/dag/{define-dag,types}.ts`,
`hatchet/src/workflows/check-dag.ts`.

---

## 1. Skeleton

```ts
// =============================================================================
// workflows/dag-git-ticket-read.ts — <what, trigger, what it emits>.
//
// Topology:
//   t0 (task-C-git-context) ──► emit co.analygo.github.ticket.read.v1
//
// TRIGGER: onEvents: ["co.analygo.code-plan.scouted.v1"]
// =============================================================================
import { defineDag } from "@analygo/contracts/templates";
import { GitHubTicketSchema, GitSchema, TicketFetchResultSchema } from "@analygo/contracts/workflows";
import { CODE_PLAN_TYPE_SCOUTED } from "../events/types.js";
import { TicketRead } from "../events/ticket-events.js";
import { taskCGitContext } from "../tasks/task-C-git-context.js";

export const dagGitTicketRead = defineDag({
  dag: {
    dagName: "dag-git-ticket-read",
    dagDescription: "<one line>",
    dagID: "dag-git-ticket-read",
    dagVersion: "1.0.0",
    dagTasks: ["task-C-git-context"],
  },
  hatchet: { runId: "dag-git-ticket-read", dagName: "dag-git-ticket-read" },

  withEvent: "external",                 // event-sourced — .passthrough() input
  onEvents: [CODE_PLAN_TYPE_SCOUTED],    // NAMED constant, never a literal
  // defaultFilters: [NAMED_FILTER],     // only when a CEL gate is needed

  input: {},                             // event arrives via withEvent
  output: {                              // the run's WORK RECORD — all domain prims
    ticket: GitHubTicketSchema.nullable(),
    git: GitSchema.nullable(),
    fetch: TicketFetchResultSchema.nullable(),
  },

  tasks: ({ dag }) => {
    const _t0 = taskCGitContext(dag);                    // root: no parents
    // const t1 = taskX(dag, { parents: [_t0], parentsMap: { key: "task-C-git-context" } });
  },
  emit: (outputs) => { /* §3 */ },
  onFailure: () => ({ result: { /* honest nulls */ } }),
});
```

Register in `workflows/all-dags.ts`:
```ts
import { dagGitTicketRead } from "./dag-git-ticket-read.js";
export const allDags = [ /* … */ dagGitTicketRead ];
```

---

## 2. parentsMap — CONTRACT key → PARENT TASK NAME

```ts
const t1 = taskX(dag, {
  parents: [t0, t0b],                            // wait for ALL listed (parallel join)
  parentsMap: {
    key:        "task-C-git-context",            // key  = child's `upstream` contract key
    otherKey:   "task-oxc-index-repo",           // value= the task that produced it
  },
});
```

- key = the **child's declared `upstream` contract key** (only the child knows it).
- value = the **parent task name** (string — never an object).
- `checkDag` verifies: every `upstream` key is wired, every value is a real task name, acyclic.

---

## 3. Terminal emission — `emit` / `onFailure` (NOT `onSuccess`)

`onSuccess({ deriveEventType, shapePayload })` is legacy. Use the hooks:

```ts
emit: (outputs) => {
  const t = outputs["task-C-git-context"] as { ticket?: unknown; git?: unknown; fetch?: { ok?: boolean } } | undefined;

  if (t?.fetch?.ok !== true) return { result: { ticket: null, git: null, fetch: t?.fetch ?? null } };

  const payload = TicketRead.parse({ ticket: t.ticket, git: t.git });   // validate BEFORE dispatch
  return { result: payload, emit: { definition: TicketRead, payload, /* scope? */ } };
},

onFailure: () => ({ result: { ticket: null, git: null, fetch: null } }),
```

Rules:
- **`emit` runs only if every task succeeded.** A DAG with tasks but no `onFailure` dies
  silently on a task throw — `checkDag` warns (`no-on-failure-hook`). Always add it.
- Two channels: `result` = the declared `output` work record; `emit` = the CHAIN event.
  A hook may also return bare emit spec(s) as shorthand for `{ emit: … }`.
- **Return `null` / omit `emit` to announce nothing.** Never fabricate an event that would
  start downstream work on unverified data (failed fetch, empty context).
- Validate the payload through the event definition's schema (`.parse`) before returning — a
  throw is surfaced as a `partial` signal, never a silent non-dispatch.
- Event **type constants** live in `events/types.ts`; the typed **definitions** live in
  `events/{ticket-events,scout,execution}.ts` (`defineCloudEvent`). A DAG emits the
  *definition*; consumers filter on its `.type`.

---

## 4. Event-sourced DAGs

```ts
withEvent: "external",            // passthrough raw event; the root task parses it
onEvents: [CODE_PLAN_TYPE_SCOUTED],           // named constant
defaultFilters: [GITHUB_..._FILTER],          // named constant; omit if no gate
```

Only the root (`task-C-`/regular-with-`withEvent`) reads `event`; children read `upstream`.
A filter `scope` that doesn't match the producer's `scope_expression` = zero runs, no error.

---

## 5. Topology comment — mandatory

Every DAG file opens with an ASCII diagram of the exact parent edges. It is the design doc;
if it and the wiring disagree, one is wrong.

---

## 6. Checklist

- [ ] One file, `defineDag()` — no inline tasks, no inline Zod.
- [ ] Topology comment matches the wiring.
- [ ] `parentsMap` keys = child `upstream` keys, values = parent task names (strings).
- [ ] `emit` (with `.parse` validation) and `onFailure` both present; nothing fabricated.
- [ ] Event keys/filters are named constants.
- [ ] `output` declared (or `output: {}` explicit) — from registered primitives / the family
      contract file.
- [ ] Matching `contracts/src/workflows/{family}-contracts.ts`, exported from its `index.ts`.
- [ ] Registered in `all-dags.ts`.
- [ ] Topology test + `checkDag` green (`sk-hatchet-test-new`).

## Gotchas

- **Every DAG must have both `emit` and `onFailure`.** A DAG with tasks but no `onFailure` dies silently when a task throws. `checkDag` warns (`no-on-failure-hook`).
- **`parentsMap` keys = child `upstream` contract keys, values = parent task name strings.** Never use an object as the value.
- **Event keys/filters must be named constants.** Import from `events/types.ts` and `@analygo/contracts/filters`.
- **`emit` payloads must be validated through `.parse()` before returning.** A throw is surfaced as a partial signal, never a silent non-dispatch.
- **Topology comment must match wiring.** The ASCII diagram at the top of each DAG file is the design doc.

## Procedures

### Wire a new DAG
- [ ] Create `contracts/src/workflows/{family}-contracts.ts` with I/O envelopes
- [ ] Write each task as a separate `defineTask()` in `tasks/`
- [ ] Create DAG file: `workflows/dag-{family}.ts`
- [ ] Add topology comment (ASCII diagram of parent edges)
- [ ] Wire `defineDag()` with `onEvents`, `defaultFilters`, `tasks`, `emit`, `onFailure`
- [ ] Register in `workflows/all-dags.ts`
- [ ] Verify: `checkDag` test passes

## References

See `/.patterns/hatchet/hatchet-dag/` and `/.patterns/hatchet/hatchet-event-sourced-dag/` for canonical examples with tests.
