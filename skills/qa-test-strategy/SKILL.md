---
name: qa-test-strategy
description: >
  Produce a concrete, repo-specific plan for what to test, at which level (unit / integration / E2E / AI eval), where tests live, and how CI runs them. Use when asked to design a test strategy, decide between unit/integration/E2E, set up testing in a new or existing codebase, organize tests in a monorepo, set coverage goals, wire tests into CI, or choose a test runner. Also useful when the user says "we need more testing" without specifying where.
---

# QA Test Strategy — decide what to test, at which level, where it lives

Best practices: https://agentskills.io/skill-creation/best-practices.md

---

## Core principles

1. **Test behavior, not implementation.** Assert on what the user observes or a caller receives — not on private internals. Implementation-coupled tests break on every refactor.
2. **Reliability over quantity.** One trustworthy test beats ten flaky ones. A suite the team doesn't trust is worse than no suite.
3. **Right test at the right level.** Many fast unit tests, fewer integration, a small number of high-value E2E on critical paths.
4. **Deterministic by default.** No real network, no real clock, no random data without a seed. Same input, same result, every run.
5. **Readable as documentation.** A test name and body should explain the requirement. Use Arrange–Act–Assert.

## Anti-patterns to refuse

- Tests with no assertions ("it renders" with nothing checked)
- Snapshot tests on huge, volatile output that nobody reviews
- Asserting on log output or private fields instead of behavior
- Catch-all `try/except: pass` that hides failures
- Mocking the very thing under test
- Over-mocking that makes the test assert mock behavior instead of real behavior

## Procedure

[ ] 1. Inspect before advising — examine the repo
[ ] 2. Rank areas by risk
[ ] 3. Choose test types per area
[ ] 4. Decide on placement
[ ] 5. Design CI stages
[ ] 6. Write the plan

### Step 1: Inspect before advising

Look at the repo directly before recommending anything. Check:
- Language and framework (React + Jest? Go + testing? Python + pytest?)
- Existing test runner and its config file
- Current test folders and naming convention (`*.test.ts` vs `__tests__/`)
- CI config — what runs on push vs merge to main
- Monorepo structure or workspace config (Nx, Turborepo, Bazel, pnpm workspaces)

**Never recommend a new tool when the project already has a working one that does the job.** If Jest works, do not switch to Vitest unless there is a concrete pain point.

### Default framework detection

| Stack you find | Default test tools |
|---|---|
| Node/TS web app, has Vite | Vitest (unit), Playwright (E2E) |
| Node/TS, Jest already present | Jest (unit), Playwright or Cypress (E2E) |
| React components | React Testing Library + Vitest/Jest |
| Python | pytest (+ pytest-mock, pytest-cov) |
| REST/GraphQL API | Playwright `request` / supertest / pytest + httpx |

If the project has no framework, recommend one, explain the choice in one sentence, then set it up minimally (config + one example test + test script) rather than a giant scaffold.

### Step 2: Rank by risk

List the areas where a bug costs the most. Prioritize, in order:
1. **Payments, billing, and subscriptions** — financial loss
2. **Authentication and authorization** — security and access control
3. **Data writes** — create, update, delete operations
4. **Core user flows** — sign-up, login, onboarding, primary action
5. **Shared libraries** used by many packages in a monorepo

Coverage percentages are a guardrail, not the goal. 80 % of untested code in a low-risk feature is fine; a single missing test around a payment edge case is not.

### Step 3: Choose test types

| Level | Share | Scope | Notes |
|---|---|---|---|
| Unit | ~60-70 % | One function or class, dependencies mocked | Milliseconds. Logic, validation, edge cases |
| Integration | ~20-30 % | Code + real DB, queue, HTTP layer, or another process | Best return for backend apps. Use containers for real dependencies |
| E2E | ~5-10 % | Whole app through browser or mobile driver | Critical journeys only. Slowest and flakiest |

Add these selectively:
- **Component tests** for UI components in isolation (Storybook + testing-library)
- **Contract tests** when services or teams depend on an API shape (Pact, or request-response schemas)
- **Smoke tests** run after every deploy
- **Regression tests** — every bug fix ships with a test that fails without the fix
- **Performance, security, accessibility, visual regression** — targeted extras, not part of the standard pyramid

