---
name: sk-hatchet-event-new
description: >
  Author one event from end to end: its scope (routing label), its filter
  (CEL + scope), and its CloudEvent definition (type + source + data
  schema). Every piece is stamped from a factory in `contracts` — no
  hand-rolled CEL, no inline filter objects, no scope string literals.
  Use when adding a new platform (S3, Linear) or a new webhook action for
  an existing platform.
license: MIT OR Apache-2.0
compatibility: Works across the contracts layer (scopes/filters) and hatchet layer (events/)
---

# sk-hatchet-event-new — Event type, filter, and scope authoring

The rule: **one event has one name, one data schema, and one home in `contracts/src/events/`**.
The filter and scope that gate it are stamped from the same factory — no hand-rolled CEL strings,
no inline filter objects, no platform-specific routing logic leaking into DAG wiring.

Three things to create for a new event:

1. **Scope constant** — the routing label (`"analygo:<platform>:<stage>:<action>"`), stamped
   by `defineScope()`.
2. **Filter constant** — the CEL expression + scope, stamped by `defineFilter()`, ready for
   DAG `defaultFilters`.
3. **CloudEvent definition** — the typed event (`type`, `source`, `dataSchema`), stamped by
   `defineCloudEvent()`.

All three live in `contracts/src/events/<platform>.ts`. The DAG imports the filter constant
from `@analygo/contracts/events` and drops it into `defaultFilters`. Zero CEL in the DAG file,
zero scope string literals, zero hand-rolled filter objects.

---

## Where things live

| What | Canonical home | Example |
|---|---|---|
| Scope constants | `contracts/src/events/<platform>.ts` | `GITHUB_SCOPE_INBOX_OPENED` |
| Filter constants | `contracts/src/events/<platform>.ts` | `GITHUB_ISSUES_OPENED` |
| CloudEvent definitions | `contracts/src/events/<platform>.ts` | `co.analygo.github.ticket.opened.v1` |
| Event payload schemas | `contracts/src/domains/` or `contracts/src/concepts/` | `GitHubOpenedEventPayloadSchema` |
| Scope shorthands | `contracts/src/templates/scopes.ts` | `defineScope("github", "inbox", "opened")` |
| Filter factory | `contracts/src/templates/filter-template.ts` | `defineFilter({ name, expression, scope })` |
| Event type constants (wire format) | `hatchet/src/events/types.ts` | `GITHUB_TYPE_TICKET_OPENED` |
| Emit hooks / fallbacks | `hatchet/src/events/` | `ticket-events.ts`, `ticket-fallbacks.ts` |

---

## Step-by-step

### 1. Define the scope

