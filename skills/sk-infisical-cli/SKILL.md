---
name: sk-infisical-cli
description: >
  Use when the user asks to inject secrets with the Infisical CLI, troubleshoot infisical run
  (especially hot-reload 530 errors), set up CLI auth in the Analygo environment, or work with
  infisical.json, boot scripts (boot.sh, vault-run.sh), or chezmoi cache (make-cache.sh). Also use
  when the user mentions "just api" or "just refresh" failing with secret injection, the CLI
  returning 530 on secret fetch, INFISICAL_DOMAIN config, or the env.shared bootstrap file. Use
  even when the user says "secrets not loading" in a local dev context where Infisical is the vault.
---

# sk-infisical-cli — Infisical CLI: Analygo-context usage

The Infisical CLI (v0.43.x at `brew install infisical`) is the primary interface for injecting
secrets into local dev processes and Docker containers. The Analygo platform uses it in two ways:

- **`just api`** → `apps/platform/api/scripts/boot.sh` → `infisical run --recursive --watch -- bash -c 'PORT=8002 exec pnpm dev'`
- **`just refresh`** (chezmoi) → `infisical/make-cache.sh` → writes `~/.config/zsh/infisical_secrets.zsh`

## Auth paths (which creds when)

| Path | Credential | When used |
|------|-----------|-----------|
| **Personal session** | `infisical login` browser flow | chezmoi `just refresh`, ad-hoc `infisical secrets get` |
| **Service token** | `INFISICAL_SERVICE_TOKEN` (scoped JWT, 884 chars) | Docker ENTRYPOINT, `just api` boot.sh, any `infisical run --token …` |
| **SDK universal auth** | `INFISICAL_CLIENT_ID` + `INFISICAL_CLIENT_SECRET` | `@analygo/env/vault.ts` at runtime (different path — see sk-infisical-sdk-overview) |

The service token is the main one for boot scripts. It's stored in `~/.analygo/env.shared`.

## Procedures

### [ ] Step 0: Understand the domain rule

**`INFISICAL_DOMAIN` must NOT end in `/api`.**

The CLI default domain is `https://app.infisical.com/api` — it **already appends `/api`** internally.
If you pass `--domain` with a trailing `/api`, the CLI constructs double paths:
`{domain}/api/v4/secrets` → `https://infisical.analygo.co/api/api/v4/secrets` → 404/530.

