---
name: sk-pi-hygene
description: >
  Audit and restructure Pi's context file hierarchy (AGENTS.md, .pi/APPEND_SYSTEM.md, .pi/SYSTEM.md) across a monorepo — trim bloat, enforce progressive density, move content to the correct tier. Use this skill when the user asks to clean up Pi context files; reduce session noise from oversized AGENTS.md or APPEND_SYSTEM.md files; slim bloated AGENTS.md that injects design system rules, database schemas, or framework docs into every session; move PL-specific content from global APPEND_SYSTEM.md into per-workspace SYSTEM.md; check whether a given file's content belongs at its current scope level; decide between AGENTS.md vs .pi/SYSTEM.md vs .pi/APPEND_SYSTEM.md for a piece of information; or organize a inherited repo's Pi context that grew without design. Also for onboarding onto an existing monorepo by measuring context-file hygiene before making changes.
compatibility:
  requires: access to the Pi agent's ~/.pi/ directory and project AGENTS.md/.pi files
metadata:
  version: 1.0.0
---

# sk-pi-hygiene — Pi Context File Organization

The Pi agent loads instructions from four overlapping layers. When they blur together — global rules shoved into AGENTS.md, design specs in APPEND_SYSTEM.md, or verbose docs injected into every session — effective context budget collapses.

This skill teaches you to audit and restructure the hierarchy.

Full spec: https://agentskills.io/specification.md
Best practices: https://agentskills.io/skill-creation/best-practices.md

---

## Prerequisites

- Write access to `~/.pi/agent/APPEND_SYSTEM.md` and the project's `AGENTS.md` / `.pi/SYSTEM.md` files
- Understanding of how Pi loads context: directory-walk for `AGENTS.md`, project trust for `.pi/` files
- No external dependencies

## The Four-Layer Model

File-reading order (closest match wins for system prompt):

| Layer | File | Scope | Mechanism | Density |
|---|---|---|---|---|
| **Layer 0 — System** | `~/.pi/agent/SYSTEM.md` | All sessions on machine | Replaces Pi's built-in prompt | Sparse |
| **Layer 0a — Append** | `~/.pi/agent/APPEND_SYSTEM.md` | All sessions on machine | Augments Pi's built-in prompt | Minimal |
| **Layer 1 — Repo root** | `project/AGENTS.md` | Any session in this repo | Directory-walk (merged with parent) | Thin overview |
| **Layer 1a — Repo append** | `project/.pi/APPEND_SYSTEM.md` | Any session under this project dir | Project trust (replaces global append within scope) | Thin guardrails |
| **Layer 2 — Subtree** | `project/apps/AGENTS.md` | Any session in this subtree | Directory-walk (merged) | Medium — directory map + pointers down |
| **Layer 3 — Workspace** | `project/apps/.pi/SYSTEM.md` | Sessions in this subtree, nearest win | Trusted full prompt replacement | Dense — complete behavioral manual |
| **Layer 4 — Skills** | `~/.pi/agent/skills/*/SKILL.md` | On-demand when task matches description | Loaded as-needed, not in every session | Individually dense, zero baseline cost |

### The progressive-density rule

> Each layer closer to the agent should be **thinner** (less content, higher-level). The densest content lives in the deepest layer (SYSTEM.md or a skill).

This means:

```
Layer 0 (global APPEND):    ONLY universal rules that apply to every project
  └─→ Layer 1 (root AGENTS):    Repo overview, universal commands, context cascade map
        └─→ Layer 2 (sub AGENTS):  Directory map, pointers to SYSTEM.md, boundaries
              └─→ Layer 3 (SYSTEM.md): The complete behavioral manual — full rules, patterns, examples
                    └─→ Layer 4 (skills): Loaded on-demand, zero baseline cost
```

## Audit Workflow

Progress:
- [ ] Step 1: Discover all Pi context files in scope
- [ ] Step 2: Classify each file's content by layer fit
- [ ] Step 3: Identify content that belongs at a different layer
- [ ] Step 4: Move content to the correct layer(s)
- [ ] Step 5: Verify line-count reduction at upper layers
- [ ] Step 6: Verify the cascade still works (no orphaned references)

### Step 1 — Discover

Find all relevant files:

```bash
# Global layer
ls -la ~/.pi/agent/*.md

# Repo-level (adapt project path)
find /path/to/project -maxdepth 5 -name "AGENTS.md" -not -path "*/node_modules/*"
find /path/to/project -maxdepth 4 -name ".pi" -type d -not -path "*/node_modules/*"
```

For each discovered file, record:
- **Path** (absolute)
- **Layer** (global, repo-root, subtree, workspace)
- **Line count** (`wc -l < file`)
- **Content categories** (design rules, DB schema, commands, directory maps, boundaries, etc.)

### Step 2 — Classify content

For each category of content in each file, assign it to where it *should* live:

