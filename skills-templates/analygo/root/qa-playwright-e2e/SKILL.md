---
name: qa-playwright-e2e
description: >
  Write, run, debug, and organize Playwright end-to-end tests and browser automation. Use when asked to write E2E tests, automate a browser flow, take screenshots or recordings, debug or fix flaky Playwright tests, test responsive layouts, set up Playwright in CI, mock network calls in browser tests, or verify UI behavior. Also useful when asked to "open the browser and check" something interactively — use exploratory automation mode.
---

# Playwright E2E — browser automation and test suites

Best practices: https://agentskills.io/skill-creation/best-practices.md

---

## Core principles

1. **Test behavior, not implementation.** Assert on what the user sees or experiences — role-based locators, visible text, URLs — not on internal selectors or DOM structure.
2. **Reliability over quantity.** One trustworthy E2E test that survives refactors beats ten that break on every CSS change.
3. **Deterministic by default.** No fixed sleeps, no real third-party network in unit tests, no inter-test ordering dependencies.
4. **Readable as documentation.** The test name and body should explain the requirement. Use Arrange–Act–Assert.

## Pick a mode

Two modes. Choose one before writing code; they have different output conventions.

- **Exploratory automation** — a throwaway script to check a flow, grab screenshots, or read console logs. Write to a temp location, run it, report results. Do not commit to the repo.
- **Test suite** — durable, well-structured tests committed to the project with proper config, page objects, and CI integration.

## Before writing anything

[ ] 1. Check for an existing `playwright.config.*`, `tests/` folder, and `test` / `test:e2e` package scripts. If Playwright is already set up, match its conventions.
[ ] 2. Detect the running dev server and its port first. If none is running, start it or ask the user for the URL. Do not guess.
[ ] 3. Confirm browsers are installed — run `npx playwright install` if not.
[ ] 4. Ask or infer the language. TypeScript is the default; JavaScript, Python, and Java are also supported. A wrong language choice wastes a full iteration.
[ ] 5. Read the module/route/component under test first. Identify the **public contract**: inputs, outputs, side effects, error cases. Then decide what to test.

## Writing reliable tests

### Locators — priority order

1. **Role-based** — `getByRole('button', { name: 'Save' })`. Preferred for accessibility and robustness.
2. **Label, placeholder, or visible text** — `getByLabel('Email')`, `getByPlaceholder('Search...')`, `getByText('Submit')`
3. **Test ID** — `getByTestId('checkout-button')` when semantic locators are not enough
4. **CSS or XPath** — only as a last resort. These break on layout changes.

```ts
// Good — resilient to markup changes
await page.getByRole('button', { name: 'Sign in' }).click();
await expect(page.getByRole('alert')).toHaveText('Invalid credentials');

// Bad — brittle, breaks on any restyle
await page.click('div.css-1x9f7 > button:nth-child(2)');
```

### Waiting and timing

- Rely on Playwright's **auto-waiting** — it waits for elements to be actionable before clicking or typing.
- Use **web-first assertions** — `expect(locator).toBeVisible()`, `expect(page).toHaveURL()` — never fixed sleeps (`page.waitForTimeout`). If something is slow, wait for a specific condition: a network response, URL fragment, or element state.
- `page.waitForResponse()` is better than `page.waitForTimeout(n)`.
- For loading spinners, wait for the spinner to disappear: `await expect(page.locator('.spinner')).toBeHidden()`.

### Folder layout (canonical)

In a monorepo, E2E tests live at the root in their own directory, separate from per-package tests:

```
repo/
├── apps/
│   ├── web/
│   │   └── src/            # unit tests co-located here
│   └── api/
│       └── tests/          # integration tests here
├── packages/
│   ├── ui/
│   │   └── src/            # component tests co-located
│   └── utils/
│       └── src/            # unit tests co-located
└── e2e/                     # <-- your Playwright tests live here
    └── playwright/
        ├── playwright.config.ts
        ├── fixtures/       # shared setup, auth helpers
        ├── pages/          # page objects
        └── specs/          # test files
```

**Rules:**
- `e2e/playwright/` is self-contained — its own config, its own `package.json`, its own `test` script.
- No app-specific logic leaks into `e2e/`. The E2E tests import pages and fixtures, not app source code.
- Match the project's existing layout if it deviates from this — convention > preference.

### Independence

Each test sets up its own state. Do not depend on test order or on data left by a previous test. Create data through the API or database where possible instead of clicking through the UI. Use `test.beforeEach` for shared setup that is genuinely needed by every test in a file.

### Structure

- **Page objects** or small helper functions for repeated flows (sign-up, checkout, login). Do not create a Page Object for every single page; only for pages with significant interaction logic. Keep assertions in the test, actions in the object.
- **Fixtures** (`test.use`) for shared config — storage state, base URL, viewport.
- **One behavior per test.** The test name should read as a sentence: `"logs in with valid credentials"`, `"shows validation error on empty email field"`.
- **Arrange–Act–Assert** shape for every test. Set up state (arrange), perform action (act), check result (assert).
- **API tests:** Use `Playwright APIRequestContext` for fast, browser-free API tests:

