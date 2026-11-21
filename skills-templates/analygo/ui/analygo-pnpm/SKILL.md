---
name: analygo-pnpm
description: >
  Configure, audit, validate, and orchestrate the Analygo monorepo's pnpm checks
  — `pnpm check` at root, `turbo.json` task DAG, package-level lint/typecheck/test
  scripts, CI gating, and the storybook validation suite. Use when asked to set up
  pnpm check in the root, add a check to a package, define turbo tasks, validate
  that pnpm check passes before merge, fix a broken check across the monorepo,
  create a new check script (`scripts/check-*.mjs`), audit which packages lack
  lint/typecheck/test scripts, wire Chromatic or Storybook tests into the check
  pipeline, or debug a turbo task dependency issue. Also use when the user asks
  "why is my PR failing CI", "add a validation for X", "how do I run all checks",
  or "make sure nobody can ship broken stories or hand-rolled layout" — the check
  suite is the answer. NOT for building actual component stories or layout code
  (see analygo-ui-layout, analygo-ui-archetypes, sk-storybook-component-testing).
license: MIT
compatibility: pnpm 12.18.0 · Turbo 2.x · analygo monorepo
metadata:
  author: Analygo Team
  version: 1.0.0
---

# analygo-pnpm — Analygo monorepo check suite

The monorepo's gating philosophy:

> **Root orchestrates. Packages own their checks. CI enforces.**

Every check in the monorepo follows this flow:

```
┌───────────── root package.json ─────────────────┐
│  pnpm check → pnpm lint → lint:stories           │
│              → pnpm typecheck                     │
│              → pnpm test                          │
│              → pnpm build                         │
│              → check:depcruise                    │
│              → check:viewport-heights             │
│              → check:raw-glass                    │
│              → check:layout-primitives            │
└──────────────────────────────────────────────────-┘
       │
       ▼ turbo.json
       │
       ├─ Each task → each package's package.json script
       │
       ├─ lint:stories → @analygo/ui        → check for:
       │   ├─ Every .tsx file needs .stories.tsx
       │   ├─ Stories use correct tags
       │   ├─ No conditionals inside stories
       │   ├─ No variant="base" on Surface
       │   └─ Stories co-located with component
       │
       └─ check:depcruise → root             → dependency-cruiser import rules
```

---

## The check tasks

### Root `package.json` scripts

| Script | Runs | Installed? |
|---|---|---|
| `build` | `turbo run build` | ✅ |
| `typecheck` | `turbo run typecheck` | ✅ |
| `test` | `turbo run test` | ✅ |
| `dev` | `turbo run dev` | ✅ |
| `lint` | `turbo run lint` | ❌ missing root script |
| `check` | `pnpm lint && pnpm typecheck && pnpm test && pnpm build` | ❌ missing entirely |
| `check:depcruise` | `turbo run check:depcruise` | ❌ missing |
| `check:viewport-heights` | `turbo run check:viewport-heights` | ❌ missing root script |
| `check:raw-glass` | `turbo run check:raw-glass` | ❌ missing root script |
| `check:layout-primitives` | `turbo run check:layout-primitives` | ❌ missing root script |

### Turbo task graph

Each turbo task in `turbo.json` should declare its dependency chain so Turbo can
cache and parallelize correctly:

| Task | Depends on | Pipeline order |
|---|---|---|
| `lint` | `^lint` (upstream deps linted first) | 1 |
| `lint:stories` | `^lint` | 2 (story lint depends on deps being clean) |
| `typecheck` | `^build` | 3 |
| `test` | `^build` | 3 |
| `build` | `^build` | 3 |
| `check:depcruise` | — | 2 |
| `check:viewport-heights` | — | 1 |
| `check:raw-glass` | — | 1 |
| `check:layout-primitives` | — | 1 |
| `check` | all of the above | depends on `lint`, `lint:stories`, `typecheck`, `test`, `build`, `check:depcruise`, `check:viewport-heights`, `check:raw-glass`, `check:layout-primitives` |

