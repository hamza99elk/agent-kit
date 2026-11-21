---
name: sk-build-append-system
description: >
  Build .pi/APPEND_SYSTEM.md — Pi's project-level guardrail file that adds
  instructions to Pi's built-in prompt (does NOT replace it). Unlike AGENTS.md
  (directory-walking, no trust needed), APPEND_SYSTEM.md lives in cwd/.pi/,
  requires project trust, and replaces ~/.pi/agent/APPEND_SYSTEM.md entirely
  (no merging). Use when creating project-level persona rules, code style
  enforcement, hard boundaries, or production constraints; when the user mentions
  "project rules", "per-project behavior", or "guardrails"; or when they ask for
  APPEND_SYSTEM.md. Does NOT cover AGENTS.md (see sk-build-agents-md) or SYSTEM.md
  (see sk-build-system).
---

# sk-build-append-system — Behavioral Guardrails (APPEND_SYSTEM.md)

`.pi/APPEND_SYSTEM.md` adds instructions to Pi's built-in system prompt. It
**replaces** (not merges with) `~/.pi/agent/APPEND_SYSTEM.md`. Only applies after
project trust is granted. Only reads from the exact `cwd/.pi/` directory — no
directory-walking.

This is the right mechanism for **hard rules, persona, and guardrails** that
should gate on trust. It preserves Pi's built-in coding tools (read, write, edit,
bash) — unlike `SYSTEM.md` which replaces the entire prompt.

For hierarchical context that cascades across directories without trust, use
`AGENTS.md` (see sk-build-agents-md). For full system prompt replacement
(custom non-coding agents), use `SYSTEM.md` (see sk-build-system).

See `~/.pi/agent/docs/configuration.md` for the canonical docs.

---

## 1. Understand the three instruction-file systems

Pi has **three separate** mechanisms. They behave differently and serve different
purposes. Do not confuse them.

| Mechanism | Discovery | Composition | Trust needed? | Best for |
|---|---|---|---|---|
| **`AGENTS.md`** | Walks up from cwd to `/` + checks `~/.pi/agent/` | **Merges** all files found (concatenated) | No | Architecture, commands, conventions, boundaries per directory |
| **`.pi/APPEND_SYSTEM.md`** | Exact `cwd/.pi/` only | **Replaces** global `APPEND_SYSTEM.md` | Yes | Hard repo-level guardrails, persona rules, code style |
| **`.pi/SYSTEM.md`** | Exact `cwd/.pi/` only | **Replaces** Pi's core prompt entirely | Yes | Custom non-coding agents only |

**Key insight:** APPEND_SYSTEM.md is *additive* — it layers on top of Pi's built-in
capabilities. SYSTEM.md is *replacement* — it strips Pi down to a blank slate.

---

## 2. Determine if APPEND_SYSTEM.md is the right choice

Use `.pi/APPEND_SYSTEM.md` when:

- ✅ You need project trust gating (secrets, production config, destructive ops)
- ✅ You want to override user-wide rules rather than merge with them
- ✅ You need persona/behavioral guardrails (not just context)
- ✅ The rules are about code style, test patterns, security, or production safety
- ✅ You want the file to be scoped to exact `cwd` — no cascading
- ✅ You want to **keep** Pi's built-in coding tools (read, write, edit, bash)

Use `AGENTS.md` (see sk-build-agents-md) when:

- ❌ You want instructions to cascade across parent/child directories
- ❌ You don't need project trust gating
- ❌ You want context that merges rather than replaces

Use `SYSTEM.md` (see sk-build-system) when:

- ❌ You want to replace Pi's entire system prompt (custom non-coding agent)
- ❌ You don't need Pi's built-in coding tools

---

## 3. CRITICAL: The override problem

**.pi/APPEND_SYSTEM.md completely replaces `~/.pi/agent/APPEND_SYSTEM.md`.**

There is no merging. If the user has global rules in `~/.pi/agent/APPEND_SYSTEM.md`
(e.g., "always use TypeScript", "prefer Vitest"), those rules are **gone** the moment
`.pi/APPEND_SYSTEM.md` exists in the project.

### Check and warn

Before writing `.pi/APPEND_SYSTEM.md`:

1. Check if `~/.pi/agent/APPEND_SYSTEM.md` exists
2. If it does, read its content
3. Warn the user: *"Your global APPEND_SYSTEM.md (~/.pi/agent/APPEND_SYSTEM.md) will be overridden by this project file. The following global rules will be lost: <list essential rules>. Should I include them in the project file?"*
4. Offer to copy essential rules from the global file into the project file

**Do not silently override global rules.** This is the most common mistake with
this skill.

---

## 4. Create the file

Place at `<cwd>/.pi/APPEND_SYSTEM.md`. Ensure `.pi/` directory exists.

