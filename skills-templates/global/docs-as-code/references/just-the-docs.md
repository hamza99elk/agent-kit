# Just the Docs

Load this when you need the simplest possible GitHub Pages documentation with no
build step.

## When to use

- Minimal docs site where you just want Markdown → GitHub Pages.
- No Python, no Node, no build pipeline needed.
- Ruby-based (Jekyll theme), works natively with GitHub Pages.

## Setup

```
docs/
├── _config.yml     # theme: just-the-docs
├── index.md
└── guides/
    └── getting-started.md
```

## GitHub Pages

Push to `main` and enable GitHub Pages in repo settings → "Deploy from branch"
→ `main` → `/docs`. No CI/workflow needed.

## Limitations

- No built-in search indexing plugins (browser-level search only).
- No multi-version support.
- No Mermaid diagram support without Jekyll plugins.
- No tabs/admonitions beyond basic Markdown.