---
name: sk-build-agents-md
description: >
  Build production-quality AGENTS.md files — Pi's directory-walking context system:
  no project trust needed, walks up parent directories, merges all files found.
  AGENTS.md lives at the directory root (e.g., apps/AGENTS.md), never inside .pi/.
  Ideal for monorepo hub-and-spoke architecture where each directory layer adds
  delta rules. Use when the user asks to create AGENTS.md; set up per-directory
  workspace context; architect cascading instructions across monorepo packages;
  or when the user mentions "hierarchical context", "CLAUDE.md", "directory-walking",
  or "context files". Does NOT cover .pi/APPEND_SYSTEM.md (see sk-build-append-system)
  or .pi/SYSTEM.md (see sk-build-system).
---

# sk-build-agents-md — Hierarchical Context File Factory

Pi loads AGENTS.md by **walking up directories** from cwd to `/` (plus
`~/.pi/agent/`), loading and **concatenating every file** found. No project trust
needed. This is ideal for monorepo hub-and-spoke context where each directory
layer adds delta rules.

See `~/.pi/agent/docs/configuration.md` for the canonical docs.

---

## 1. Understand the three instruction-file systems

Pi has **three separate** mechanisms. They behave differently and serve different
purposes. Do not confuse them.

| Mechanism | Discovery | Composition | Trust needed? | Best for |
|---|---|---|---|---|
| **`AGENTS.md`** | Walks up from cwd to `/` + checks `~/.pi/agent/` | **Merges** all files found (concatenated) | No | Architecture, commands, conventions, boundaries per directory |
| **`.pi/APPEND_SYSTEM.md`** | Exact `cwd/.pi/` only | **Replaces** global `APPEND_SYSTEM.md` | Yes | Hard repo-level guardrails, persona rules |
| **`.pi/SYSTEM.md`** | Exact `cwd/.pi/` only | **Replaces** Pi's core prompt entirely | Yes | Custom non-coding agents only |

**Key constraint:** AGENTS.md is **not** `.pi/APPEND_SYSTEM.md`. Never write AGENTS.md
inside a `.pi/` directory. Never name it `APPEND_SYSTEM.md` or `SYSTEM.md`.

---

## 2. Determine if AGENTS.md is the right choice

Use AGENTS.md when:

- ✅ You want instructions to cascade (parent → child directories)
- ✅ You want context to apply **without** requiring project trust
- ✅ You're setting up monorepo-wide conventions that work across apps and packages
- ✅ You want per-directory **delta rules** that add to, not replace, parent context
- ✅ The context is about commands, architecture, boundaries, and conventions

Use `.pi/APPEND_SYSTEM.md` (see sk-build-append-system) or `.pi/SYSTEM.md` (see sk-build-system) when:

- ❌ You need project trust gating (secrets, production config)
- ❌ You want to override user-wide rules rather than merging with them
- ❌ You need persona/behavioral guardrails, not just context

---

## 3. Architect the monorepo layout

**Hub-and-Spoke** design — one root AGENTS.md with global context, child directories
add only their delta:

```text
~/Projects/analygo/                  # Monorepo Root
├── AGENTS.md                        # Global repo map, turbo/pnpm commands, cross-pkg rules
│
├── apps/
│   ├── AGENTS.md                    # Shared frontend/Next.js conventions
│   ├── portal/
│   │   └── AGENTS.md                # Portal-specific routes, state, domain rules
│   └── admin/
│       └── AGENTS.md                # Admin-specific rules
│
└── packages/
    └── ui/
        └── AGENTS.md                # Design system token rules & component authoring rules
```

**How it works at runtime:**
- Launch `pi` in `apps/portal/` → Pi loads `analygo/AGENTS.md` + `apps/AGENTS.md` + `portal/AGENTS.md`
- Launch `pi` in `packages/ui/` → Pi loads `analygo/AGENTS.md` + `ui/AGENTS.md`
- Each file documents only **delta rules** for its directory — never repeats parent content

---

## 4. Create the file

Place at `<target-dir>/AGENTS.md` — **never** inside `.pi/`.

### Anti-duplication rule