**File must be named `APPEND_SYSTEM.md` — not `SYSTEM.md`, not `AGENTS.md`.**

### No YAML frontmatter

`.pi/APPEND_SYSTEM.md` is plain Markdown. No frontmatter.

---

## 5. Write the file

### Structure — cover six core areas

**Persona — define the role Pi should adopt for this project:**

```markdown
You are an expert <role> for this project.

- You specialize in <what>
- You understand <domain> and translate that into <output>
```

**Commands early — exact flags and options, not just tool names:**

```markdown
## Commands
- **Build:** `pnpm build` (compiles TypeScript, outputs to dist/)
- **Test:** `pnpm test` (runs Vitest, single-run mode with --reporter=verbose)
- **Test (watch):** `pnpm test -- --watch` (re-runs on file changes)
- **Lint:** `pnpm lint --fix` (auto-fixes ESLint errors)
- **Type-check:** `npx tsc --noEmit` (catches type errors without emitting files)
- **Format:** `pnpm format` (formats with Prettier)
```

**Project knowledge — tech stack + file structure:**

```markdown
## Project knowledge
- **Tech Stack:** React 18, Next.js 14, TypeScript 5, Tailwind CSS v4, pnpm workspaces
- **File Structure:**
  - `src/` — Application source code
  - `tests/` — Unit, integration, and E2E tests
  - `docs/` — All documentation
  - `config/` — ESLint, Prettier, depcruise configs
```

**Code style — real snippets showing good vs bad:**

```markdown
## Standards

**Naming:**
- Functions: camelCase (`getUserData`)
- Classes: PascalCase (`UserService`)
- Constants: UPPER_SNAKE_CASE (`MAX_RETRIES`)

**Example:**
\`\`\`typescript
// ✅ Good - descriptive names, proper error handling, explicit types
async function fetchUserById(id: string): Promise<User> {
  if (!id) throw new Error('User ID required');
  const response = await api.get(`/users/${id}`);
  return response.data;
}

// ❌ Bad - vague names, no error handling, implicit any
async function get(x) {
  return await api.get('/users/' + x).data;
}
\`\`\`
```

**Boundaries — three-tier:**

```markdown
## Boundaries
- ✅ **Always:** Write to `src/` and `tests/`, run tests before commits, follow naming conventions
- ⚠️ **Ask first:** Database schema changes, adding dependencies, modifying CI/CD config
- 🚫 **Never:** Commit secrets or API keys, edit `node_modules/` or `vendor/`, disable type checking
```

**Workflow — git conventions:**

```markdown
## Workflow
- Branch from `main`, merge via squash
- Commit messages: `type(scope): description` (e.g. `feat(auth): add OAuth login`)
- Run `pnpm check:god-files` before pushing
- PRs require 1 approval and passing CI
```

---

## 6. Paired-file pattern (recommended for monorepos)

For best results, **don't use APPEND_SYSTEM.md alone** — pair it with AGENTS.md:

| File | Role | Scope |
|---|---|---|
| `AGENTS.md` (at repo root) | Architecture, commands, directory map | Cascading, no trust needed |
| `.pi/APPEND_SYSTEM.md` | Persona, guardrails, code style enforcement | Scoped to cwd, trust-gated |

AGENTS.md provides the *what* (structure, commands, conventions).
APPEND_SYSTEM.md provides the *how* (persona, behavior, enforcement).

---

## 7. Validate

Manual checks:
- ✅ Named `APPEND_SYSTEM.md` — not `SYSTEM.md`, not `AGENTS.md`
- ✅ Located inside `.pi/` directory
- ✅ Plain Markdown — no YAML frontmatter
- ✅ Warned user about `~/.pi/agent/APPEND_SYSTEM.md` override (step 3)
- ✅ Offered to migrate essential global rules into the project file
- ✅ Commands use exact flags and options, not just tool names
- ✅ Code examples show **both** good and bad
- ✅ Boundaries cover all three tiers
- ✅ Covers all six core areas: persona, commands, testing, project structure, code style, git workflow, boundaries

---

## 8. Report

Full path, one-line persona/role description, whether global APPEND_SYSTEM.md was
found and migrated, commands summary, and key boundaries.

Remind user to run `/reload` in Pi after saving.

---

## Templates

Use `assets/templates/` for starting points:

- `assets/templates/append-system-standalone.md` — full standalone APPEND_SYSTEM.md
- `assets/templates/append-system-minimal.md` — minimal guardrail-only version

## References

- `references/refinement.md` — how to iterate after mistakes (shared with sk-build-agents-md and sk-build-system)
- `~/.pi/agent/docs/configuration.md` — canonical Pi configuration docs

## Related skills

- **sk-build-agents-md** — for AGENTS.md (hierarchical context files, no trust needed)
- **sk-build-system** — for SYSTEM.md (full system prompt replacement)