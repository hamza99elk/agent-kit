---
name: sk-hatchet-system
description: The architecture map of the Analygo Hatchet execution engine. Load first for end-to-end context, then move to the focused skill (task/dag/contract/test). Defers to the TS source and door gates for exact rules.
license: MIT OR Apache-2.0
compatibility: Conceptual map — applies to the entire Analygo Hatchet stack (contracts + hatchet packages)
---

# Hatchet System — the map

`packages/hatchet` = execution engine (tasks, DAGs, domain atoms, events).
`packages/contracts` = Zod schemas + `defineTask`/`defineDag` factories + the registry.
**When this page and a `.ts` file disagree, the `.ts` file wins.** This page tells you WHERE
things live and WHICH skill/source defines the rule; it does not restate the rules.

---

## The five moving parts

```
contracts/src/{primitives,concepts,projections}/  DATA SCHEMAS          (registered)
contracts/src/workflows/{family}-contracts.ts     I/O ENVELOPES         (compose data schemas)
contracts/src/domains/registery.ts                REGISTRY              (output/upstream gate)
hatchet/src/domains/**/                            PURE domain atoms     (no ctx/env/SDK)
hatchet/src/tasks/task-*.ts                        defineTask() handler  (import-only)
hatchet/src/workflows/dag-*.ts                     defineDag() wiring    (import-only)
hatchet/src/events/*                               CloudEvent types + definitions
```

A run: `event → task-C- root (shape context) → children (upstream) → emit event → next DAG`.

---

## The layers (one rule)

`primitives → concepts → projections → workflows`. Layer N imports N or lower, never up.
Atomic field → `primitives`; domain noun → `concepts`; invariant-bearing output →
`projections`; the `{key: schema}` envelope a task/DAG consumes → `workflows`.
Exact placement + registration → **`sk-hatchet-contract-new`**.

---

## Dataflow (the canonical chain)

```
concepts/ticket-fetch.ts        TicketFetchResultSchema = z.object(...).strict()   ← DATA
domains/registery.ts            register("TicketFetchResultSchema", _…)           ← REGISTER
workflows/git-ticket-read-contracts.ts  { ticket, git, fetch, task, events }      ← ENVELOPE
hatchet/tasks/task-C-git-context.ts     defineTask({ output: { ticket, git, fetch } })
hatchet/workflows/dag-git-ticket-read.ts defineDag({ … emit: TicketRead … })
```

A task imports envelopes/primitives from `@analygo/contracts`; its `output` values MUST be
registered. Task/dag authoring → **`sk-hatchet-task-new`** / **`sk-hatchet-dag-new`**.

---

## Task kinds & the `task-C-` context root

Prefixes from `contracts/src/templates/task/kind-prefixes.ts`: `task-` regular, **`task-C-`
context** (the event-shaping root), `task-D-` durable, `task-S-` spawn, `task-F-` fanout,
`task-ai-`, `task-jev-`. `task-C-` is the ONLY kind allowed to read `event` in an event-sourced
DAG — `check:task-event-read` enforces it. Canonical examples: `task-C-scout-context`,
`task-C-git-context`.

---

## Emission: `emit` / `onFailure` (not `onSuccess`)

`defineDag({ emit, onFailure })`. `emit` runs only if all tasks succeeded and returns
`{ result, emit }` (validate the payload with `.parse` first; return `null` emit to announce
nothing). `onFailure` makes a crashed run non-silent — a DAG with tasks but no `onFailure`
carries the advisory `no-on-failure-hook` warning. Event definitions live in
`hatchet/src/events/*` (`defineCloudEvent`); type constants in `events/types.ts`.
Details → **`sk-hatchet-dag-new`**.

---

## Tests — five tiers, one question each

unit · contract-fence (`Schema.parse()`) · task-boundary (`execute` + `signal`) · topology
(`checkDag` + trigger/emit contract) · eval (`tsx`). Runner split and doctrine:
`docs/tests/README.md` + **`sk-hatchet-test-new`**.

---

## Gates (`npm run check:all`, then `npm run test`)

`check:contracts` · `check:deps` · `check:dag-defaults` · `check:contract-validate` ·
`check:task-signal` · `check:task-event-read` · `check:task-coverage` ·
`check:workflow-contracts` · `check:pured` · `check:lint`.
What each catches → `packages/hatchet/package.json` (`scripts`) and the gate sources under
`tools/hatchet/contract-validators/`. Do not memorise — run them.

---

## CheckDag (topology)

Iterates `allDags` (`npm run test -- dag-scout-topology`). Validates parents exist,
`parentsMap` values are real task names, every `upstream` key wired, acyclic, kind/prefix
consistency, `output`+`adapt` present. `parentsMap` = CONTRACT key → PARENT TASK NAME.

---

## Writing order

schema (`concepts`) → register → envelope (`workflows/{family}-contracts.ts`) → domain atom →
task → DAG → `all-dags.ts` → tests. Full checklists are in the focused skills.

## Gotchas

- **The two import rules are the most frequently broken gate.** Layer N may only import N or lower. `domains/` may not import from `@analygo/contracts` or any other package.
- **`task-C-` is the ONLY kind that may read `event`.** The `check:task-event-read` gate enforces this.
- **Every DAG needs both `emit` and `onFailure`.** Without both, a crashed pipeline emits nothing.
- **The registry is the source of truth for what fields are allowed.** If the gate says "not a registered domain primitive", register it first.

## Procedures

### Orient to the codebase
1. Read `contracts/src/` structure: `primitives/` → `concepts/` → `projections/` → `workflows/`
2. Read `hatchet/src/` structure: `domains/` → `tasks/` → `workflows/` → `events/`
3. Check `contracts/src/domains/registery.ts` for registered schemas
4. Check `hatchet/src/workflows/all-dags.ts` for existing DAGs
5. Determine which layer a new piece belongs in before writing code

## References

See `/.patterns/hatchet/README.md` for the full layered architecture reference. See `.patterns/hatchet/hatchet-domain/`, `.patterns/hatchet/hatchet-task/`, `.patterns/hatchet/hatchet-dag/` for each layer's pattern.
