# agent-kit Factory — Append Guardrails

These rules apply when working in `~/Projects/agent-kit/`. They supplement Pi's built-in prompt. The global `~/.pi/agent/APPEND_SYSTEM.md` is **replaced** by this file inside this project.

---

## Universal rules (from global)

### Mermaid Block Rendering

Place ` ```mermaid ` blocks directly at the top level of `.md` files — **not** inside any wrapper fence. The renderer will not parse them inside nested fences.

---

## Agent-kit specific rules

### Skill anatomy

Every skill directory MUST have:
```
sk-skill-name/
├── SKILL.md           # Required — frontmatter + body
├── references/        # Optional — supporting docs
├── assets/            # Optional — templates
├── scripts/           # Optional — automation
└── evals/             # Optional — evals
```

### SKILL.md frontmatter (required)

```yaml
---
name: sk-skill-name
description: >
  One-paragraph description. MUST include "Use when" and "NOT for" conditions.
license: MIT
metadata:
  author: hamza
  version: 1.0.0
---
```

### Naming conventions

- Skill directories: `sk-<kebab-case-name>` (e.g. `sk-build-agents-md`)
- AGENTS.md templates: `<workspace>.AGENTS.md` (e.g. `engine.AGENTS.md`)
- SYSTEM.md templates: `SYSTEM.md` (keep the name, organize by directory)
- No YAML frontmatter in AGENTS.md or `.pi/APPEND_SYSTEM.md` — those are plain Markdown

### Distribution rules

- Skills are **authored** in `skills-templates/` and **distributed** via symlinks
- **Never** create a skill directly in `~/.pi/agent/skills/` — always author in agent-kit and symlink
- After adding a skill, update the skill inventory in `AGENTS.md` (Section: Skills by Group)
- After syncing, remind user to `/reload` in Pi

### God File Rule (not applicable here)

The God File Rule applies to the analygo monorepo's `packages/hatchet/src` and `packages/contracts/src` — it does NOT apply to agent-kit (which has no TypeScript code).

---

## Writing quality skills

### Descriptions must be precise

✅ **Good:**
```yaml
description: >
  Build production-quality AGENTS.md files — Pi's directory-walking context
  system. Use when the user asks to create AGENTS.md; set up per-directory
  workspace context; architect cascading instructions across monorepo packages.
  NOT for .pi/APPEND_SYSTEM.md (see sk-build-append-system) or .pi/SYSTEM.md
  (see sk-build-system).
```

❌ **Bad:**
```yaml
description: Create AGENTS.md files.
```

### Trigger conditions

Every SKILL.md must answer:
- **Use when:** List specific scenarios that trigger this skill
- **NOT for:** List scenarios where this skill should NOT be used
- **See also:** Reference related skills by name

### Code examples

Include both ✅ good and ❌ bad examples. Real snippets, not placeholders.

---

## Validation checklist

Before committing a skill:
- ✅ Frontmatter has all required fields (name, description, license, metadata.author, metadata.version)
- ✅ Description includes "Use when" and "NOT for" language
- ✅ File is named `SKILL.md` (capital S)
- ✅ No secrets, API keys, or production configs
- ✅ Symlink created in correct target directory
- ✅ AGENTS.md skill inventory updated
- ✅ Mermaid blocks are at top-level of .md files (not inside wrapper fences)
- ✅ `/reload` instruction given to user

---

## Commands

- **Create skill dir:** `mkdir -p skills-templates/<group>/<skill-name>/{references,assets,scripts,evals}`
- **Sync to Pi:** `ln -sfn $(pwd)/skills-templates/global/* ~/.pi/agent/skills/`
- **Check broken symlinks:** `for l in ~/.pi/agent/skills/*; do [ -e "$l" ] || echo "BROKEN: $l -> $(readlink "$l")"; done`
- **Stale check:** `find ~/.pi/agent/skills/ -xtype l -o -xtype d 2>/dev/null`