In `contracts/src/events/github.ts` (or your platform's file — `s3.ts`, `linear.ts`, etc.):

```ts
import { defineScope } from "../templates/scopes.js";
import { defineFilter } from "../templates/filter-template.js";

export const GITHUB_SCOPE_INBOX_FIELD_ADDED = defineScope("github", "inbox", "field-added");
```

The convention is `"analygo:<platform>:<stage>:<action>"`:
| Part | Meaning | Examples |
|---|---|---|
| `analygo` | Fixed prefix — identifies the routing domain | — |
| `<platform>` | The origin system | `github`, `s3`, `linear` |
| `<stage>` | Pipeline stage | `inbox` (raw webhook), `ready` (classified), `update` (re-evaluation needed) |
| `<action>` | Specific event discriminator | `opened`, `field-added`, `commented`, `object-created` |

### 2. Define the filter

Same file, below the scope constant:

```ts
export const GITHUB_ISSUES_FIELD_ADDED_START_DATE = defineFilter({
  name: "github-issues-field-added-start-date",
  expression: "input.issue_field.id == 35221871",
  scope: GITHUB_SCOPE_INBOX_FIELD_ADDED,
});
```

`defineFilter` validates through `HatchetFilterSchema` and returns the exact
`{ expression, scope, payload? }` triple. The `name` is consumed for documentation
and gate introspection but is NOT included in the return value — Hatchet would
reject unknown properties.

### 3. Define the CloudEvent

```ts
import { defineCloudEvent } from "../templates/cloud-event-template.js";
import { GitHubFieldAddedEventPayloadSchema } from "../domains/github/payloads.js";
import { GITHUB_TYPE_TICKET_FIELD_ADDED } from "./type-constants.js";

export const TicketFieldAdded = defineCloudEvent({
  type: GITHUB_TYPE_TICKET_FIELD_ADDED,       // "co.analygo.github.ticket.field_added.v1"
  source: "analygo://github",
  dataSchema: GitHubFieldAddedEventPayloadSchema,
});
```

### 4. Wire into the DAG

In the DAG file (`dag-git-ticket-read.ts` or a new `dag-s3-ingest.ts`):

```ts
import { GITHUB_ISSUES_FIELD_ADDED_START_DATE } from "@analygo/contracts/events";

export const dagGitTicketRead = defineDag({
  onEvents: [GITHUB_WEBHOOK_EVENT_KEY_ISSUES_FIELD_ADDED],
  defaultFilters: [GITHUB_ISSUES_FIELD_ADDED_START_DATE],
  // ...
  emit: (outputs) => ({
    definition: TicketFieldAdded,
    payload: { ... },
    scope: GITHUB_SCOPE_READY_OPENED,       // or appropriate ready scope
  }),
});
```

That's it. The DAG never writes `expression: "..."` inline — it imports a named filter.
The webhook's `scope_expression` CEL string is the only CEL you ever set by hand,
and it's a one-time config per webhook endpoint.

---

## Adding S3 (the test)

```ts
// contracts/src/events/s3.ts
import { defineScope } from "../templates/scopes.js";
import { defineFilter } from "../templates/filter-template.js";
import { defineCloudEvent } from "../templates/cloud-event-template.js";

export const S3_SCOPE_INBOX_OBJECT_CREATED = defineScope("s3", "inbox", "object-created");
export const S3_SCOPE_READY_OBJECT_CREATED  = defineScope("s3", "ready", "object-created");

export const S3_OBJECT_CREATED = defineFilter({
  name: "s3-object-created",
  expression: "true",
  scope: S3_SCOPE_INBOX_OBJECT_CREATED,
});

export const S3ObjectCreated = defineCloudEvent({
  type: "co.analygo.s3.object.created.v1",
  source: "analygo://s3",
  dataSchema: S3ObjectCreatedPayloadSchema,
});
```

Then `hatchet/src/workflows/dag-s3-ingest.ts`:

```ts
import { S3_OBJECT_CREATED } from "@analygo/contracts/events";
import { S3_SCOPE_READY_OBJECT_CREATED } from "@analygo/contracts/events";

export const dagS3Ingest = defineDag({
  onEvents: ["s3:object:created"],
  defaultFilters: [S3_OBJECT_CREATED],
  // ...
  emit: (outputs) => ({
    definition: S3ObjectCreated,
    payload: { key, bucket, size },
    scope: S3_SCOPE_READY_OBJECT_CREATED,
  }),
});
```

No new CEL, no new factory, no new wiring pattern. One file in `contracts/src/events/`,
one DAG, done.

---

## What NOT to do

| Anti-pattern | Why |
|---|---|
| `expression: "true"` inline in a DAG's `defaultFilters` | Unnamed, unreusable, no validation. Extract to a named constant via `defineFilter()`. |
| Hand-rolled scope string literal | Typo risk, no convention enforcement. Use `defineScope("github", "ready", "opened")`. |
| CEL expression in a DAG file | CEL is opaque; it fails silently if unparseable. Validate through `defineFilter()` at definition time. |
| Event type string in a DAG file | Use the typed constant from `types.ts` or the CloudEvent definition. A typo silently routes to zero consumers. |
| Re-declaring a scope in hatchet when it's already in contracts | Scopes are contracts — one definition, one home (`contracts/src/events/`). Hatchet imports them. |

## Gotchas

- **Every event needs three pieces: scope, filter, and CloudEvent definition.** Missing any one = event never fires or never matches.
- **Event type constants go in `events/types.ts`, definitions in `events/{platform}.ts`.** The `check:event-definition` gate rejects `defineCloudEvent()` in workflow files.
- **Scopes are branded strings from factory functions.** Never inline a scope string.
- **CEL expressions are string constants from `contracts/src/templates/filter-template.ts`.** Never hand-roll a CEL expression.
- **Platform names come from `PLATFORM_NAMES` in `naming.ts`.** Adding a platform without adding it to the naming table will fail the naming gate.

## Procedures

### Add a new event type
- [ ] Define the scope label: `contracts/src/scopes/<platform>.ts`, using `defineEventScope()`
- [ ] Define the filter: `contracts/src/filters/<platform>.ts`, using `defineEventFilter()` with scope + CEL expression
- [ ] Define the CloudEvent: `hatchet/src/events/<platform>.ts`, using `defineCloudEvent()` with type, source, dataSchema
- [ ] Add type constant to `events/types.ts`
- [ ] Export from `events/` barrel
- [ ] Import in the DAG file: `onEvents: [TYPE_CONSTANT]`, `defaultFilters: [FILTER_CONSTANT]`

## References

See `/.patterns/hatchet/hatchet-create-event/` for the complete event authoring pattern with tests and anti-patterns.