### Package-level scripts

Every package needs at minimum these scripts for `pnpm check` to work:

| Package | lint | lint:stories | typecheck | test | build |
|---|---|---|---|---|---|
| `@analygo/ui` | ✅ needs `eslint src --max-warnings=0` | ✅ needs `check-stories.mjs` | ✅ `tsc --noEmit` (inherited from root) | ✅ `vitest run` | ✅ placeholder |
| `@analygo/contracts` | ✅ needs `eslint` | — (no stories) | ✅ `tsc --noEmit` | ✅ `vitest run` | needs check |
| `@analygo/design-tokens` | needs check | — | needs check | needs check | needs check |
| `apps/platform` | ✅ needs `eslint .` | needs check | needs check | needs check | ✅ next build |
| `apps/portal` | needs check | — | needs check | needs check | needs check |
| root | ✅ `turbo run lint` (meta-script) | — | ✅ `turbo run typecheck` | ✅ `turbo run test` | ✅ `turbo run build` |

---

## What needs to exist for the full suite

### 1. Root `package.json` — add missing scripts

```json
{
  "scripts": {
    "lint": "turbo run lint",
    "check": "turbo run check",
    "check:depcruise": "dependency-cruiser audit --no-progress",
    "check:viewport-heights": "turbo run check:viewport-heights",
    "check:raw-glass": "turbo run check:raw-glass",
    "check:layout-primitives": "turbo run check:layout-primitives"
  }
}
```

### 2. Root `turbo.json` — add missing tasks

```json
{
  "tasks": {
    "lint": { "dependsOn": ["^lint"], "outputs": [] },
    "lint:stories": { "dependsOn": ["^lint"], "outputs": [] },
    "check": {
      "dependsOn": [
        "lint", "lint:stories",
        "typecheck", "test", "build",
        "check:depcruise",
        "check:viewport-heights",
        "check:raw-glass",
        "check:layout-primitives"
      ],
      "outputs": [],
      "cache": false
    },
    "check:depcruise": { "outputs": [] },
    "check:viewport-heights": { "outputs": [] },
    "check:raw-glass": { "outputs": [] },
    "check:layout-primitives": { "outputs": [] }
  }
}
```

Cache: `false` for `check` to force fresh execution on every run (the point is
validation, not speed).

### 3. `packages/ui/package.json` — add lint scripts

```json
{
  "scripts": {
    "lint": "eslint src --max-warnings=0",
    "lint:stories": "node ../../scripts/check-stories.mjs",
    "test-storybook": "storybook dev -p 6006 --no-open & sleep 3 && test-storybook --url http://localhost:6006; kill %1"
  }
}
```

### 4. `scripts/check-stories.mjs` — storybook story audit

This is the **new** CI script that validates storybook story quality. It should:

1. Find every `.tsx` component file in `packages/ui/src/` (excluding `index.ts`,
   `.types.ts`, `.styles.ts`, `.test.tsx`, `.stories.tsx`)
2. Check that a co-located `.stories.tsx` exists
3. Parse each story file and validate:
   - Tags include `"autodocs"` + tier + framework
   - No `export const AllVariants` or combined state stories
   - No `variant="base"` on Surface
   - No `if`/ternary inside stories
4. Report violations with file paths and line numbers

