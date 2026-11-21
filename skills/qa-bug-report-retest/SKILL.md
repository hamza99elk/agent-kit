---
name: qa-bug-report-retest
description: >
  Produce structured bug reports with reproduction steps, retest fixes against original criteria plus regression checks, and derive test cases from acceptance criteria. Use when asked to file a bug or defect, write reproduction steps, triage an issue, verify a fix or ticket resolution, write test cases from ACs, or say "it works now" or "still broken" with confidence. Also useful when a user describes a problem vaguely and needs help turning it into a proper bug report.
---

# QA Bug Report & Retest — reproducible bugs, verified fixes, test cases from ACs

Best practices: https://agentskills.io/skill-creation/best-practices.md

---

## Core principles that apply across all jobs

1. **Test behavior, not implementation.** A bug is about what the user observes or what a caller receives — not about how the code is structured internally. Write steps and assertions against observable outcomes.
2. **Reliability over quantity.** One trustworthy reproduction beats three vague reports. A test case with no assertion is worse than no test case.
3. **Deterministic by default.** Reproduce with the same input, same state, same environment — every time. If it's intermittent, say how often and under what conditions.
4. **Readable as documentation.** A bug report's title and steps should explain the requirement gap. A test case's name should read like a sentence.

## Anti-patterns to refuse in bug reports and test cases

- **Tests with no assertions** — "it renders" with nothing checked catches nothing
- **Snapshot tests on huge, volatile output** — nobody reviews the diff
- **Asserting on log output or private fields** instead of observable behavior
- **Mocking the very thing under test** — that tests the mock, not the code
- **Catch-all `try/except: pass`** that hides failures

## Three distinct jobs

Pick the right one before writing anything.

## Job 1: File a bug report

### Before writing

1. **Reproduce it yourself** — at least twice, following the same steps. If you cannot reproduce, say so and note the conditions you tried.
2. **Search the tracker** (GitHub Issues, Jira, etc.) for duplicates. Link any related tickets.
3. **Determine the environment** — URL / build version, browser / OS / device, account or role used. If not provided, ask.

### Template

```
Title: <component> — <what is wrong>, <condition>
Severity: Critical | High | Medium | Low
Environment: <URL/build/version>, <browser/OS/device>, <account or role>

Steps to reproduce:
1. <known state — "Logged in as user X on fresh data">
2. <navigation or action>
3. <trigger the symptom>

Expected: <what should happen — concrete and observable>
Actual: <what happens instead — concrete and observable>
Frequency: always | intermittent (x of y runs)

Evidence: <screenshot, console error, network request, log excerpt>
Notes: <workaround, suspected cause, related tickets>
```

### Gotchas

- **Title states the symptom, not the cause.** Wrong: "Database query is slow." Right: "User list page takes >10 s to load for 10 000+ users."
- **Steps start from a known state** — "logged out", "logged in as admin", "fresh database". Without this, a tester cannot reproduce.
- **Expected and actual are separate and concrete.** Wrong: "Should work correctly." Right: "Expected: 'Success' toast appears and user redirects to dashboard. Actual: spinner spins indefinitely, no redirect."
- **Attach evidence, but no secrets.** Strip tokens, real customer data, and credentials. A failing network request (shown from devtools Network tab) or console error is often more useful than a screenshot.
- **One bug per report.** If you found multiple problems, write separate reports. Compound tickets get closed without fixing everything.
- **No duplicates.** Searching the tracker first is mandatory.

## Job 2: Retest a fix

### Procedure

[ ] 1. Read the ticket thoroughly — original reproduction steps, expected result, and what the fix claims to change. Do not trust the title alone.
[ ] 2. Confirm you are testing the build that *contains* the fix — check the version, commit hash, or deploy timestamp.
[ ] 3. Run the original reproduction steps **exactly as written**.
[ ] 4. Run variations the original report did not try — different input values, different role, boundary values, refresh and back navigation.
[ ] 5. Check neighboring features or components that touch the same code for regressions. A fix that breaks something else is not ready.
[ ] 6. Decide the result:
     - **Verified:** original steps pass, variations pass, no regressions found.
     - **Not fixed:** original steps still fail — attach fresh evidence.
     - **Partially fixed or new issue:** describe exactly what still fails. File a separate bug for anything new.
[ ] 7. Comment on the ticket with: build tested, steps run, result (with evidence), and regression check summary. Move the ticket's status only if the user explicitly asked you to or the workflow clearly expects it.

### Self-review checklist for retest

Before declaring a fix verified, check:
- [ ] Did the original reproduction steps actually fail before the fix (confirm the bug was real)?
- [ ] Did I test the exact build / commit that claims to contain the fix?
- [ ] Did I test variations beyond the original steps (different input, role, edge cases)?
- [ ] Did I check neighbors for regressions?
- [ ] Is my evidence attached (screenshot, trace, log)?

### Gotchas

- **Do not skip step 4** — most retest failures come from verifying only the happy path.
- **Do not claim "verified" without re-running the test yourself.** The fact that someone else fixed it is not evidence.
- **If you cannot access the build containing the fix, say so.** Testing the wrong build produces worthless results.
- **A test that passes but has no assertion is worthless.** Never mark "verified" based on a test that ran without checking anything.

## Job 3: Test cases from acceptance criteria

For each acceptance criterion, write at least one case. Then add edge cases the criteria forgot.

```
ID: TC-<area>-<nnn>
Title: <behavior under test — reads like a sentence>
Priority: P0 | P1 | P2
Type: functional | negative | boundary | permission | regression
Preconditions: <state/data required>
Steps: 1. <action> 2. <action>
Expected: <observable result>
```

### Coverage checklist per criterion

| Check | Apply when |
|---|---|
| Happy path | Always |
| Invalid input | Form fields, API params |
| Empty/null input | Optional fields, lists |
| Boundary values | Numeric ranges, pagination |
| Permission differences | Different roles accessing same feature |
| Error handling | Network failure, server error, timeout |
| Retry or double submit | Buttons, form submission |

For an API, also cover: status codes, response shape against the schema, auth failures (no token, expired token, wrong role), validation errors (missing field, wrong type, out-of-range), and idempotency (POST the same payload twice).

### Validation

1. Build a **coverage map** — acceptance criteria on one axis, test case IDs on the other. Gaps are immediately visible.
2. Review the final set for: missing cases (gaps), duplicate cases (same behavior tested twice), and untestable cases (cannot observe the expected result). Remove or merge duplicates before delivering.

### Self-review checklist for test cases

Before delivering, check:
- [ ] Does each test actually fail if I break the behavior it claims to cover? (If unsure, mentally break the code and confirm the assertion would catch it.)
- [ ] Are assertions checking **specific** expected values, not just "truthy" or "no throw"?
- [ ] Edge and error cases covered, not just the happy path?
- [ ] No dead, commented-out, or duplicate test cases?
- [ ] Test names describe the requirement; can someone read the name and know what's being tested?
- [ ] Coverage map shows no gaps — every criterion has at least one test?