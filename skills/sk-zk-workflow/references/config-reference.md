# .zk/config.toml Quick Reference

Full docs: https://zk-org.github.io/zk/reference/config/

## Key sections

| Section | Purpose |
|---|---|
| `[note]` | Default filename, template, extension, ID charset/length |
| `[extra]` | Custom variables accessible in templates as `{{extra.<key>}}` |
| `[group."<name>"]` | Per-directory overrides (e.g., daily notes get date-based filenames) |
| `[format.markdown]` | Link format (wiki vs markdown), hashtags, colon-tags |
| `[lsp.diagnostics]` | Diagnostic levels: dead-link, self-link, missing-backlink |
| `[lsp.completion]` | Completion pop-up customization |
| `[filter]` | Named filters (e.g., `recents = "--sort created- --created-after 'last two weeks'"`) |
| `[alias]` | Shell-based command aliases (e.g., `ls = "zk list $@"`) |

## Current excludes

Set in `[note]` section:
```toml
exclude = [
    ".*/**",
    "**/plans/*",
    "**/node_modules/**",
    "chezmoi/**",
    "checkins/**",
    "inbox/**",
    ".pi/**",
    "env/**",
    "scripts/**",
    "04-archive/**",
    "knowledge/kb/archive/**",
]
```

## LSP diagnostics configured

```toml
[lsp.diagnostics]
dead-link = "error"
```

Dead links (`[[wikilink]]` pointing to non-existent notes) are flagged as errors by the Neovim LSP client.