| Content type | Belongs in | Rationale |
|---|---|---|
| Machine-wide coding conventions (god-file rule, mermaid rendering, multi-repo codemode workflow) | `~/.pi/agent/APPEND_SYSTEM.md` | Applies to every project on this machine |
| Repo layout, monorepo commands, contract-first policy | `project/AGENTS.md` | Universal within the repo, relevant to any subdirectory |
| Per-project guardrails (CI commands, boundary tables, link to SYSTEM.md) | `project/.pi/APPEND_SYSTEM.md` | Replaces global append within project scope; supplements AGENTS.md |
| Framework-specific rules (Next.js, Hono, Tailwind token contracts) | `subtree/AGENTS.md` or `subtree/.pi/SYSTEM.md` | Only relevant when working in that framework's directory |
| Design system contracts, import paths, token values, component API docs | Workspace `.pi/SYSTEM.md` or a skill | High density; injected only into that workspace or on-demand |
| Database schemas, table definitions, migration commands | Workspace `.pi/SYSTEM.md` or subtree `AGENTS.md` of the API/DB package | Only relevant for backend/DB work |
| Step-by-step workflows (how to build a page, how to run a migration) | A skill (`~/.pi/agent/skills/<name>/SKILL.md`) | Loaded on-demand when the agent enters that workflow; zero baseline cost |
| Common pitfalls, troubleshooting, API error catalogs | Skill references (`skills/<name>/references/*.md`) | Loaded on-demand when errors occur |

### Step 3 — Identify mismatches

Common anti-patterns to look for:

| Anti-pattern | Detection | Fix |
|---|---|---|
| **Global APPEND bloat** | `~/.pi/agent/APPEND_SYSTEM.md` contains project-specific content (DB schemas, design rules, per-framework commands) | Strip to only machine-wide rules. Move project-specific content to `project/.pi/APPEND_SYSTEM.md` or deeper |
| **AGENTS.md as SYSTEM.md** | `AGENTS.md` file exceeds 80 lines or contains design-system API docs, import path tables, token contracts | Move dense content to `.pi/SYSTEM.md` at the same level. Keep AGENTS.md as thin overview + pointers |
| **Design docs in APPEND** | Design layout principles, component taxonomies, or golden rules in any `APPEND_SYSTEM.md` | Move to the relevant workspace `SYSTEM.md` or a skill. These are on-demand knowledge, not universal guardrails |
| **DB schema in global context** | Table lists, migration commands, or medallion-architecture docs in top-level files | Move to the backend package's `AGENTS.md` or `.pi/SYSTEM.md`. Only relevant for DB work |
| **Dual sourcing** | Same rule set in both APPEND_SYSTEM.md and AGENTS.md (duplicated) | Pick one owner. APPEND_SYSTEM.md for universal rules, AGENTS.md for repo-specific, never both |
| **SYSTEM.md at wrong depth** | `.pi/SYSTEM.md` exists at repo root AND at a subdirectory, but the subdirectory version is thinner | Swap them — the deeper the directory, the denser the SYSTEM.md should be |
| **Context without cascade** | AGENTS.md or APPEND.md at any level that doesn't point to deeper context files | Add a "Related files" or "Context hierarchy" section that tells the agent where to find more detail |

### Step 4 — Move content

For each mismatch:

1. **Identify the right target layer** for the content (use the classification table from Step 2).
2. **Strip from the current file.** Remove the sections that don't belong at this layer.
3. **Add to the target file.** If the target doesn't exist, create it. If it exists, merge.
4. **Add a pointer.** The higher-level file should mention where the detail now lives: `See apps/.pi/SYSTEM.md for the full design system contract.`
5. **Keep the cascade intact.** After moving, verify that a reader starting at the root can discover where things went.

### Step 5 — Verify line reduction

```bash
# After edits, verify upper layers are thin
echo "Global APPEND: $(wc -l < ~/.pi/agent/APPEND_SYSTEM.md) lines"
echo "Root AGENTS:   $(wc -l < project/AGENTS.md) lines"
echo "Subtree AGENTS: $(wc -l < project/apps/AGENTS.md) lines"
echo "Workspace SYSTEM: $(wc -l < project/apps/.pi/SYSTEM.md) lines"
```

Target ranges:
- Global APPEND_SYSTEM.md: **≤ 30 lines** (god-file + mermaid + maybe 1 more universal rule)
- Root AGENTS.md: **30–60 lines** (repo layout + 5–8 universal commands + context map)
- Subtree AGENTS.md: **40–80 lines** (directory map + pointers + boundary table)
- Workspace SYSTEM.md: **unlimited** (this is the dense behavioral manual)

### Step 6 — Verify the cascade

Walk through: if someone works in `project/apps/platform/api/`, can they find every rule that applies to them?

```text
1. ~/.pi/agent/APPEND_SYSTEM.md      → machine-wide rules (god-file, mermaid)
2. project/AGENTS.md                  → repo layout, universal commands, says "subtree has its own rules"
3. project/.pi/APPEND_SYSTEM.md       → repo-specific guardrails (contracts-first, hatchet tools)
4. project/apps/AGENTS.md             → directory map, says "read .pi/SYSTEM.md for full details"
5. project/apps/.pi/SYSTEM.md         → full design system + platform workflow + boundaries
6. project/apps/platform/api/AGENTS.md → API backend: DB tables, routes, lifecycle
```

