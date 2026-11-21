---
name: sk-zk-workflow
description: >
  Use when the user says "add this" with a GitHub URL to install a tool, "capture this thought",
  "promote this from inbox", "re-index zk", "log a change", "check OKF compliance", or wants to
  capture, search, link notes, or maintain the knowledge/ OKF bundle in hamza-workspace. Also use
  when the user mentions "zk", "inbox", "knowledge bundle", "OKF", "kb/log", "validate.sh",
  "notebook.db", "re-index", or "promote note". NOT for general Markdown editing rules — those
  come from the OKF skill.
---

# sk-zk-workflow — Read, search, capture, promote, and maintain the zk notebook

The workspace root (`~/hamza-workspace/`) is a zk notebook. All zk commands run from there.

---

## Prerequisites

- `zk` installed (via Homebrew)
- `.zk/config.toml` at workspace root with excludes set
- `ZK_NOTEBOOK_DIR` can be set to `~/hamza-workspace` for convenience
- **8 template groups** defined (see `.zk/config.toml` and `sk-zk-template-agent` skill)
- `journal/` symlinked to `knowledge/kb/journal/`

## Workflow

Progress:
- [ ] Step 1: Capture — get the thought into the inbox
- [ ] Step 2: Re-index (if files were added outside zk)
- [ ] Step 3: Search / retrieve as needed
- [ ] Step 4: Promote (when a capture proves worth keeping)
- [ ] Step 5: Validate OKF compliance

### Step details

#### 1. Capture (four patterns)

| Situation | Command |
|---|---|
| Daily journal | `cd ~/hamza-workspace && zk j` or `zk daily` |
| One-liner thought (inbox) | `cd ~/hamza-workspace && zk new knowledge/kb/inbox --title "the thought" --no-edit` |
| New concept (stabilized) | `cd ~/hamza-workspace && zk new knowledge/kb/concepts --title "Idea Name"` |
| New playbook | `cd ~/hamza-workspace && zk new knowledge/kb/playbooks --title "Procedure"` |
| New decision | `cd ~/hamza-workspace && zk new knowledge/kb/decisions --title "Choice"` |
| With a URL | `cd ~/hamza-workspace && zk new knowledge/kb/inbox --title "article" --extra url="https://..." --no-edit` |
| Multi-line or interactive | `cd ~/hamza-workspace && bash knowledge/scripts/capture` (reads stdin or prompts) |
| Tool install (like jrnl/timewarrior/nb-cli/zk) | `brew install <tool>` then write a brief concept note: `cd ~/hamza-workspace && zk new knowledge/kb/concepts --title "<tool> — what it does" --no-edit` |

After a tool install, also log the version:
```bash
cd ~/hamza-workspace
echo "- **$(brew info <tool> 2>/dev/null | head -1)** — installed via \`brew install\`" >> knowledge/.zk-install-log.md
```

#### 2. Re-index

After adding files outside zk (e.g., git clone, `mv`, `cp`, editor writes), rebuild the index:

```bash
cd ~/hamza-workspace && zk index
```

Check for YAML parsing warnings — those mean frontmatter issues (malformed YAML in some `.md` file). Update excludes in `.zk/config.toml` if whole directories should be skipped.

#### 3. Search & retrieve

```bash
cd ~/hamza-workspace

zk list --limit 10                          # recent notes
zk list --tag <tag>                         # by tag
zk list --match "<text>"                    # text search
zk list --tag <tag> --exclude "inbox/*"     # canonical docs only
zk list --link-to "<title>"                 # backlinks
zk list --linked-by "<title>"               # outbound links
zk tag list                                 # all tags
zk tag list --sort count                    # most-used tags
```

For browsing, use `zk edit --interactive` (opens fuzzy picker → editor).

#### 4. Promote from inbox

When a capture proves worth keeping:

1. **Copy** the file (do NOT move) to the correct directory:
   ```bash
   cp knowledge/kb/inbox/<file> knowledge/kb/concepts/<file>
   ```
2. Add or fix the `type:` frontmatter (one of: `Inbox`, `Concept`, `Primitive`, `Decision`, `Playbook`, `Project`, `Journal`)
3. Add relevant `tags:`
4. **Append a log entry** to `knowledge/kb/log.md`:
   ```markdown
   ## YYYY-MM-DD — Promoted <title>

   - `<source>` → `knowledge/kb/<dir>/<file>` — new `<Type>` note
   ```
5. Add `promoted-to: <relative-path>` to the inbox copy's frontmatter so it's traceable

#### 5. Validate OKF compliance

```bash
cd ~/hamza-workspace/knowledge && bash scripts/validate.sh
```

Fixes any `type:` violations. Reserved filenames (`index.md`, `log.md`, `README.md`) are exempt.

## Gotchas

- **`zk new` without `--no-edit`** opens `$EDITOR` (nvim). In non-interactive contexts (scripts, agent), always add `--no-edit` or the command hangs.
- **`zk list` shows inbox notes too** by default. Use `--exclude "inbox/*"` for canonical-only queries.
- **YAML parsing warnings** on `zk index` mean some `.md` file has malformed frontmatter. Run `zk index 2>&1 | grep warning` to find them. Either fix the frontmatter or add the file's directory to `.zk/config.toml` excludes.
- **Don't move files when promoting** — copy and annotate. The original capture stays in inbox with a `promoted-to:` trail.
- **`zk` globs are relative to notebook root** (`~/hamza-workspace/`). So `knowledge/inbox/` in a glob must be `knowledge/inbox/**`, not just `inbox/**`.
- **`zk index` is fast** (~seconds for 600+ notes). No reason to avoid it.