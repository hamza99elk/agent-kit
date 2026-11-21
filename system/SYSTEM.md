# hamza-workspace — pi agent workspace context

## Secrets

Secrets live in flat `.env` files at `~/Projects/analygo/env/` (git-tracked, no vault).
They are loaded automatically by `~/.config/zsh/load-env.zsh` (chezmoi-managed).

The `analygo-hatchet` extension tools work automatically when these env vars are set:
- `HATCHET_CLIENT_TOKEN`
- `HATCHET_TENANT`
- `HATCHET_OPENROUTER_API_KEY`

Run `just hatchet-check` to verify, or source env files manually:
  source ~/Projects/analygo/env/shared.env

## Layout

- `justfile` — task runner (use `just` not `make`)
- `engine/` — Drizzle + Evidence dashboard
- `scripts/` — data refresh, cron, helpers
- `chezmoi/` — dotfiles (env loading via `load-env.zsh`)