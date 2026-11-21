# agent-kit

Canonical source-of-truth for Pi agent context files (AGENTS.md), skill definitions
(SKILL.md), and system prompt templates (SYSTEM.md). Authored in `agent-kit/`,
distributed to consumers via **chezmoi-managed symlinks**.

## Architecture

```
agent-kit/                              ← single source of truth
├── skills-templates/                   ← all skill definitions
│   ├── global/                         ← → ~/.pi/agent/skills (dir-level chezmoi symlink)
│   ├── analygo/                        ← → analygo/*/.pi/skills (per-skill chezmoi symlinks)
│   └── hamza-workspace/                ← → hamza-workspace/*/.pi/skills
├── agents-templates/                   ← AGENTS.md files by workspace
├── system-templates/                   ← SYSTEM.md prompt replacements
├── AGENTS.md                           ← root context — factory persona
└── .pi/APPEND_SYSTEM.md                ← project guardrails
```

```
~/.pi/agent/skills → agent-kit/skills-templates/global    ← directory symlink (chezmoi)
```

| Consumer `.pi/skills/` | Skills | Symlink → |
|---|---|---|
| `analygo/apps/.pi/skills` | 6 | `agent-kit/analygo/apps/<name>/<name>/` |
| `analygo/packages/hatchet/.pi/skills` | 11 | `agent-kit/analygo/hatchet/<name>/<name>/` |
| `analygo/packages/ui/.pi/skills` | 10 | `agent-kit/analygo/ui/<name>/<name>/` |
| `analygo/packages/contracts/.pi/skills` | 2 | `agent-kit/analygo/contracts/<name>/<name>/` |
| `hamza-workspace/.pi/skills` | 5 | `agent-kit/hamza-workspace/root/<name>/` |
| `hamza-workspace/strategy/.pi/skills` | 1 | `agent-kit/hamza-workspace/strategy/<name>/` |

## Chezmoi State Files

Each consumer `.pi/skills/<name>` symlink is tracked as a chezmoi state file under
`~/hamza-workspace/chezmoi/`. The state file contains the symlink target path.

### Chezmoi file → target mapping

