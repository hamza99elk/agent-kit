# AGENTS.md — OKF Bundle Rules for knowledge/

**This is the root knowledge source of hamza-workspace.**

It follows the **OKF v0.2 (Open Knowledge Format)** bundle specification.
Old numbered directories (`00-inbox` → `06-nutrition`) are retired — all
knowledge lives here. `checkins/` (habit/nutrition tracker) and `areas/` (life
domains) remain separate as secondary input areas.

For workspace-level rules, see `.clinerules` in the repo root.

## 7 Types (vocabulary)

Every non-reserved `.md` file under `kb/` **must** have a `type:` field in its frontmatter.
Reserved filenames (`index.md`, `log.md`, `_index.md`, `README.md`) have no frontmatter.

| Type | Directory | Purpose |
|---|---|---|
| `Inbox` | `kb/inbox/` | Raw capture — unprocessed notes, clippings, bookmarks |
| `Journal` | `kb/journal/` | Chronological entries by day |
| `Concept` | `kb/concepts/` | Emergent ideas and definitions worth keeping |
| `Primitive` | `kb/primitives/` | Reusable building blocks (snippets, patterns, configs) |
| `Decision` | `kb/decisions/` | Architecture and design decisions with context |
| `Playbook` | `kb/playbooks/` | Step-by-step procedures |
| `Project` | `kb/projects/` | Active or completed project notes |

## Frontmatter convention

```yaml
---
type: <Type>
title: "Human-readable title"
description: "One-line summary"
created: "2026-11-02"
tags:
  - tag1
  - tag2
publish: "project-name"  # optional, for scripts/publish.sh
---
```

## Rules for agents

1. **Never skip `type:`** — validate.sh checks this. Every `.md` under `kb/` (except reserved names) needs it.
2. **Prefer `kb/inbox/` for new captures** — triage/promote later, don't file directly into concepts/decisions/etc unless you're sure.
3. **Write `kb/log.md` entries** for significant changes (migrations, promotions, decisions).
4. **Run `scripts/validate.sh`** after any batch change to catch drift early.
5. **Use `scripts/capture`** for quick inbox additions from the shell.
6. **Use `scripts/publish.sh <project>`** to surface notes tagged for a project.
7. **Don't delete originals** — when promoting from inbox, copy (not move) to the target directory, then update the inbox copy's frontmatter to note the promotion.
8. **`_index.md` files** are OKF-reserved; strip their frontmatter if they had any.
9. **`knowledge/` is the canonical root** — the `03-knowledge` symlink exists only for git transition and will be removed.
10. **Don't add new numbered dirs** — use the OKF types instead.