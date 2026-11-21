---
name: sk-agent-kit-factory
description: >
  Maintain the agent-kit skills repository at ~/Projects/agent-kit/ — the
  canonical single-source-of-truth for all Pi agent context files, skill
  definitions, and system prompts. Use when the user asks to add a new skill,
  restructure skill groups, create AGENTS.md files, manage .pi/APPEND_SYSTEM.md
  guardrails, set up symlink distribution, prune stale skills, audit skill
  coverage, or sync skills across workspaces (analygo, hamza-workspace, ~/.pi/).
  NOT for using skills — only for authoring, organizing, and maintaining them.
license: MIT
metadata:
  author: hamza
  version: 1.0.0
---

# sk-agent-kit-factory — Skills Repository Maintenance

This is the factory for the `agent-kit` repository at `~/Projects/agent-kit/`.

> **Do NOT use this skill to *apply* the skills to a coding task.**
> This skill is for **authoring, organizing, and maintaining** the skill definitions
> themselves.

---

## 1. Understand the agent-kit Layout

```
~/Projects/agent-kit/
├── AGENTS.md                       # Root context — factory persona + repo map
├── .pi/
│   └── APPEND_SYSTEM.md            # Guardrails for the factory itself
│
├── skills-templates/               # Canonical skill store (named *-templates
│   ├── global/                     #   to prevent harness auto-scanning)
│   │   ├── sk-build-agents-md/     #   → symlinked to ~/.pi/agent/skills/
│   │   ├── sk-build-append-system/ #      (always available)
│   │   ├── sk-build-system/
│   │   ├── sk-fullstack-practices/
│   │   ├── sk-pi-extension/
│   │   ├── sk-pi-hygene/
│   │   ├── sk-typescript-atomic-build/
│   │   ├── sk-agent-kit-factory/   #   ← This skill
│   │   ├── github-automation/
│   │   ├── github-issues/
│   │   └── docs-as-code/
│   │
│   ├── analygo/                    # → symlinked into analygo .pi/skills/
│   │   ├── hatchet/                #   (per-project, loaded on demand)
│   │   ├── ui/
│   │   ├── contracts/
│   │   ├── aegis/
│   │   └── root/
│   │
│   └── hamza-workspace/            # → symlinked into hamza-workspace .pi/skills/
│       ├── root/
│       ├── strategy/
│       └── finance/
│
├── agents-templates/               # AGENTS.md context files by workspace
├── system-templates/               # SYSTEM.md prompt replacements
└── justfile                        # Task runner
```

### Distribution model

Skills are **authored in agent-kit** and **distributed outward** via symlinks:

| Target | Source in agent-kit | Mechanism |
|---|---|---|
| `~/.pi/agent/skills/*` | `skills-templates/global/*` | `~/.pi/agent/skills` → `agent-kit/skills-templates/global` symlink |
| `analgo/*/.pi/skills/*` | `skills-templates/analygo/*` | Per-project symlink setup |
| `hamza-workspace/*/.pi/skills/*` | `skills-templates/hamza-workspace/*` | `hamza-workspace/agent-kit` → `Projects/agent-kit` root symlink |

### Key insight

`~/.pi/agent/skills` is a **symlink** to `~/Projects/agent-kit/skills-templates/global`. The source directories ARE the distributed skills. No inner symlinks needed — it's directory-level symlink all the way down.

---

## 2. Know the Skill Anatomy

Every skill directory must have:

```
sk-my-skill/
├── SKILL.md           # Required — the skill definition
├── references/        # Optional — supporting docs
├── assets/            # Optional — templates, images
├── scripts/           # Optional — automation
└── evals/             # Optional — evaluation cases
```

### SKILL.md frontmatter (required fields)

```yaml
---
name: sk-my-skill
description: >
  One-paragraph description that triggers the skill. Be specific about WHEN
  to use this skill (trigger conditions) and WHEN NOT to use it.
license: MIT
metadata:
  author: <user or team>
  version: 1.0.0
---
```

### Best practices (from agentskills.io)

- **Short descriptions** lead to more precise skill activation
- **No dependencies** unless specified in `compatibility:` block
- **Include examples** of good and bad output
- **Reference other skills** by name when they are related
- **Use plain Markdown** — no special syntax required
- **Trigger precision** matters: list both "use when" and "NOT for" conditions

---

## 3. Add a New Skill

### Step 1: Determine placement

| Skill scope | Directory | Distribution path |
|---|---|---|
| **Global** (always available to Pi) | `skills-templates/global/` | `~/.pi/agent/skills/<name>` (already symlinked) |
| **Analygo project** (per-package) | `skills-templates/analygo/<pkg>/` | `analygo/<pkg>/.pi/skills/<name>` |
| **Hamza workspace** (personal) | `skills-templates/hamza-workspace/<area>/` | `hamza-workspace/<area>/.pi/skills/<name>` |

### Step 2: Create the skill directory and SKILL.md

```bash
mkdir -p skills-templates/global/sk-my-new-skill/{references,assets}
```

Then write `SKILL.md` with:
1. YAML frontmatter (name, description, license, metadata)
2. Title + one-line overview
3. Trigger conditions (use-when / not-for)
4. Prerequisites
5. Body — structured steps, code examples, good vs. bad patterns
6. Related skills section

### Step 3: Register in the distribution manifest

Update the `AGENTS.md` repo-global skill index (Section: Skills by Group) to
include the new skill.

### Step 4: No symlink needed for global

If it's a global skill, `~/.pi/agent/skills` already points to `skills-templates/global/`. The new dir just needs to exist as a real directory there.

---

## 4. Remove a Skill

### Step 1: Verify nothing depends on it

```bash
rg -l "sk-my-old-skill" skills-templates/
rg -l "sk-my-old-skill" agents-templates/
```

### Step 2: Remove source

```bash
rm -rf skills-templates/global/sk-my-old-skill
```

### Step 3: Update distribution manifest

Remove from `AGENTS.md` skill index.

---

## 5. Restructure Skills (Grouping by Consumer)

Skills grouped by **consumer**, not source:

| Group | Consumer | Loaded when |
|---|---|---|
| `global/` | `~/.pi/agent/skills/` | Every Pi session |
| `analygo/` | Per-package `.pi/skills/` | When Pi opens that package |
| `hamza-workspace/` | WS-area `.pi/skills/` | When Pi opens that area |

---

## 6. Audit Skills

```bash
bash scripts/audit-skills.sh
```

Checks:
- ✅ Frontmatter has required fields (name, description, license, metadata)
- ✅ File is named `SKILL.md` (capital S)
- ✅ `~/.pi/agent/skills` symlink points to `skills-templates/global/`

---

## 7. Authoring Workflow

```mermaid
flowchart TD
    A[Determine scope] --> B[Create dir + SKILL.md]
    B --> C[Register in AGENTS.md index]
    C --> D[Verify ~/.pi/agent/skills symlink exists]
    D --> E[/reload in Pi]
    E --> F[Verify: bash scripts/audit-skills.sh]
```

---

## 8. Related Skills

- **sk-build-agents-md** — Creating AGENTS.md context files
- **sk-build-append-system** — Creating `.pi/APPEND_SYSTEM.md` guardrails
- **sk-build-system** — Creating SYSTEM.md prompt replacements
- **sk-pi-hygene** — Auditing/restructuring context hierarchy

---

## References

- `https://agentskills.io/skill-creation/best-practices.md` — Official best practices
- `~/.pi/agent/docs/configuration.md` — Pi configuration docs