Before writing `<target-dir>/AGENTS.md`, inspect parent directories up to the
monorepo root for existing `AGENTS.md` files. The new file should document only
**delta rules** specific to that workspace. Do not repeat root-level commands,
global architecture, or conventions already covered by a parent.

### No YAML frontmatter

AGENTS.md is plain Markdown. No frontmatter. (The `---` frontmatter in this skill
file is for the skill system, not the output.)

---

## 5. Write the file

### Structure — cover six core areas concisely

Keep under ~150 lines. Each file is loaded and concatenated with others — brevity
matters more here than in `.pi/APPEND_SYSTEM.md`.

**Persona** — define the role Pi should adopt for this directory:

```markdown
You are an expert <role> for this project.

- You specialize in <what>
- You understand <domain> and translate that into <output>
```

**Commands early** — put executable commands in an early section:

```markdown
## Commands
- **Build:** `pnpm build` (compiles TypeScript, outputs to dist/)
- **Test:** `pnpm test` (runs Vitest, must pass before commits)
- **Lint:** `pnpm lint --fix` (auto-fixes ESLint errors)
- **Type-check:** `npx tsc --noEmit` (catches type errors)
```

**Architecture & Boundaries** — directory structure + three-tier boundaries:

```markdown
## Architecture
- `src/` — Application source code
- `packages/` — Shared libraries (contracts, ui, utils)
- `apps/` — Consumer applications

## Boundaries
- ✅ **Always:** Write to `src/` and `tests/`, run tests before commits
- ⚠️ **Ask first:** Database schema changes, adding dependencies, CI/CD
- 🚫 **Never:** Commit secrets, edit `node_modules/`, modify production configs
```

**Workflow** — git workflow and release process:

```markdown
## Workflow
- Branch from `main`, merge via squash
- Commit messages: `type(scope): description` (e.g. `feat(auth): add OAuth login`)
- PRs require 1 approval and passing CI
```

---

## 6. Write delta rules by directory level

| Level | What to put | Example |
|---|---|---|
| **Root** (`~/Project/`) | Global commands, monorepo tooling, package manager, top-level dir map | `pnpm` commands, Turbo config, cross-pkg boundaries |
| **Subtree** (`apps/`, `packages/`) | Shared conventions for that subtree | Frontend/Next.js conventions, UI design rules |
| **Leaf** (`portal/`, `admin/`, `ui/`) | Directory-specific rules only | Portal route structure, UI token names, domain-specific patterns |

**Anti-pattern — don't do this:**
- ❌ Putting `apps/AGENTS.md` with full Next.js conventions when root AGENTS.md already covers them
- ❌ Making every leaf AGENTS.md a standalone 200-line document (defeats cascading)
- ❌ Writing AGENTS.md inside `.pi/` (wrong mechanism)

---

## 7. Validate

Manual checks:
- ✅ Named `AGENTS.md` — not `APPEND_SYSTEM.md`, `SYSTEM.md`, `CLAUDE.md`
- ✅ Located at target directory root — not inside `.pi/`
- ✅ Plain Markdown — no YAML frontmatter
- ✅ Under ~150 lines
- ✅ Documents only delta rules for this directory level
- ✅ Does not repeat parent AGENTS.md content
- ✅ Covers six core areas: persona, commands, architecture, boundaries, workflow, project knowledge
- ✅ Commands use exact flags and options, not just tool names
- ✅ Boundaries cover all three tiers (always / ask-first / never)

---

## 8. Report

Full path, one-line persona/role description, directory level (root / subtree / leaf),
parent AGENTS.md files found (including paths), and brief summary of delta rules.

---

## Templates

Use `assets/templates/` for starting points:

- `assets/templates/agents-sketch.md` — quick outline for a single AGENTS.md file
- `assets/templates/agents-monorepo.md` — full hub-and-spoke monorepo layout
- `assets/templates/agents-leaf.md` — minimal leaf-directory delta template

## References

- `references/refinement.md` — how to iterate after mistakes (shared with sk-build-append-system and sk-build-system)
- `~/.pi/agent/docs/configuration.md` — canonical Pi configuration docs