---
name: qa-sweep
description: >
  Run a manual or exploratory QA pass on a feature, page, or whole app, then report bugs found with reproduction evidence. Use when asked to QA, smoke test, verify a feature works end-to-end, check a deploy, find bugs, test the app as a user would, do exploratory testing, or "kick the tires" before a release. Also useful when the user says "can you test this for me" or "make sure it works" without specifying what exactly to check.
---

# QA Sweep — find bugs by testing the way a real user would

Best practices: https://agentskills.io/skill-creation/best-practices.md

---

## Pick a depth tier

Choose a tier first. If the user does not specify, default to **Standard** and state your choice.

| Tier | When | What it covers |
|---|---|---|
| Smoke | After a deploy or quick check-in | App loads, main flow works, no console errors on startup |
| Standard | A feature or page before release | Happy paths, key edge cases, forms, navigation, console and network errors |
| Full | Release or major change | Everything above plus accessibility basics, performance basics, responsive layouts, error and empty states |

## Procedure

Progress:
- [ ] Phase 1: Find your testing surface
- [ ] Phase 2: Gather what "correct" means
- [ ] Phase 3: Start the system
- [ ] Phase 4: Write a short test plan
- [ ] Phase 5: Execute
- [ ] Phase 6: Fix and retest (only if asked)
- [ ] Phase 7: Write the report

### Phase 1: Find your testing surface

Probe what tools you have available: a browser (Playwright or headed browser), shell access, API access (curl, fetch), a local dev server. Say which ones you will use. **If a capability is missing — for example no browser — say what you cannot verify instead of guessing.**

### Phase 2: Gather what "correct" means

Use these sources in this order:
1. A spec or ticket with acceptance criteria — this is the best source
2. Existing test cases or documentation
3. The UI and code itself

Extract: acceptance criteria, user journeys, failure modes, edge cases. **If there is no spec, state the assumptions you are testing against.** For example: "Testing against the assumption that password must be 8+ characters and contain one number."

### Phase 3: Start the system

Detect or start the app. Check running dev servers first. Note the URL, build version, and environment (localhost / staging / production). **A test run against the wrong environment produces worthless results.**

### Phase 4: Write a short test plan

Group cases by scope (feature, page, user journey). For each case include: setup steps, action steps, expected result.

Cover this checklist for every feature or page:
- [ ] Happy path for each user journey
- [ ] Invalid input — wrong format, wrong type
- [ ] Empty input — leave required fields blank
- [ ] Very long input — boundary test for form fields
- [ ] Boundary values — numerics, pagination, date ranges
- [ ] Permission or role differences — what does an admin see vs a regular user
- [ ] Error states — network failure, server error (500), timeout
- [ ] Refresh and back button — does the app survive navigation
- [ ] Double submit — clicking a button twice

For large apps, split by area and test areas in parallel (one tester per area), each reporting back.

### Phase 5: Execute

- Run cases one at a time. Record pass / fail / blocked as you go.
- **On every page: check the browser console for errors and the Network tab for failed requests.** Silent JavaScript errors and 404s for assets are easy to miss but often surface real bugs.
- For API testing, also verify: status codes, response body shape, auth failures (no token, expired, wrong role), validation errors (missing field, wrong type), and idempotency (POST the same payload twice).
- Capture evidence for each failure: a screenshot, console error, or network request excerpt. **Screenshots are expensive in tokens** — take them for failures and key states, not every step.
- Reproduce a failure **twice** before reporting it to rule out a flake.
- Run tests in a logical order (happy path first, then edge cases) to validate the system works before you stress it. No point testing boundary values on a broken login flow.

### Phase 6: Fix and retest (only if asked)

If the user asked for fixes:
- Fix one bug at a time.
- Re-run the failing case.
- Re-run neighboring cases to catch regressions.
- **Never claim a fix works without re-running the case.**

### Phase 7: Write the report

Keep it to what the reader needs. Do not narrate every step.

```
Scope: <features or pages tested>
Environment: <URL, build, browsers>
Tier: Smoke | Standard | Full
Tools used: <Playwright, curl, manual browser>

Results:
  Passed: <n>
  Failed: <n>
  Blocked: <n>
  Not tested: <n>

Bugs (ordered by severity):
1. [Critical] <Title> — <2-line summary, steps, expected vs actual, evidence>
2. [High] <Title> — ...
3. ...

Fixed vs open vs needs human review:
- Fixed: <n>
- Still open: <n>
- Needs human review: <n>

Gaps:
- <what was not covered and why — for example: "Could not test payment flow because test environment has no payment processor configured">
```

### Self-review checklist before delivering the report

- [ ] Did I reproduce every failure at least twice?
- [ ] Is the environment (URL, build, version) recorded?
- [ ] Are reproduction steps minimal, numbered, and starting from a known state?
- [ ] Is expected vs actual clearly separated for each bug?
- [ ] Is evidence attached for each failure?
- [ ] Is the bug list ordered by severity?
- [ ] Have I noted what was not tested and why?
- [ ] Are test accounts / non-prod data used everywhere?

### Severity guide

| Level | Meaning |
|---|---|
| Critical | Data loss, security hole, app unusable, no workaround |
| High | Core flow broken, workaround is painful or complex |
| Medium | Feature misbehaves, reasonable workaround exists |
| Low | Cosmetic or minor polish issue |

## Core principles

1. **Test behavior, not implementation.** A bug is what the user observes — not what the code looks like internally. Report against observable outcomes.
2. **Reliability over quantity.** One thorough QA pass that catches real bugs beats ten shallow passes that miss the critical issue.
3. **Deterministic by default.** Reproduce with the same input, same state, same environment. If intermittent, document the frequency and conditions.
4. **Readable as documentation.** The report should explain the requirement gap clearly enough that a developer can act on it without asking questions.

## Anti-patterns to refuse

- Reporting a bug with no reproduction steps — "it doesn't work" is not a bug report
- Asserting on log output or private fields instead of observable user-facing behavior
- Reporting without reproducing at least twice — one-off flakes waste everyone's time
- Testing with real production data instead of test accounts / sandbox

---

### Gotchas

- **Do not trust the test environment without checking.** A test run against staging that is running broken code or wrong version produces worthless results.
- **Reproduce twice before reporting.** One-off flakes waste everyone's time.
- **"Works on my machine" is not a valid test result.** Run in the environment the user specified or the closest approximation available.
- **Do not test production with real data.** Use test accounts and sandbox environments.
- **Screenshots are expensive — prefer logs and console output** when testing through an agent. Reserve screenshots for failures and visual layout checks.
- **Skip steps only if blocked.** Note why you skipped. A test plan with skipped steps is better than an executed plan that skipped verification but did not report it.
- **A test that passes but has no assertion is worthless.** Running the flow without checking the result proves nothing.