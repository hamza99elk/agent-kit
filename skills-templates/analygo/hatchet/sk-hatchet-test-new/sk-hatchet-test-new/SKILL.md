---
name: sk-hatchet-test-new
description: Write Hatchet tests — the five tiers (unit, contract-fence, task-boundary, topology, eval) and the static gates. Use the runTask harness for task-boundary specs. Doctrine lives in docs/tests/README.md; this is the actionable pattern.
license: MIT OR Apache-2.0
compatibility: Works within the Analygo Hatchet test framework (vitest, runTask harness, checkDag)
---

# Test Authoring

Full doctrine: `docs/tests/README.md`. Harness: `tests/workflow/_harness.ts`
(`runTask`, `captureTaskFn`). Signal builder: `tests/workflow/_signal.ts`. **Defer to those
files — this page is the recipe.**

---

## 1. Five tiers — one question each, never overlap

| Tier | Question | File | Runner |
|---|---|---|---|
| Unit | does the domain fn work? | `tests/unit/<domain>/<fn>.spec.ts` | vitest |
| Contract-fence | does domain output fit its Zod schema? | `tests/integration/<pipeline>-contracts.test.ts` | vitest |
| Task-boundary | does the REAL `execute` envelope (data + `signal`) fit its I/O contract, on every branch? | `tests/workflow/<basename>.task.spec.ts` | vitest |
| Topology | is the DAG wired right + trigger/emit correct? | `tests/workflow/dag-<name>-topology.test.ts` | vitest |
| Eval | is the output *any good*? | `tests/eval/run-eval-<name>.ts` | `tsx` |

A test answers exactly one question. Asserting domain correctness AND schema compliance in
one test → split it. Eval scripts are `tsx`, excluded from vitest (`exclude: ["tests/eval/**"]`),
and import domain fns directly (no engine).

---

## 2. Contract-fence — domain output through its schema

```ts
const parsed = NeighborhoodSchema.parse(bfsNeighborhood(INDEX, anchors, "path", 2));
expect(parsed.kept.length).toBeGreaterThan(0);
```

The `.parse()` IS the fence: an off-enum value throws `ZodError`. ≥1 fence per major mode.
It validates the DATA sub-schema only — NOT the `signal` envelope.

---

## 3. Task-boundary — drive the real handler via `runTask`

The only tier that runs `execute()`. Use the harness — do NOT hand-build envelopes.

```ts
import { runTask } from "./_harness.js";
import { TaskGitContextOutputSchema } from "@analygo/contracts/workflows";
import { taskCGitContext } from "../../src/tasks/task-C-git-context.js";

// root: pass the event as `input`. Stub network (fetch/tool) — no engine, no real API.
it("ok — fetches and normalises the ticket", async () => {
  stubFetchOk({ title: "…", labels: [{ name: "code" }], state: "open" });
  const { output } = await runTask(taskCGitContext, { input: { input: { ticket: { number: 42, repo: "acme/widget" } } } });
  const parsed = TaskGitContextOutputSchema.parse(output);      // full envelope incl. signal
  expect(parsed.task.status).toBe("ok");
  expect(parsed.task.runId).toBe("run-test-001");               // real template ran
});
```

Rules:
- Cover **every** signal branch — the enum is `ok | partial | error`
  (`contracts/src/primitives/task.ts`). 3 branches → 3 tests.
- Parented tasks: pass `overrides: { parentsMap: { key: "task-parent" } }` +
  `parents: { "task-parent": { key: … } }`.
- Add negatives: missing required upstream (must throw), extra key (`.strict()` rejects).
- Root/file tasks carry `// coverage: partial -- <reason>` if they have no `parentsMap`
  (`check:task-coverage` requires the spec import + run, via `runTask`).
- Stub I/O (`vi.stubGlobal("fetch", …)`) — never hit a real API in a boundary test.

---

## 4. Topology — `checkDag` + trigger/emit contract

The `allDags` loop in `tests/workflow/dag-scout-topology.test.ts` auto-covers every registered
DAG's graph (parents, parentsMap, acyclic, kind/prefix, output+adapt). **Register the DAG in
`all-dags.ts` and that loop covers it.**

For the things `checkDag` CANNOT see — the trigger string and the emit definition — add a
focused file:

```ts
expect(dagGitTicketRead.onEvents).toEqual([CODE_PLAN_TYPE_SCOUTED]);  // exact trigger
expect(TicketRead.type).toBe(GITHUB_TYPE_TICKET_READ);                // emit type == constant
expect(dagGitTicketRead.hasEmit).toBe(true);
expect(dagGitTicketRead.hasOnFailure).toBe(true);
expect(checkDag(dagGitTicketRead)).toStrictEqual([]);
```

A DAG subscribed to a typo'd type, or emitting a definition whose `.type` disagrees with the
constant, is a *valid graph that routes to nobody* — this tier is what closes that gap.

---

## 5. Eval — quality (tsx)

```ts
for (const c of cases) {
  try {
    const scored = validateCase(runPipeline(c.input), c.expected, runId, c.id);
    results.push(EvalRunResultSchema.parse(scored));   // re-parse through schema
  } catch (err) {
    results.push(failedResult(c.id, err.message));      // never abort the suite
  }
}
printSummary(results);           // PASS/FAIL table + scores + reasons
writeResults(runId, results);    // tests/eval/<dag>/results/<runId>.jsonl (gitignored)
```

Cases: `tests/eval/<dag>/cases/{dev,heldout}.jsonl`, one object/line, **all `expected`
fields optional** (a case asserts only what it labels). Minimums: 20 dev, 5 heldout.
`compare-eval-<name>.ts` diffs vs a baseline (`SCORE_TOLERANCE = 0.01`).

---

## 6. Pre-push

- [ ] `npm run typecheck` — `packages/contracts` AND `packages/hatchet`
- [ ] `npm run check:all` clean (contracts, deps, defaults, contract-validate,
      **task-signal**, task-event-read, task-coverage, workflow-contracts, pured, lint)
- [ ] `npm run test` green (unit + fence + task-boundary + topology)
- [ ] Every domain fn: ≥1 fence per major mode
- [ ] Every task: boundary spec covering all 3 signal branches + negatives
- [ ] DAG: in `all-dags.ts`; topology/trigger/emit asserted
- [ ] Eval: 20 dev + 5 heldout; per-case try/catch; schema-parsed; `results/` gitignored

## Gotchas

- **The five tiers are independent.** A task-boundary test does NOT replace unit tests. Write the right tier.
- **`runTask` is for task-boundary tests only.** Not for DAG-level topology tests.
- **`checkDag` tests topology + emit/onFailure pairing.** They don't execute task handlers.
- **Eval tests run the full pipeline.** Use sparingly — they're slow.
- **Signal tests must cover every branch.** If a handler has 3 return paths, the test must exercise all 3.

## Procedures

### Add tests for a new task
- [ ] Unit test: test the pure domain atom in isolation
- [ ] Contract-fence test: verify `Schema.parse()` accepts/rejects valid/invalid data
- [ ] Task-boundary test: use `runTask` harness with mock upstream/event
- [ ] Check every branch: success, partial, error all produce `task: signal(...)`
- [ ] Topology test: add to `checkDag` test suite
- [ ] Eval test (optional): run the full pipeline against test input

### Verify test coverage
- [ ] `check:task-coverage` passes
- [ ] `check:task-signal` passes
- [ ] `checkDag` passes

## References

See `docs/tests/README.md` for the full testing doctrine. See `/.patterns/hatchet/vitest-domain-pipeline-test/` for the test pattern with canonical examples.
