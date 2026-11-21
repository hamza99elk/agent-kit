# agent-kit — ARCHIVED

This repo has been **archived**. The agent-kit factory approach (central skill authoring
+
symlink distribution) has been reversed. All skills now live as **hard copies** in their
respective target locations:

| Location | Contents |
|---|---|
| `~/.pi/agent/skills/*` | Global skills (11) — hard copies |
| `~/Projects/analygo/.pi/skills/*` | Analygo root-level skills (7) — hard copies |
| `~/Projects/analygo/packages/hatchet/.pi/skills/*` | Hatchet skills (11) — hard copies |
| `~/Projects/analygo/packages/ui/.pi/skills/*` | UI skills (10) — hard copies |
| `~/Projects/analygo/packages/contracts/.pi/skills/*` | Contracts skills (1) — hard copy |
| `~/Projects/analygo/packages/aegis/.pi/skills/*` | Aegis skills (1) — hard copy |
| `~/Projects/analygo/apps/.pi/skills/*` | Apps skills (4) — hard copies |
| `~/hamza-workspace/.pi/skills/*` | Hamza-workspace root skills (5) — hard copies |
| `~/hamza-workspace/strategy/.pi/skills/*` | Strategy skills (1) — hard copy |

## What's in this archive

- `skills-templates/` — the canonical source definitions, now snapshotted into targets
- `agents-templates/` — `.AGENTS.md` templates (never deployed — some target dirs don't exist)
- `system-templates/SYSTEM.md` — hamza-workspace system prompt (never deployed)
- `scripts/sprout-skills.sh` + `scripts/audit-skills.sh` — distribution scripts (obsolete)
- `AGENTS.md` — factory persona (obsolete)
- `.pi/APPEND_SYSTEM.md` — factory guardrails (obsolete)

The `archive-2025-04` branch preserves the full git history for reference.
For any skill changes, edit the hard copies directly at their target locations.