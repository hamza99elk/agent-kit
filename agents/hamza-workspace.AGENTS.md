# ── hamza-workspace — AI Agent Rules ──────────────────────────────────────
#
# This file informs AI coding agents (Cline, Claude Code, Pi) about the
# workspace structure, conventions, and tooling.
#
# Merged from .clinerules (now deleted) into Pi's AGENTS.md hierarchy.

## Workspace structure

- `strategy/`                  — Life domains as first-class: VISION, GOALS, AREAS (business, finance, health, etc.)
- `knowledge/`                 — Root knowledge source (OKF v0.2 bundle) — inbox, journal, concepts, decisions, playbooks, projects
- `plans/`                     — Active projects / quarterly plans
- `justfile`                   — Task runner (use `just` not `make`)
- `engine/`                    — Personal quantified-self engine (Drizzle, Evidence)
- `scripts/`                   — Shell scripts for data refresh, seeding, cron helpers
- `chezmoi/`                   — Dotfiles managed by chezmoi
- `checkins/`                  — Daily habit/nutrition tracker (symlink to ~/Documents/hamza-productivity/logs)
- `inbox/`                     — General catch-all inbox
- `archive/`                   — Cold storage (single dir)
- `nutrition/`                 — Food + workout data files
- `db/`                        — SQLite DB + Drizzle migrations
- `db/kcal.db`                 — kcal-cli SQLite DB (calorie/macro tracking via Go+SQLite CLI)
- `finances/`                  — Ledger + finance data
- `exercise/`                  — Workout templates/logs
- `habits/`                    — Habit tracking
- `dashboard/`                 — Evidence/streamlit dashboards
- `nvim-life-logs/`            — Neovim session logs
- `tui/`                       — Terminal UI tools
- `docs/`                      — Misc docs / guides
- `.pi/`                       — Pi coding-agent workspace config
- `.zk/`                       — Zettelkasten config

## Critical: Secrets sourcing

Secrets live in Infisical vault (project: secret-management). They are cached locally to
`~/.config/zsh/infisical_secrets.zsh` by `infisical/make-cache.sh`.

**Never run `infisical secrets get` directly in agent commands.** Use instead:

```bash
source ~/.config/zsh/infisical_secrets.zsh
```

Or to print env vars for a subprocess:

```bash
eval "$(just env)"
```

## Commands cheat sheet

| Task                    | Command                                |
|-------------------------|----------------------------------------|
| Fetch fresh secrets     | `just refresh`                         |
| Source secrets          | `source ~/.config/zsh/infisical_secrets.zsh` |
| Open Drizzle Studio     | `just db-studio`                       |
| Push DB schema          | `just db-push`                         |
| Boot Evidence dashboard | `just evidence`                        |
| Tail today's checkin    | `just checkin-today`                    |
| Open checkins dir       | `just checkin-dir`                      |
| Today's kcal summary    | `just kcal-today`                       |
| Weekly kcal analytics   | `just kcal-week`                        |
| Show kcal goal          | `just kcal-goal`                        |
| Re-import foods to kcal | `just kcal-import`                      |
| Inject today's meals     | `just kcal-inject`                      |
| Save food lines          | `kcal-save` (pipe checkin lines to it)   |
| Re-index ZK             | `just zk-index`                         |

## Conventions

- Use single-quote strings in shell scripts when possible
- Keep personal secrets out of git (chezmoi ignores them via `.chezmoiignore`)
- Log daily tracking in `checkins/YYYY-MM-DD.md` (habit/nutrition tracker)
- Knowledge notes go in `knowledge/kb/` with valid OKF `type:` frontmatter
- Life area docs go in `strategy/areas/<domain>/`
- Strategic files (VISION, GOALS) live in `strategy/`