---
name: sk-contracts-system
description: Contracts layer architecture — layer stack, composition rules, and where schemas belong.
---

# Contracts Layer System

The contract layer (`packages/contracts/src/`) is the **single factory for every data shape**
that crosses a task boundary. Tasks and DAGs only import — they never compose.

---

## 1. The four layers (strict dependency, no skipping)

```
primitives/   ─── atoms: path, count, symbol, language, identity, time, collection
      ↑
concepts/     ─── domain nouns: file, graph, plan, work, judgment, scouting, repository
      ↑
projections/  ─── pipeline outputs with cross-field invariants: skeleton, scout-shape,
                  manifest. These add invariants over concept compositions.
      ↑
workflows/    ─── DAG and task I/O envelopes + topology contracts. Named keyed objects
                  that compose schemas from projections/ and below. This is what the
                  orchestrator imports to know what a task/DAG produces.
      ↑

```

A file at layer N may import from layer N or lower. Never from N+1.

---

## 2. What lives where

| Shape | Home |
|---|---|
| Field atom (`path`, `count`, `language`) | `primitives/` |
| Domain noun (File, Graph, Plan, Judgment) | `concepts/` |
| Pipeline output with invariants (SkeletonResult, ScoutShape) | `projections/` |
| Task I/O envelope ({ result: RepoResolveResultSchema }) | `workflows/` — named task boundary, composes from concepts/projections |
| DAG envelope (dagScoutInput) | `workflows/` — orchestrator I/O boundary |
| Topology contract (parentsMap validation) | `workflows/` — alongside the DAG envelope it validates |

---

## 3. The single-import rule

Files in `tasks/` and `workflows/` must NOT contain:
- `import { z } from "zod"`
- Any `z.object({})`, `z.string()`, `z.array()`, `z.enum()` — inline Zod of any kind
- Any `const X = z.array(Schema)` — the array schema must be a registered export

Every schema used in `defineTask()` or `defineDag()` is imported from
`@analygo/contracts/{domains,projections,workflows}` — never composed inline.

**Litmus test:** if a line in a task file contains `z.` (outside a comment), stop.
The schema belongs in the contract layer.

---

## 4. Contract extensions (the right way)

When a task needs a shape that doesn't exist yet:

1. Author the shape at the correct layer in `contracts/src/` — not in the task file.
2. Export from the layer's index/barrel.
3. Register new domain primitives in `domains/registery.ts`.
4. Import in the task file.

**The extension point is the contract layer, not the task.**

---

## 5. Enforcement

| Tool | Enforces |
|---|---|
| `depcruise` (`.dependency-cruiser/contracts-import-rules.cjs`) | Layer purity — no N+1 imports |
| `checkDag` (`workflows/check-dag.ts`) | Every `parentsMap` entry matches parent's declared output schema |
| `vitest run check-dag` | Pre-push gate — must pass before any DAG change |
| `check:dag-defaults` | No bare `return {}` objects without schema parse |

---

## 6. Key constraints

- `primitives/` imports from `zod` only
- `concepts/` imports from `primitives/` and sibling `concepts/` files
- `projections/` imports from `concepts/` and `primitives/`
- `workflows/` imports from `projections/`, `concepts/`, and `primitives/`
- `tasks/` (hatchet) imports from `@analygo/contracts/{domains,workflows}` only — never from `projections/` directly
- `workflows/` (hatchet) imports from `tasks/` + `contracts/` only