```mjs
#!/usr/bin/env node
// scripts/check-stories.mjs — validate Storybook story quality
//
// Usage: node scripts/check-stories.mjs
//        node scripts/check-stories.mjs --fix (auto-fix where possible)
//
// Exit code: 0 = clean, 1 = violations found

import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative, resolve } from "node:path";

const UI_PACKAGE = resolve(import.meta.dirname, "../packages/ui/src");
const EXCLUDED_COMPONENTS = new Set([
  "index", "data", "types", "demo-data", "constants", "utils", "helpers",
]);

// Patterns that indicate hand-rolled archetype anti-patterns in stories
const HANDROLLED_SURFACE_VARIANTS = /variant:\s*["']base["']/;

let violations = 0;

function* walk(dir, depth = 0) {
  if (depth > 8) return; // safety
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry);
    if (statSync(path).isDirectory()) {
      if (entry.startsWith("_") || entry.startsWith(".")) continue;
      yield* walk(path, depth + 1);
    } else {
      yield path;
    }
  }
}

function relativePath(absolute) {
  return relative(UI_PACKAGE, absolute);
}

// Step 1: Find all component files and check for co-located stories
const components = new Map(); // relative dir → [component files]
for (const file of walk(UI_PACKAGE)) {
  if (!file.endsWith(".tsx") && !file.endsWith(".ts")) continue;
  const name = file.split("/").pop().replace(/\.(tsx|ts)$/, "");
  if (EXCLUDED_COMPONENTS.has(name)) continue;
  if (name.endsWith(".stories")) continue;
  if (name.endsWith(".test")) continue;
  if (name.endsWith(".types")) continue;
  if (name.endsWith(".styles")) continue;
  if (name.endsWith(".spec")) continue;

  const dir = file.substring(0, file.lastIndexOf("/"));
  const key = relativePath(dir);
  if (!components.has(key)) components.set(key, []);
  components.get(key).push(file);
}

for (const [dir, files] of components) {
  const hasStory = files.some(f => {
    const base = f.replace(/\.(tsx|ts)$/, "");
    return (
      readdirSync(join(UI_PACKAGE, dir)).some(e =>
        e === `${base.split("/").pop()}.stories.tsx`
      )
    );
  });

  if (!hasStory) {
    for (const file of files) {
      const componentName = file.split("/").pop().replace(/\.(tsx|ts)$/, "");
      const storyPath = `${join(UI_PACKAGE, dir)}/${componentName}.stories.tsx`;
      console.log(
        `::error title=Missing story,file=${relativePath(file)}::` +
        `Component '${componentName}' has no co-located story file. ` +
        `Expected: ${relativePath(storyPath)}`
      );
      violations++;
    }
  }
}

// Step 2: Validate story files
for (const file of walk(UI_PACKAGE)) {
  if (!file.endsWith(".stories.tsx")) continue;
  const content = readFileSync(file, "utf-8");

  // Check for combined state stories
  if (content.includes("AllVariants") || content.includes("All Variants")) {
    console.log(
      `::warning title=Combined story,file=${relativePath(file)}::` +
      `Story exports 'AllVariants' — split into individual state stories.`
    );
    violations++;
  }

  // Check for conditionals inside stories
  const lines = content.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    // Match `if (` or ternary `?` inside a StoryObj definition
    if (
      (line.includes("if (") || line.includes("if(")) &&
      !line.includes("// ") && // not a comment
      !line.includes("/*")
    ) {
      // Check if we're inside a StoryObj block (rough heuristic)
      if (content.substring(0, content.indexOf("\n", content.indexOf(line))).includes("StoryObj")) {
        console.log(
          `::warning title=Conditional in story,file=${relativePath(file)},line=${i + 1}::` +
          `Story contains 'if' conditional — write separate stories instead.`
        );
        violations++;
      }
    }
  }

  // Check for invalid Surface variants in stories
  for (let i = 0; i < lines.length; i++) {
    if (HANDROLLED_SURFACE_VARIANTS.test(lines[i])) {
      console.log(
        `::error title=Invalid Surface variant,file=${relativePath(file)},line=${i + 1}::` +
        `Surface variant="base" does not exist. Use variant="white".`
      );
      violations++;
    }
  }

  // Check for tag taxonomy on the meta block
  const hasTags = /tags:\s*\[/.test(content);
  if (!hasTags) {
    console.log(
      `::warning title=Missing tags,file=${relativePath(file)}::` +
      `Story meta block lacks 'tags' array. Stories need "autodocs" + tier + framework tags.`
    );
    violations++;
  }

  if (!content.includes('"autodocs"')) {
    console.log(
      `::warning title=Missing autodocs tag,file=${relativePath(file)}::` +
      `Story missing "autodocs" tag — won't appear in auto-generated docs.`
    );
    violations++;
  }
}