Each step should add detail without repeating what the parent already said.

## Gotchas

- **APPEND_SYSTEM.md at `~/.pi/agent/` is global.** It fires in *every* session, not just this project. The God File Rule belongs there (it's a universal coding convention). Database schema tables do NOT. Never put domain-specific content in the global append.
- **Project-level `.pi/APPEND_SYSTEM.md` replaces the global one** when Pi detects project trust. It does NOT merge. If you want project-specific rules, put them here; if you want to preserve the global rules AND add project ones, duplicate them or structure the project append to reference the global.
- **AGENTS.md merges upward** via directory walk. A file at `project/apps/AGENTS.md` merges with `project/AGENTS.md`. This means a rule in the parent AGENTS.md is still visible in the child. Don't repeat rules in child AGENTS.md that the parent already covers.
- **SYSTEM.md replaces the prompt entirely** when Pi enters that workspace. It does NOT merge with parent SYSTEM.md or AGENTS.md. So the SYSTEM.md must be self-contained for its workspace — it cannot assume the reader has seen the parent AGENTS.md.
- **Skills have zero baseline cost** — they are not loaded until the task description matches. This is the best place for step-by-step workflows, domain-specific API docs, and anything >50 lines that isn't needed every session.
- **Do NOT design-system rules in APPEND_SYSTEM.md.** Design rules (10 golden rules, layout hierarchy, token contracts) are workspace-specific. Put them in the workspace SYSTEM.md or a skill. The one exception: a single-line pointer like "See `apps/.pi/SYSTEM.md` for design system rules" can live in the repo AGENTS.md.
- **Line count is a proxy, not an absolute.** A 40-line AGENTS.md that's all imperative "NEVER DO X" is worse than a 60-line one that explains the "why." But a 250-line AGENTS.md is almost always wrong — dense content belongs in SYSTEM.md or a skill.
- **Don't orphan references.** When moving content out of AGENTS.md, add a pointer line: `See apps/.pi/SYSTEM.md for the full design system contract.` Without it, the agent won't know where the rules went.
- **Skills need good descriptions to trigger.** When you move a workflow into a skill, make sure the `description` field uses trigger-oriented language. Don't just say "Builds pages" — say "Use this skill when constructing page layouts from Container/Stack/Grid primitives; creating new routes in apps/platform; composing Surface and Card with the correct variant prop."
- **AGENTS.md files are not trusted — they're directory-walked.** This means they can live anywhere, no `pi trust` needed. `.pi/` files require project trust. Use AGENTS.md for structural context (directory maps, boundaries, pointers) and `.pi/SYSTEM.md` for behavioral instructions.

## Patterns to use

### The pointer pattern

When you move content to a deeper layer, keep a placeholder:

```markdown
## Design system
See `apps/.pi/SYSTEM.md` for the complete design system contract
(10 golden rules, layout hierarchy, import paths, token contracts).
```

### The boundary table pattern

AGENTS.md files work well with a boundaries table:

```markdown
## Boundaries
| ✅ Always | ⚠️ Ask first | 🚫 Never |
|---|---|---|
| Run lint + typecheck before commit | Adding new deps | Root barrel imports |
| Compose from design system first | Changing route structure | Hand-rolled primitives |
```

### The cascade explanation table

Help the agent discover deeper context:

```markdown
## Related files
| File | Role |
|---|---|
| `apps/.pi/SYSTEM.md` | Full behavioral instructions (required reading) |
| `apps/platform/api/AGENTS.md` | API backend agent context |
```

## Evals

### Test prompt 1 — Slim a bloated AGENTS.md

**Prompt:** "I have a 250-line `apps/AGENTS.md` that contains the full design system manual (import paths, golden rules, token contracts, layout hierarchy, 20+ anti-patterns). Where should each section go instead? Show me the deltas."

**Expected outcome:** Knows to move design system content to `apps/.pi/SYSTEM.md`, commands to SYSTEM.md or a skill, keep only directory map + pointers + boundaries in AGENTS.md.

### Test prompt 2 — Global APPEND audit

**Prompt:** "My `~/.pi/agent/APPEND_SYSTEM.md` is 130 lines and contains: God File Rule, Mermaid rendering rules, 10 design layout golden rules, and a full database schema overview with 9 schemas and their tables. Which of these should stay?"

**Expected outcome:** Identifies God File Rule and Mermaid as universal (keep). Identifies design rules + DB schema as project-specific (move to project-level or deeper).

### Test prompt 3 — Dual sourcing detection

**Prompt:** "I have the same '10 golden rules' repeated in three places: `~/.pi/agent/APPEND_SYSTEM.md`, `~/project/AGENTS.md`, and `~/project/apps/.pi/SYSTEM.md`. Which should I keep and which should I remove?"

**Expected outcome:** Removes from global APPEND and root AGENTS. Keeps only in the workspace SYSTEM.md (or a skill). Adds a pointer at the removed locations.

---

*Generated by sk-build-skill*