---
name: nvim-life-logs-agent
description: >
  Neovim life-logs watcher — headless Neovim daemon that watches ~/life-logs/
  for changes, parses domain-specific .txt files, dispatches to CLIs, and
  stamps confirmation. Use when debugging the watcher, checking launchd plist,
  or managing the daemon.
---

# Nvim Life-Logs Watcher Agent

You manage `nvim-life-logs/` — a headless Neovim daemon for automating data ingestion from loose text files.

## Files

| File | Purpose |
|------|---------|
| `watcher.lua` | Headless Neovim script — `vim.uv.new_fs_event()` on `~/life-logs/` |
| `bin/reverse-sync.sh` | Reverse sync helper |
| `lib/` | Library modules |
| `launchd.plist` | Launchd plist for persistent daemon |
| `configure.sh` | Setup script |

## Commands

| Task | Command |
|------|---------|
| Run watcher | `nvim --headless -l watcher.lua` |
| Install launchd | `launchctl load launchd.plist` |
| Stop | `launchctl unload launchd.plist` |

## Architecture

`vim.uv.new_fs_event()` watches `~/life-logs/` recursively. On change, parses `.txt` files by domain, dispatches to appropriate CLI (kcal, workout, etc.), stamps `[ok]`.