| Chezmoi state file | Creates symlink |
|---|---|
| `dot_pi/agent/symlink_skills` | `~/.pi/agent/skills` → global/ |
| `Projects/analygo/apps/dot_pi/skills/symlink_autumn-catalog` | `analygo/apps/.pi/skills/autumn-catalog` → apps/autumn-catalog/ |
| `Projects/analygo/apps/dot_pi/skills/symlink_autumn-concepts` | `analygo/apps/.pi/skills/autumn-concepts` → apps/autumn-concepts/ |
| `Projects/analygo/apps/dot_pi/skills/symlink_autumn-integrate` | `analygo/apps/.pi/skills/autumn-integrate` → apps/autumn-integrate/ |
| `Projects/analygo/apps/dot_pi/skills/symlink_autumn-setup` | `analygo/apps/.pi/skills/autumn-setup` → apps/autumn-setup/ |
| `Projects/analygo/apps/dot_pi/skills/symlink_sk-platform-nav` | `analygo/apps/.pi/skills/sk-platform-nav` → apps/sk-platform-nav/ |
| `Projects/analygo/apps/dot_pi/skills/symlink_sk-route-consolidation` | `analygo/apps/.pi/skills/sk-route-consolidation` → apps/sk-route-consolidation/ |
| `Projects/analygo/packages/hatchet/dot_pi/skills/symlink_sk-hatchet-*` | `analygo/packages/hatchet/.pi/skills/sk-hatchet-*` → hatchet/sk-hatchet-*/ |
| `Projects/analygo/packages/ui/dot_pi/skills/symlink_*` | `analygo/packages/ui/.pi/skills/*` → ui/*/ |
| `Projects/analygo/packages/contracts/private_dot_pi/private_skills/symlink_*` | `analygo/packages/contracts/.pi/skills/*` → contracts/*/ |
| `hamza-workspace/dot_pi/skills/symlink_*` | `hamza-workspace/.pi/skills/*` → root/*/ |
| `hamza-workspace/strategy/dot_pi/skills/symlink_strat-task-warrior` | `hamza-workspace/strategy/.pi/skills/strat-task-warrior` → strategy/strat-task-warrior/ |

### Chezmoi naming conventions

| Prefix | Meaning | Example | Creates |
|---|---|---|
| `dot_` | file/dir prefixed with `.` | `dot_pi/` → `~/.pi/` |
| `private_` | 0700 permissions | `private_dot_pi/` → `~/.pi/` (private) |
| `symlink_` | creates a symlink | `symlink_skills` → symlink at `~/.pi/agent/skills` |

All 38 symlink state files are at `~/hamza-workspace/chezmoi/`.

## Adding a New Skill

### 1. Author the skill

```bash
# Global
mkdir -p skills-templates/global/sk-my-skill/{references,assets}

# Analygo (per-package)
mkdir -p skills-templates/analygo/hatchet/sk-my-skill/sk-my-skill/{references,assets}

# Hamza workspace
mkdir -p skills-templates/hamza-workspace/root/sk-my-skill/{references,assets}
```

Write `SKILL.md` in the innermost directory with required frontmatter:
```yaml
---
name: sk-my-skill
description: >
  One-paragraph description with trigger conditions. Use when.... NOT for...
license: MIT
metadata:
  author: hamza
  version: 1.0.0
---
```

### 2. Register the symlink in chezmoi

```bash
# Global (dir-level symlink, no per-skill needed)
# ~/.pi/agent/skills already → agent-kit/global/ — new dir appears automatically

# Analygo / hamza (per-skill symlink needed)
chezmoi add ~/Projects/analygo/packages/hatchet/.pi/skills/sk-my-skill
chezmoi apply
```

### 3. Update AGENTS.md index

Add the skill to the Skills by Group table in `AGENTS.md`.

## Removing a Skill

### 1. Check for dependents

```bash
rg -l "sk-old-skill" skills-templates/ agents-templates/
```

### 2. Remove source

```bash
rm -rf skills-templates/global/sk-old-skill
```

### 3. Remove chezmoi state

```bash
chezmoi purge ~/Projects/analygo/packages/hatchet/.pi/skills/sk-old-skill
chezmoi apply
```

### 4. Remove from AGENTS.md

## Commands

```bash
# Authoring
mkdir -p skills-templates/analygo/hatchet/sk-my-skill/sk-my-skill/references

# State management
chezmoi add ~/.pi/agent/skills                                                  # track new symlink
chezmoi add ~/Projects/analygo/packages/hatchet/.pi/skills/sk-my-skill          # track per-skill symlink
chezmoi diff                                                                    # preview pending changes
chezmoi apply                                                                  # apply state to filesystem
chezmoi purge ~/Projects/analygo/packages/hatchet/.pi/skills/sk-old-skill       # remove tracked state

# Verification
chezmoi status ~/Projects/analygo/packages/hatchet/.pi/skills/                  # is it managed?
ls -la ~/.pi/agent/skills/                                                      # global skills
find ~/hamza-workspace/chezmoi -name "symlink_*" -type f | wc -l               # count managed symlinks
```

## Skill Anatomy

```
sk-my-skill/
├── SKILL.md           # Required — frontmatter + body
├── references/        # Optional — supporting docs
├── assets/            # Optional — templates
├── scripts/           # Optional — automation
└── evals/             # Optional — evaluation cases
```

## Layout Rules

- `skills-templates/` named with `-templates` suffix to prevent harness auto-scanning
- Global skills: flat structure (`global/sk-name/SKILL.md`)
- Analygo skills: double-nested (`analygo/<pkg>/sk-name/sk-name/SKILL.md`)
- Hamza skills: flat structure (`hamza/<area>/sk-name/SKILL.md`)
- No YAML frontmatter in AGENTS.md or .pi/APPEND_SYSTEM.md (plain Markdown only)
- `sk-` prefix for skill directories
- `<workspace>.AGENTS.md` for agent template files

## Total Inventory

| Group | Count |
|---|---|
| Global skills | 11 |
| Analygo skills | 30 |
| Hamza skills | 6 |
| Agent templates | 11 |
| System templates | 1 |
| **Chezmoi symlink states** | **38** |