```ts
test('rejects unauthenticated request', async ({ request }) => {
  const res = await request.get('/api/orders');
  expect(res.status()).toBe(401);
});
```

Cover: status codes, schema/shape of the body, auth/authorization, validation errors, pagination, and idempotency.

### Authentication

- Log in **once** in a setup step, save the session with `storageState`, and reuse it across tests.
- Use separate saved states per role — `storageState-admin.json`, `storageState-user.json`.
- Do not log in through the UI in every test. It adds minutes to the suite and is the most common source of flakes.

### Network mocking

- Mock third-party or flaky API calls with `page.route()`.
- Keep at least a few critical journey tests against the **real backend** — mocking everything hides integration bugs.

### Cross-browser and responsive

- Configure projects for Chromium, Firefox, and WebKit as needed.
- For responsive checks, run the same flow at mobile (iPhone 12/13), tablet (iPad), and desktop (1920×1080) viewports.

## Debugging failures

| Technique | When to use |
|---|---|
| `--trace on` → open trace viewer | First step on any unexplained failure. Shows timeline, DOM snapshots, network, and console. |
| `--headed --debug` | Step through the test interactively. Use for logic bugs. |
| Check console and failed network requests | Captured during the run in `testInfo`. Often faster than trace. |

Classify the cause before fixing:
1. **Timing** — add a proper wait condition
2. **Shared state** — data collision between tests
3. **Test data** — missing or stale fixture data
4. **Environment** — different server, different build
5. **Real app bug** — the test is correct, the app is broken

## Self-review checklist (before declaring a test suite done)

- [ ] Does each test actually fail if I break the behavior it claims to cover?
- [ ] Are there assertions, and do they check **specific** expected values?
- [ ] No fixed `sleep`/`waitForTimeout` anywhere?
- [ ] No real external network in tests that should be unit tests?
- [ ] Edge and error cases covered, not just the happy path?
- [ ] Tests are independent and pass in randomized order?
- [ ] Names describe the requirement; no dead or commented-out tests?
- [ ] No over-mocking that makes the test assert mock behavior instead of real behavior?

## Flaky tests

If a test fails intermittently across several runs:

1. Reproduce with `--repeat-each 10 --retries 0` to confirm it is actually flaky.
2. Find the race or shared-state cause.
3. Fix it. **Retries in CI are a safety net, not a fix.**
4. If you cannot fix immediately, quarantine the test with `test.skip` and a tracked issue link. Do not let a flaky test stay red or silently retried.

## CI configuration

- Run headless — `--project=chromium` for CI.
- Cache browser binaries — `actions/setup-node` + Playwright's built-in browser cache keys.
- Shard across machines for large suites — `--shard=x/y`.
- Upload artifacts on failure only: `--output=test-results --reporter=list,html`.
- Run the full suite on merge to main or nightly. Run a small smoke subset on pull requests if the full suite is slow.

## Gotchas

- **Never use `page.waitForTimeout()`** — it is always the wrong choice. Rely on web-first assertions and `waitForResponse` / `waitForURL` instead.
- **Locators are the #1 cause of flaky E2E tests.** Always prefer role-based locators; never depend on auto-generated classes, deep CSS chains, or DOM position.
- **A test that passes but has no assertion is worthless** — it can never fail, so it can never catch a regression. Every test must assert a specific observable outcome.
- **Mock the network, not the framework.** Over-mocking (e.g., mocking the fetch call inside the test's own module) tests the mock, not the app. Use `page.route()` or MSW.
- **Page objects are for reuse, not for every page.** Creating a POM for a one-off test adds indirection without value.
- **Run tests in randomized order periodically** to catch hidden coupling between tests that only shows up in CI.

## Anti-patterns to refuse

- Tests with no assertions
- Snapshot tests on huge, volatile output that nobody reviews
- Asserting on log output or private fields instead of observable behavior
- Catch-all `try/except: pass` that hides failures
- Over-mocking that tests the mock instead of the real behavior

## Token and cost discipline

When an agent drives the browser:
- Screenshots cost far more tokens than console logs or accessibility snapshots.
- Prefer text snapshots (`page.content()`, `page.evaluate()`, `page.accessibility.snapshot()`) and logs.
- Take screenshots only for failures, key state confirmations, or visual checks where text is insufficient.
- For long multi-step UI scenarios, delegate to a sub-task so the main agent context stays small.

## Safety

- Do not run tests that submit real payments, send real emails, or modify production data.
- Use test accounts and a non-production environment — staging, test, or localhost.
- Review any third-party script before executing it.

## References

- `references/playwright-troubleshooting.md` — load when a test fails in a way you cannot explain with trace viewer alone