**Shape adjustments:**
- Frontend-heavy apps → "trophy" shape (more integration, fewer unit tests)
- Microservices → "diamond" shape (heavy integration and contract tests, fewer unit and E2E)
- Default monolith → traditional pyramid

### AI-powered features

If the app calls an LLM, test the surrounding code normally with the model mocked. Add **evals** for model-facing behavior. Evals are not integration tests: output is non-deterministic, so they score a dataset (pass rate, graded quality) instead of asserting one exact result.

### Step 4: Place the tests — the clean layout

Use this canonical layout for a monorepo. It keeps tests close to their code, separates cross-cutting concerns, and scales cleanly.

```
repo/
├── apps/
│   ├── web/
│   │   ├── src/                     # source
│   │   └── *.test.ts               # co-located unit tests (or tests/ per app)
│   └── api/
│       ├── src/
│       └── tests/                  # integration tests (DB, HTTP-layer)
├── packages/
│   ├── ui/
│   │   └── src/
│   │       └── *.test.tsx          # component tests co-located with source
│   └── utils/
│       └── src/
│           └── *.test.ts           # unit tests co-located with source
└── e2e/                             # cross-app E2E, cross-service integration, contract tests
    └── playwright/
```

**Rules this layout enforces:**
- Each `apps/*` and `packages/*` owns its own unit, component, and integration tests plus a `test` script runnable alone with one command.
- `e2e/` at the root is the boundary between per-package tests and cross-cutting ones. No app-specific logic leaks in.
- Co-locate unit and component tests with source (`Button.test.tsx` next to `Button.tsx`). Use a `tests/` subdirectory per app for integration tests that need setup helpers.
- Share config and helpers (test runner presets, fixtures, mocks) through a shared dev package — share config, not tests.
- Shared libraries (`packages/ui/`, `packages/utils/`) get the strongest unit coverage since every dependent app inherits their bugs.
- Enforce package boundaries so tests do not reach into other packages' internals (dependency-cruiser or ESLint rule).

**Non-monorepo alternative:**
- Co-locate unit tests with source: `Button.test.tsx` beside `Button.tsx`
- Integration tests in `tests/integration/`
- E2E in `e2e/` at project root

### Step 5: CI rules

| Event | What runs |
|---|---|
| Pull request | Lint, unit, and integration tests for changed packages only (Nx `affected`, Turborepo `--filter`, or equivalent) |
| Merge to main | Full suite including E2E |
| Nightly | Full suite (catches drift across merged PRs) |

Use caching (`actions/cache`, Nx remote caching), parallel runs, and sharding for large suites. Quarantine or fix flaky tests quickly — they destroy trust.
- Keep unit tests in the fast PR lane.
- Run the heavier E2E / cross-browser matrix on merge or nightly if it's slow.
- Upload artifacts on failure (Playwright trace, screenshots, video) so failures are debuggable.
- Add a coverage gate so coverage can't silently regress — but don't write meaningless tests just to hit a number.
- Tests must be fast, deterministic, and independent.
- Run tests in randomized order to catch hidden coupling between tests (Vitest `--sequence.seed`, Jest `--randomize`, pytest `--random-order`).
- Freeze the clock for time-sensitive tests (`vi.useFakeTimers()`, `freezegun`, Playwright `clock`).

### Step 6: Deliver the plan

Write a concrete, short plan with these sections:

1. **Risk list** — top 5 areas in order of cost-of-failure
2. **Test-type table** — what to add, where, with which tool (framework, runner)
3. **Folder layout** — how test directories are organized in the repo
4. **CI stages** — what runs when, caching strategy
5. **First three tests to write this week** — pick the highest-ROI targets

### Gotchas

- **Do not redesign from scratch.** If the project has a working test setup, improve it. The user asked for a strategy, not a migration to their third test runner this quarter.
- **Do not recommend E2E for everything.** Most bugs are caught by integration tests faster and more reliably.
- **Coverage percentages are a result, not a goal.** Targeting "80 % coverage" leads to trivial tests of generated code. Target risk coverage instead.
- **Monorepo shared libraries are a risk multiplier.** A bug in a shared utility breaks every package. Give them the strongest testing.
- **Flaky tests must be quarantined, not retried into silence.** Retries hide the problem; a quarantined test with a tracked issue forces a fix.