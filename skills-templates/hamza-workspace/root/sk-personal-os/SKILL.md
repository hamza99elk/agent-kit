---
name: sk-personal-os
description: >
  Use when the user asks "what tools do I use", "explain my setup", "how to
  discover this repo", "what's in hamza-workspace", "show me the CLI stack",
  "how does my system work", "find the right tool for X", or wants to understand
  the personal quantified-self infrastructure. Also use when an agent needs to
  discover what tools are available in hamza-workspace before attempting a task,
  or when the user asks generic questions about their system ("I have a tool for
  that", "there's a CLI somewhere", "check what I use for...").
  NOT for using any specific tool — those have their own skills. NOT for
  generic workspace analysis tasks. NOT for building new components.
---

# sk-personal-os — Personal OS: CLI Stack & Workspace Discovery

`hamza-workspace` (`~/hamza-workspace/`) is a personal quantified-self OS — a
collection of CLIs, engines, and data files that track nutrition, training,
finances, habits, body metrics, and knowledge. This skill explains the
ecosystem and how to discover what exists.

## Architecture

```
  ┌──────────────────────────────────────────────────┐
  │          hamza-workspace/  (monorepo root)       │
  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
  │  │ CLIs     │ │ Engines  │ │  Data / Config   │  │
  │  │ workout  │ │ TS per.  │ │  checkins/       │  │
  │  │ kcal     │ │ Lua prog.│ │  exercise/       │  │
  │  │ sprout   │ │ Drizzle  │ │  nutrition/      │  │
  │  │ habits   │ │          │ │  finances/       │  │
  │  │ hledger  │ │          │ │  db/             │  │
  │  │ zk       │ │          │ │  knowledge/      │  │
  │  │ navi     │ │          │ │  .pi/skills/     │  │
  │  └──────────┘ └──────────┘ └──────────────────┘  │
  └──────────────────────────────────────────────────┘
```

---

## CLI Stack

### Nutrition (`kcal`)
- **Binary:** `~/bin/kcal` (compiled Go binary)
- **DB:** `~/"Library/Application Support"/kcal/kcal.db` (SQLite)
- **Config copy:** `~/hamza-workspace/db/kcal.db`
- **Commands:** `entry add/list`, `entry quick`, `analytics week`, `goal set/current`, `body add/list`, `exercise add/list`, `category`, `recipe`, `config`
- **Key detail:** `kcal entry quick "<name> | <kcal> <protein> <carbs> <fat> | <category>" --date YYYY-MM-DD` is the hot-path for watcher dispatching
- **Purpose:** Track calories, macros, body weight, exercise energy estimates. Source of truth for food entries.

### Training (`workout-cli`)
- **Binary:** `~/.bun/bin/workout` (Bun script → TypeScript source at `~/hamza-workspace/workout-cli/`)
- **Storage:** `~/.workout/` — `state.json` (e1RMs, history), `profiles/default/` (templates, workouts, config)
- **Commands:** `start`, `log`, `done`, `cancel`, `status`, `summary`, `inject`, `sync`, `state`, `exercises`, `templates`, `profile`, `last`, `history`
- **Engine:** `workout-cli/src/lib/engine/` — Pure TS library for periodization, e1RM estimation, 11 progression rules
- **Purpose:** Log strength training sessions. Source of truth for sets, RIR/RPE, e1RMs. Generates workout plans via `program.ts`.

### Habits (`sprout`)
- **Binary:** `/opt/homebrew/bin/sprout`
- **DB:** `habit.db` (SQLite, location discovered via `sprout` — check `~/.config/sprout/` or just run `sprout list`)
- **Key commands:** `sprout list` (all habits + today's progress), `sprout status` (today only), `sprout log <name> <value>`, `sprout streak`, `sprout add/delete/edit`
- **Purpose:** Track daily habit check-ins. Source of truth for habit data. The watcher dispatches `[x]` lines from `habits.txt` to `sprout log`.

### Habits (legacy — `habits`)
- **Binary:** `~/.local/bin/habits` (Python, older standalone tool)
- **Data:** `~/.habits_tracker.json`
- **Status:** Legacy. The `sprout` CLI is the current tool. `habits` still works but `sprout` is preferred.

### Finances (`hledger`)
- **Binary:** `/opt/homebrew/bin/hledger`
- **Journal:** `~/hamza-workspace/finances/ledger.journal`
- **Key commands:** `hledger balance`, `hledger register`, `hledger stats`, `hledger print`
- **Purpose:** Plain-text accounting. Source of truth for all financial transactions.

### Knowledge (`zk`)
- **Binary:** `~/bin/zk` (compiled Go binary)
- **Index:** `~/.zk/notebook.db` (SQLite)
- **Root:** `~/hamza-workspace/` (the `knowledge/` subdirectory is the OKF bundle; zk indexes the whole workspace)
- **Key commands:** `zk search`, `zk new`, `zk index`, `zk list`
- **Purpose:** Full-text search, backlinks, tag filtering across all workspace markdown files.

### Task Runner (`just`)
- **Binary:** `/opt/homebrew/bin/just`
- **Recipes:** `~/hamza-workspace/justfile`
- **Key recipes:**
  - `workout-today`, `workout-inject`, `workout-sync`, `workout-status`, `workout-summary`, `workout-sync-kcal`, `workout-sync-all`
  - `kcal-today`, `kcal-week`, `kcal-goal`, `kcal-db`, `kcal-import`, `kcal-inject`, `kcal-save`
  - `habits-ls`, `habits-undone`, `habits-trends`
  - `fin-check`, `fin-sync`
  - `life-open`, `life-watcher`, `life-log`
  - `db-studio`, `db-push`, `db-seed`
  - `env-load`, `env-source`
- **Purpose:** Central dispatch. Run `just --list` to see everything available.

### Dotfiles (`chezmoi`)
- **Binary:** `/opt/homebrew/bin/chezmoi`
- **Source:** `~/hamza-workspace/chezmoi/`
- **Purpose:** Manage `~/.config/` files (zsh, nvim, kitty, ghostty, git, launchd, etc.)

### Agent (`pi`)
- **Script:** `~/bin/pi` (shell dispatcher)
- **Binary:** `~/.pi/agent/bin/pi`
- **Config:** `~/hamza-workspace/.pi/`
- **Skills:** `~/hamza-workspace/.pi/skills/` (project-local) and `~/.pi/agent/skills/` (global)
- **Purpose:** Coding agent harness. Context management, tool registration, workspace orchestration.

### Misc
- **`navi`** — `/opt/homebrew/bin/navi`, cheatsheets in `~/hamza-workspace/navi-cheats/`
- **`fzf`** — `/opt/homebrew/bin/fzf`, fuzzy finder (used by zk, navi)
- **`fd`** — `/opt/homebrew/bin/fd`, fast file search
- **`bat`** — `/opt/homebrew/bin/bat`, syntax-highlighted cat
- **`eza`** — `/opt/homebrew/bin/eza`, modern ls
- **`jq`** — `/opt/homebrew/bin/jq`, JSON processor
- **`yq`** — `/opt/homebrew/bin/yq`, YAML/JSON/TOML processor
- **`sqlite3`** — `/usr/bin/sqlite3`, SQLite CLI

---

## Workspace Discovery Procedure

When a user says something like "there's a tool for that" or "check what I use for [domain]" or asks to grasp the repo:

1. **Run `just --list`** — This is the fastest overview of all available commands.
   ```bash
   cd ~/hamza-workspace && just --list
   ```

2. **Check `AGENTS.md`** — Top-level context file with workspace structure, conventions, and cheat sheet.
   ```bash
   cat ~/hamza-workspace/AGENTS.md
   ```

3. **Scan `justfile`** — For each domain section (Workout, Nutrition, Finances, Habits, etc.), read the section header comments and recipe definitions.
   ```bash
   head -100 ~/hamza-workspace/justfile   # top sections
   grep -n "^#" ~/hamza-workspace/justfile  # all section headers
   ```

4. **Check the zk knowledge base** — For documented architecture and decisions.
   ```bash
   zk search "concept|decision|playbook" 2>/dev/null
   # Or browse knowledge/kb/playbooks/, knowledge/kb/concepts/
   ```

5. **For a specific domain**, drill into:
   - **Workout:** `~/hamza-workspace/workout-cli/README.md`, `workout --help`, `knowledge/kb/playbooks/nutrition-and-workout-system.md`
   - **Nutrition:** `kcal --help`, `knowledge/kb/playbooks/nutrition-and-workout-system.md`
   - **Knowledge:** `knowledge/kb/playbooks/zk-usage.md`, `knowledge/kb/concepts/zk.md`
   - **Finances:** `hledger --help`, `~/hamza-workspace/finances/`
   - **General:** `knowledge/kb/`, especially `playbooks/`, `concepts/`, `decisions/`

6. **Check `.pi/skills/`** — Project-local agent skills that document specific workflows.
   ```bash
   ls ~/hamza-workspace/.pi/skills/
   ```

---

## Tool Discovery by Domain

| Domain | Primary CLI | Secondary | Data location | Docs |
|--------|-------------|-----------|---------------|------|
| Nutrition | `kcal` | — | `kcal.db` | `knowledge/kb/playbooks/nutrition-and-workout-system.md` |
| Training / Workouts | `workout` | `bun run src/index.ts` | `~/.workout/`, `workout-cli/src/lib/engine/` | same, also `workout-cli/SPEC.md` |
| Habits | `sprout` | `habits` (legacy) | `habit.db` | — |
| Finances | `hledger` | — | `finances/ledger.journal` | — |
| Knowledge | `zk` | — | `knowledge/` (OKF bundle) | `knowledge/kb/playbooks/zk-usage.md` |
| Task dispatch | `just` | — | `justfile` | — |
| Dotfiles | `chezmoi` | — | `chezmoi/` | — |
| Agent harness | `pi` | — | `.pi/` | — |
| Cheatsheets | `navi` | — | `navi-cheats/` | — |

## Key Engineering Decisions

- **Training data is NOT in kcal DB.** kcal stores only the energy summary (kcal estimate, duration). Set-by-set detail lives in `~/.workout/`. See `knowledge/kb/playbooks/nutrition-and-workout-system.md` for the reasoning.
- **Two program definitions exist** — TS (`program.ts`) and Lua (`exercise/archive/3-day-full-body.lua`). They mirror each other. The TS one runs the computation; the Lua one powers the Neovim Telescope picker.
- **The watcher is one-way:** `.txt` files → CLI dispatch → DBs. There is NO reverse sync from DBs to watcher (except the explicit `reverse-sync.sh` script).
- **Secrets are in Infisical**, cached locally. Never run `infisical secrets get` directly.

## Boundaries

- When the user asks "what tool for X", answer with the correct CLI from the table above, not with "I'll write a script". The tool exists.
- When the user asks to understand the repo, use the Discovery Procedure (steps 1-6 above). Don't skip to reading arbitrary files.
- When the user says "there's a tool" but doesn't name it, check both `just --list` and the tool discovery table. Don't guess.
- When the user asks to build something for a domain that already has a tool, redirect to the existing tool first.