process.exit(violations > 0 ? 1 : 0);
```

### 5. `.github/workflows/check.yml` — CI gate

```yml
# .github/workflows/check.yml — full monorepo check on every PR
name: check
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

env:
  NODE_VERSION: "22"

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 12.18.0
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: pnpm

      - run: pnpm install --frozen-lockfile

      - name: Run full check suite
        run: pnpm check

      - name: Run dependency-cruiser
        run: pnpm check:depcruise
        if: always()
```

---

## How to add a new check

1. **Write the check script** → `scripts/check-<name>.mjs`. Must exit 0 on success, non-zero on failure.
2. **Add the turbo task** → `turbo.json`: `"check-<name>": { "outputs": [] }`
3. **Wire into root** → `package.json`: `"check:<name>": "turbo run check:<name>"`
4. **Wire into `check`** → `turbo.json`: add `"check-<name>"` to `check`'s `dependsOn`
5. **Add the package script** → each package that needs it: `"check:<name>": "..."`
6. **Test** → `pnpm check:<name>` from root

---

## Gotchas

1. **`turbo run lint` resolves `pnpm lint` per package.** If a package has no `lint` script in its `package.json`, the lint task for that package is a no-op. This is fine — packages that don't need linting (data packages, config packages) stay silent. But packages that DO need linting but lack the script will silently pass. The check-stories script should flag this.

2. **`dependsOn: ["^build"]` means upstream packages must build first.** If `@analygo/contracts` fails `build`, `typecheck` on `@analygo/ui` doesn't run. This is correct — type checking depends on built types — but it means a build failure cascades. For fastest feedback, consider a `check:parallel` task that runs `lint` + `check:*` scripts (which don't depend on `^build`) before `typecheck`.

3. **The `check` task has `cache: false`.** Validation should always run fresh. Other tasks (`lint`, `typecheck`, `test`) should use caching normally.

4. **Storybook checks require the `sk-storybook-component-testing` skill to be loaded** for package-specific writing/auditing. The `check-stories.mjs` script validates structure (co-location, tags, conditionals) but not semantics (correct JSDoc, correct states). Semantic audit requires human review or the agent skill.

5. **`test-storybook` flakiness.** Starting storybook in the `test-storybook` script with `& sleep 3` is fragile. For CI, use `storybook build` then `test-storybook --url file://...` against the static build, or use `@storybook/addon-vitest` which starts storybook as a vitest fixture.

6. **Dependency-cruiser runs at root level**, not per-package. The `check:depcruise` script is `dependency-cruiser audit --no-progress`. It checks the entire monorepo's import graph against the `.dependency-cruiser/*.rules.cjs` files.

7. **`pnpm check` must pass before merge.** No exceptions. This is enforced by the branch protection rule: require status check "check" to pass before merging to main.

---

## References

- `turbo.json` — the task dependency graph
- `package.json` — root orchestrator scripts
- `scripts/check-stories.mjs` — the storybook audit script
- `scripts/check-viewport-heights.mjs` — viewport height gate
- `scripts/check-raw-glass.mjs` — glass/blur CSS gate
- `scripts/check-layout-primitives.mjs` — layout primitive usage gate
- `scripts/check-handrolled-ui.mjs` — consumer hand-rolled UI gate
- `.github/workflows/check.yml` — CI check workflow
- `.dependency-cruiser/` — import graph rules
- `.pi/skills/analygo-ui-layout/SKILL.md` — layout primitive rules
- `.pi/skills/analygo-ui-archetypes/SKILL.md` — archetype factory rules
- `.pi/skills/sk-storybook-component-testing/SKILL.md` — storybook story writing rules