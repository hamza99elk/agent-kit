# `~/Projects/agent-kit/` — Agent Kit Factory

You are the **agent-kit factory** — maintainer of the canonical skills
repository for Pi agent context files, skill definitions, and system
prompts. NOT a machine for applying skills — you maintain the skill
definitions themselves.

Symlink fan-out is handled by `scripts/sprout-skills.sh`. No chezmoi
state files needed per-skill. See `docs/README.md` for the full
architecture.

---

## Distribution Model: `sprout-skills.sh`

All `.pi/skills/` symlinks are managed by `scripts/sprout-skills.sh`.
**Never create a raw symlink with `ln -s`.** Always run:
```bash
bash scripts/sprout-skills.sh --apply
```

### How it works

```
agent-kit/skills-templates/
├── global/          → ~/.pi/agent/skills          (dir-level symlink)
├── analygo/         → $workspace/.pi/skills/*      (per-skill symlinks)
└── hamza-workspace/ → $workspace/.pi/skills/*      (per-skill symlinks)

            ↕ scripts/sprout-skills.sh --apply
```

### Bridge to chezmoi (Cluster 1)

The only connection is:
```
chezmoi/run_onchange_after_sprout-skills.sh.tmpl
  ↳ calls agent-kit/scripts/sprout-skills.sh --apply
```

Triggered automatically by `chezmoi apply` (or `just apply` in chezmoi).

---

## Commands

**Fan-out symlinks:**
```bash
bash scripts/sprout-skills.sh --apply    # write/update all symlinks
bash scripts/sprout-skills.sh --prune    # remove broken links
bash scripts/sprout-skills.sh            # dry-run
```

**Quality:**
```bash
bash scripts/audit-skills.sh             # check all SKILL.md files
```

**Verify:**
```bash
readlink ~/.pi/agent/skills
readlink ~/Projects/analygo/packages/hatchet/.pi/skills/sk-hatchet-test-new
bash scripts/sprout-skills.sh --apply    # idempotent — safe to re-run
```

---

## Architecture

```
~/Projects/agent-kit/
├── AGENTS.md                       # ← This file
├── .pi/APPEND_SYSTEM.md            # Factory guardrails
│
├── skills-templates/               # Canonical skill definitions
│   ├── global/                     # → ~/.pi/agent/skills/
│   ├── analygo/                    # → analygo/*/.pi/skills/
│   │   ├── hatchet/
│   │   ├── ui/
│   │   ├── apps/
│   │   ├── contracts/
│   │   ├── aegis/
│   │   └── root/
│   └── hamza-workspace/            # → hamza-workspace/*/.pi/skills/
│       ├── root/
│       ├── strategy/
│       └── finance/
│
├── agents-templates/               # AGENTS.md files by workspace
├── system-templates/               # SYSTEM.md prompt replacements
└── scripts/
    ├── sprout-skills.sh            # Main fan-out engine
    ├── audit-skills.sh             # SKILL.md quality checker
    └── sync-global-skills.sh       # Legacy (deprecated)
```

---

## Skills by Group

### Global (always available via `~/.pi/agent/skills/`)

| Skill | Purpose |
|-------|---------|
| `sk-build-agents-md` | Build AGENTS.md hierarchical context files |
| `sk-build-append-system` | Build `.pi/APPEND_SYSTEM.md` guardrails |
| `sk-build-system` | Build full SYSTEM.md prompt replacement |
| `sk-fullstack-practices` | Full-stack development conventions |
| `sk-pi-extension` | Build/debug Pi coding agent extensions |
| `sk-pi-hygene` | Audit/restructure Pi context hierarchy |
| `sk-typescript-atomic-build` | TypeScript coding conventions |
| `sk-agent-kit-factory` | Maintain this repo (the skill you're reading) |
| `github-automation` | GitHub workflow automation |
| `github-issues` | GitHub issue management |
| `docs-as-code` | Documentation infrastructure |

### Analygo (per-package, loaded on demand)

| Package | Skills |
|---------|--------|
| `hatchet/` | Audtor, CLI, contract-new, conventions, dag-new, event-new, extension, pi-extensions, system, task-new, test-new |
| `ui/` | analygo-pnpm, build, layout, consumer-app-layout, consumer-feature, consumer-guide, consumer-page-layout, consumer-page-skeleton, archetypes, Storybook-testing |
| `apps/` | autumn-catalog, autumn-concepts, autumn-integrate, autumn-setup, sk-platform-nav, sk-route-consolidation |
| `contracts/` | sk-contracts-system |
| `aegis/` | openclaw |
| `root/` | qa-bug-report-retest, qa-playwright-e2e, qa-sweep, qa-test-strategy, security-specialist |

### Hamza-workspace (personal areas)

| Area | Skills |
|------|--------|
| `root/` | sk-infisical-cli, sk-infisical-sdk-overview, sk-personal-os, sk-zk-workflow, okf-open-knowledge-format |
| `strategy/` | strat-task-warrior |
| `finance/` | (add skills here) |

---

## Adding a New Skill

1. **Determine placement:** `global/`, `analygo/<pkg>/`, or `hamza-workspace/<area>/`
2. **Create dir + SKILL.md** under `skills-templates/<group>/<name>/`
3. **Fan out:** `bash scripts/sprout-skills.sh --apply`
4. **Register** in this AGENTS.md index (Skills by Group tables above)
5. **Commit:** `git add <skill> AGENTS.md && git commit -m "feat(sk-name): description"`

**No chezmoi edits needed.** Adding a skill = git commit + sprout-skills.

## Removing a Skill

1. **Verify nothing depends:** `rg -l "sk-old-skill" skills-templates/ agents-templates/`
2. **Remove source:** `rm -rf skills-templates/global/sk-old-skill`
3. **Prune broken links:** `bash scripts/sprout-skills.sh --prune`
4. **Refresh:** `bash scripts/sprout-skills.sh --apply`
5. **Remove from this AGENTS.md index**

## Layout Rules

- `skills-templates/` named with `-templates` suffix to prevent harness auto-scanning
- Some skills use **double nesting**: `sk-name/sk-name/SKILL.md` (hatchet, ui, apps, contracts)
- Others are **flat**: `sk-name/SKILL.md` (global, root, hamza)
- `sprout-skills.sh` auto-detects: if a same-named subdir exists, symlinks to it
- No YAML frontmatter in AGENTS.md (plain Markdown only)
- `sk-` prefix for skill names

## Boundaries

- ✅ **Always:** Create skills under `skills-templates/`; run `sprout-skills.sh --apply`; update this index; commit changes
- ⚠️ **Ask first:** Moving a skill between groups; deleting a skill with external references; changing distribution model
- 🚫 **Never:** Use raw `ln -s` for distribution symlinks; put secrets in skill content; create skills outside `skills-templates/`; run `chezmoi add` for a skill symlink

## Workflow

- Branch from `main`, merge via squash
- Commit messages: `type(scope): description` (e.g. `feat(sk-name): add skill for X`)
- After adding + fanning out: run `/reload` in Pi to pick up new skills