| Correct | `INFISICAL_DOMAIN='https://infisical.analygo.co'` |
|---------|-----------------------------------------------------|
| Wrong | `INFISICAL_DOMAIN='https://infisical.analygo.co/api'` |
| Wrong | `INFISICAL_DOMAIN='http://localhost:8082'` (that's Hatchet dispatch) |

Set in: `~/.analygo/env.shared` (all repos source this), and each repo's `.infisical.json`
(`apps/platform/.infisical.json`, `~/hamza-workspace/chezmoi/.infisical.json`).

### [ ] Step 1: Boot the API (dev)

```bash
cd /Users/pro/Projects/analygo/apps/platform
just kill        # free port 8002
just api         # runs apps/platform/api/scripts/boot.sh
```

This runs:
```bash
infisical run \
  --token "$INFISICAL_SERVICE_TOKEN" \
  --domain "$INFISICAL_DOMAIN" \                     # https://infisical.analygo.co (no /api!)
  --env dev \
  --recursive \                                      # MANDATORY — folder-scoped secrets
  --project-config-dir "$PLATFORM_ROOT" \            # reads .infisical.json for workspaceId
  --watch \                                          # auto-restart on secret change (every 10s)
  -- bash -c 'PORT=8002 exec pnpm dev'
```

`--recursive` is MANDATORY — without it, folder-scoped secrets (under `/hatchet`, `/models`, etc.)
inject as empty strings.

### [ ] Step 2: Setup the vault tunnel (if cloud is unreachable from your network)

The health-check in `boot.sh` probes the cloud URL first. If it fails, it opens an SSH tunnel:
```bash
ssh -f -N -L 8082:10.10.0.2:8082 root@46.62.141.132
```

The tunnel is only needed if direct HTTPS to `infisical.analygo.co` fails from your network
(corporate proxy, VPN split-tunnel, etc.). After opening, the CLI uses the tunnel transparently.

### [ ] Step 3: Refresh shell secrets cache

```bash
cd /Users/pro/hamza-workspace/chezmoi
just refresh     # runs infisical/make-cache.sh
```

This writes `~/.config/zsh/infisical_secrets.zsh` (sourced by `.zshrc`). It fetches three groups:
- Model keys from `/models` (ANTHROPIC_API_KEY, OPENROUTER_API_KEY, etc.)
- Productivity secrets from `/productivity` (EVIDENCE_PG_DSN, etc.)
- Hatchet secrets from `/hatchet` (HATCHET_CLIENT_TOKEN, etc.)

### [ ] Step 4: View secrets

```bash
# All secrets in the linked project/environment
infisical secrets

# Recursive (show all folders)
infisical secrets --recursive

# Specific folders
infisical secrets --path /hatchet
infisical secrets --path /models

# Plain output (no table, one var per line)
infisical secrets --plain

# Single secret
infisical secrets get ANTHROPIC_API_KEY --path /models --plain --silent
```

## Gotchas

### `.infisical.json` vs `.infisical.yaml`

The CLI writes `.infisical.json` (JSON format), **not** `.infisical.yaml`. The config file contains:
```json
{
  "workspaceId": "6471384a-5404-4a63-9ac3-090f1264bb37",
  "defaultEnv": "dev",
  "domain": "https://infisical.analygo.co"
}
```

The `domain` field in this file must match `INFISICAL_DOMAIN` (no `/api`). If it's wrong
(e.g., `http://localhost:8082`), the CLI's hot-reload watcher uses this fallback and hits
a wrong server → `530` error.

### Hot-reload 530 error

If `just api` shows:
```
ERR [HOT RELOAD] Failed to fetch secrets ... [status-code=530]
```

Troubleshoot in order:
1. `grep INFISICAL_DOMAIN ~/.analygo/env.shared` — must NOT end in `/api`
2. `grep domain apps/platform/.infisical.json` — must be `https://infisical.analygo.co`,
   not `localhost:8082`
3. `curl -s -m 3 https://infisical.analygo.co/api/status` — vault reachable?
4. `infisical secrets get ANTHROPIC_API_KEY --env dev --path /models --plain --silent` — token valid?

### `HOME` secret warning

The warning `Infisical secret named [HOME] has been removed because it is a reserved secret name`
is harmless. Infisical injects ALL vault secrets into env, but filters out reserved env vars
that could clobber the OS. `HOME`, `PATH`, `SHELL`, etc. are filtered.

### Service token vs universal auth

The Analygo boot scripts use `--token "$INFISICAL_SERVICE_TOKEN"` (a scoped JWT). This is the
**legacy** auth method, but it still works with v0.43.x CLI and is what all current Docker
ENTRYPOINTs use. Universal auth (`--client-id`/`--client-secret`) is the newer approach but
requires changing every Dockerfile and boot script — not recommended for incremental fixes.

### `--recursive` is mandatory

Without it, `infisical run` only injects root-level secrets. Folder-scoped secrets
(`/hatchet`, `/models`, `/productivity`, `/github`, `/hyperdx`) inject as empty strings.
This is the #1 cause of "missing env var" bugs in dev.

### The two auth paths (CLI vs SDK) are independent

Fixing one doesn't fix the other. The CLI uses `INFISICAL_SERVICE_TOKEN`; the SDK uses
`INFISICAL_CLIENT_ID` + `INFISICAL_CLIENT_SECRET`. They are different credentials stored
in the same `env.shared` file but serve different code paths.

## References

- `apps/platform/api/scripts/boot.sh` — local dev boot with `--recursive --watch`
- `apps/platform/scripts/vault-run.sh` — alternative boot for standalone platform repo
- `~/hamza-workspace/chezmoi/infisical/make-cache.sh` — shell cache generator
- `~/.analygo/env.shared` — bootstrap credentials (static, chezmoi-managed as `private_dot_analygo/private_env.shared`)
- `apps/platform/.infisical.json` — workspace config for CLI
- `sk-infisical-sdk-overview` — the SDK path (@infisical/sdk v5.x, @analygo/env/vault.ts)
- `~/.pi/APPEND_SYSTEM.md` — Infisical domain rule + auth path docs