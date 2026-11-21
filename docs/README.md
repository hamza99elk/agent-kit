# agent-kit — AI Harness (Cluster 2)

Canonical source-of-truth for Pi agent context files, skill definitions,
and system prompt templates. This repo is **independent of chezmoi** —
symlink fan-out is handled by `scripts/sprout-skills.sh`.

## Architecture

```
agent-kit/
├── skills-templates/           ← all skill definitions
│   ├── global/                 ← → ~/.pi/agent/skills (dir-level symlink)
│   ├── analygo/                ← → $workspace/.pi/skills (sprout-skills fan-out)
│   └── hamza-workspace/        ← → $workspace/.pi/skills
├── agents-templates/           ← AGENTS.md files by workspace
├── system-templates/           ← SYSTEM.md prompt replacements
├── scripts/
│   ├── sprout-skills.sh        ← Symlink fan-out engine (standalone)
│   ├── audit-skills.sh         ← SKILL.md quality check
│   └── sync-global-skills.sh   ← Legacy global sync (deprecated by sprout-skills)
├── AGENTS.md                   ← Root context — factory persona
└── .pi/APPEND_SYSTEM.md        ← Project guardrails
```

### Distribution model

Skills are **authored in agent-kit** and **fanned out** via `sprout-skills.sh`:

| Consumer `.pi/skills/` | Source | Symlink → |
|---|---|---|
| `~/.pi/agent/skills` | `global/` | Dir-level symlink (maintained by sprout-skills) |
| `analygo/packages/hatchet/.pi/skills` | `analygo/hatchet/` | 11 skills |
| `analygo/packages/ui/.pi/skills` | `analygo/ui/` | 10 skills |
| `analygo/packages/contracts/.pi/skills` | `analygo/contracts/` | 1 skill |
| `analygo/packages/aegis/.pi/skills` | `analygo/aegis/` | 1 skill |
| `analygo/apps/.pi/skills` | `analygo/apps/` | 6 skills |
| `analygo/.pi/skills` | `analygo/root/` | 5 skills |
| `hamza-workspace/.pi/skills` | `hamza-workspace/root/` | 5 skills |
| `hamza-workspace/strategy/.pi/skills` | `hamza-workspace/strategy/` | 1 skill |

### Bridge to chezmoi

The **only** connection to Chef (Cluster 1) is:

```
chezmoi/run_onchange_after_sprout-skills.sh.tmpl
  ↳ calls agent-kit/scripts/sprout-skills.sh --apply
```

When you run `just apply` in chezmoi, the `run_onchange_after_` hook triggers
the fan-out script. No chezmoi state files needed per-skill.

## Adding a New Skill

### 1. Author the skill

```bash
bash scripts/audit-skills.sh   # check current state first
```

Create the directory:
```bash
# Global (always available)
mkdir -p skills-templates/global/sk-my-skill/{references,assets}

# Analygo (per-package)
mkdir -p skills-templates/analygo/hatchet/sk-my-skill/{references,assets}

# Analygo (root level — shared skills)
mkdir -p skills-templates/analygo/root/sk-my-skill/{references,assets}

# Hamza workspace
mkdir -p skills-templates/hamza-workspace/root/sk-my-skill/{references,assets}
```

Write `SKILL.md` with required frontmatter:
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

### 2. Fan out the symlink

```bash
bash scripts/sprout-skills.sh --apply
```

**No chezmoi edits needed.** Adding a skill = a git commit in agent-kit + running
sprout-skills. That's it.

### 3. Update AGENTS.md index

Add the skill to the Skills by Group table in `AGENTS.md`.

## Removing a Skill

### 1. Check for dependents

```bash
rg -l "sk-old-skill" skills-templates/ agents-templates/
```

### 2. Remove source + fan-out

```bash
rm -rf skills-templates/global/sk-old-skill
bash scripts/sprout-skills.sh --prune    # cleans broken symlinks
bash scripts/sprout-skills.sh --apply    # refreshes everything
```

### 3. Remove from AGENTS.md

## Commands

```bash
# Authoring
mkdir -p skills-templates/analygo/hatchet/sk-my-skill/sk-my-skill/references
mkdir -p skills-templates/analygo/hatchet/sk-my-skill/{references,assets}

# Fan-out
bash scripts/sprout-skills.sh --apply    # write/update all symlinks
bash scripts/sprout-skills.sh --prune    # remove broken links
bash scripts/sprout-skills.sh            # dry-run (default)

# Quality
bash scripts/audit-skills.sh

# Verify
readlink ~/Projects/analygo/packages/hatchet/.pi/skills/sk-hatchet-test-new
readlink ~/.pi/agent/skills
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

### SKILL.md frontmatter

```yaml
---
name: sk-my-skill
description: >
  Use when... NOT for...
license: MIT
metadata:
  author: hamza
  version: 1.0.0
---
```

## Layout Rules

- `skills-templates/` named with `-templates` suffix to prevent harness auto-scanning
- Some skills (hatchet, ui, apps, contracts) use **double nesting**:
  `sk-name/sk-name/SKILL.md` — inner dir is the real skill root
- Other skills (root, global, hamza) are **flat**: `sk-name/SKILL.md`
- `sprout-skills.sh` auto-detects: if a same-named subdir exists, symlinks to it
- No YAML frontmatter in `AGENTS.md` or `.pi/APPEND_SYSTEM.md` (plain Markdown only)
- `sk-` prefix for skill directories
- `<workspace>.AGENTS.md` for agent template files

## Total Inventory

| Group | Count |
|---|---|
| Global skills | 11 |
| Analygo skills | 33 |
| Hamza skills | 6 |
| Agent templates | 11 |
| System templates | 1 |

## Related

- `~/ops/mac-hardening` — Cluster 4 (independent git repo)
- `~/notes` — Cluster 3 (plans, scratch)
- `~/hamza-workspace/chezmoi` — Cluster 1 (dotfiles)

See `scripts/README.md` for the full 4-cluster migration map.