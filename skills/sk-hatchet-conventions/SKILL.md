---
name: sk-hatchet-conventions
description: >
  Hatchet coding conventions — task structure, naming, signals, gates.
  Load this skill before writing Hatchet tasks, DAGs, or contracts.
---

# Hatchet Conventions

## Critical rules (non-negotiable)

- Every task return path MUST include `task: signal(…)`
- `output` declared → `adapt: (raw) => raw` REQUIRED
- No inline `import { z }` in tasks/workflows — import from `@analygo/contracts`
- Task naming: `task-{kind}{platform}-{action}` (kinds: `C-` context, `ai`, `D-` durable, etc.)
- Run `npm run check:all` before pushing
- Layer N imports from N or lower — enforced by `depcruise`

## Authoring order (contracts-first)

```
concepts|<layer>/<name>.ts        data schema (z.object().strict())
domains/registery.ts              register("Name", _Name)
workflows/{family}-contracts.ts   envelope composing the data schema
hatchet/src/domains/**/<name>.ts  pure domain fn (no ctx/env/SDK, never throws)
hatchet/src/tasks/task-*.ts       defineTask() handler → signal every path
hatchet/src/workflows/dag-*.ts    defineDag() wiring + emit/onFailure
hatchet/src/workflows/all-dags.ts add to allDags
tests/**                          see sk-hatchet-test-new
```

## Skill discovery (AI SDK)

Implementation skills (code editing, coding decisions, auditing, research, scoping) are
registered as `deferLoading: true` AI SDK tools in `packages/hatchet/src/ai/skills/`.
The model discovers them via `toolSearch()` during a Hatchet task turn — no skill IDs
in the system prompt.

See `packages/hatchet/src/ai/skills/` for the tool definitions, or call
`search({ query: "..." })` to find a matching skill at runtime.

## Full reference

See `references/AGENTS.md` for the complete engineer persona with all
gates, layer rules, and authoring order.