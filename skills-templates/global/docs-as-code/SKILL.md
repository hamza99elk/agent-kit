---
name: docs-as-code
description: >
  Implement docs-as-code workflows using Git, Markdown, static site generators (MkDocs Material,
  Docusaurus), and automated CI/CD publishing pipelines. Use when the user asks to set up or improve
  documentation infrastructure, write docs in Markdown, version-control docs alongside code, deploy
  to GitHub Pages / Vercel / Netlify, configure mkdocs.yml / docusaurus.config.ts, add search, link
  checking, or multi-version docs. Also use when reviewing PRs that change docs, setting up a docs
  site from scratch, or migrating from a wiki / Notion / Confluence to a code-based workflow. NOT
  for the "code-as-doc" pipeline-documentation generator pattern (see pipeline-doc-gen skill).
license: MIT
compatibility:
  - git
  - python >= 3.10
  - node >= 18
metadata:
  version: "1.1"
  changes:
    - "Replaced Step 1 choice table with a default (MkDocs Material) + escape hatch (Docusaurus)"
    - "Added progressive-disclosure references with conditional load triggers"
    - "Removed inline generic content (basic scaffold commands, feature lists)"
    - "Added eval assertions (expected outputs) to evals/evals.json"
---

# Docs-as-Code — Git + Markdown + Static Site CI/CD

Best practices: https://agentskills.io/skill-creation/best-practices.md

---

## Prerequisites

- **Python 3.10+** for MkDocs Material (`pip install mkdocs-material`)
- **Node 18+** for Docusaurus (if used instead of MkDocs)
- **Git** — docs live in a repo alongside code
- **CI/CD** — GitHub Actions, GitLab CI, or equivalent

## Workflow

Progress:
- [ ] Step 1: Scaffold with MkDocs Material (default) or Docusaurus (React-heavy projects)
- [ ] Step 2: Write content in Markdown
- [ ] Step 3: Configure navigation, theme, plugins
- [ ] Step 4: Set up CI/CD deployment
- [ ] Step 5: Validate (build, link-check, preview)

### Step 1: Scaffold

**Default: MkDocs Material** (Python, API/project docs, monorepo docs)

```sh
pip install mkdocs-material
mkdocs new .
```

This creates:
```
my-docs/
├── mkdocs.yml
└── docs/
    └── index.md
```

**For React-heavy or multi-version product docs**, use Docusaurus instead:

```sh
npx create-docusaurus@latest my-docs classic --typescript
cd my-docs
```

If you're unsure which generator fits, default to MkDocs Material. If your project is React-heavy or needs multi-version docs (`versioned_docs/`), see
[`references/docusaurus-guide.md`](references/docusaurus-guide.md) for Docusaurus.
For the simplest possible GitHub Pages docs with no build step (Ruby), see
[`references/just-the-docs.md`](references/just-the-docs.md).

### Step 2: Write content in Markdown

Place `.md` files under `docs/`. Use standard Markdown — both generators support:

- **Admonitions/callouts:** `!!! note "Title"\n    Body`
- **Code blocks** with line numbers and copy button (built-in)
- **Tabs:** `=== "Tab Name"` with `pymdownx.tabbed` (MkDocs) or MDX tabs (Docusaurus)
- **Mermaid diagrams:** `` ```mermaid ``
- **Search indexing** (built-in, no config needed)
- **Auto-generated tables of contents** from headings

Image paths differ between generators:
- **MkDocs:** paths are relative to `docs/` directory: `![alt](img/logo.png)` → `docs/img/logo.png`
- **Docusaurus:** images live in `static/` and use root-relative paths: `![alt](/img/logo.png)`

### Step 3: Configure navigation and theme

**MkDocs Material — `mkdocs.yml`:**

```yaml
site_name: My Documentation
site_url: https://docs.example.com
theme:
  name: material
  features:
    - navigation.tabs
    - search.highlight
    - content.tabs
    - content.code.copy
  palette:
    - scheme: default
      primary: indigo
nav:
  - Home: index.md
  - API:
    - Overview: api/overview.md
    - Reference: api/reference.md
  - Guides:
    - Authentication: guides/authentication.md
plugins:
  - search
  - git-revision-date-localized
markdown_extensions:
  - pymdownx.superfences
  - pymdownx.tabbed
  - admonition
  - toc:
      permalink: true
```

If you need Docusaurus config instead, see `references/docusaurus-guide.md`.

### Step 4: Set up CI/CD

**GitHub Actions — `.github/workflows/deploy-docs.yml`:**

```yaml
name: Deploy Docs
on:
  push:
    branches: [main]
    paths: ["docs/**", "mkdocs.yml"]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # needed for git-revision-date plugin
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.x"
      - name: Install deps
        run: pip install mkdocs-material mkdocs-git-revision-date-localized-plugin
      - name: Build
        run: mkdocs build --strict
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./site
```

If the peaceiris action fails (org pages, cross-repo deploy, custom domain), load
[`references/gh-pages-alternatives.md`](references/gh-pages-alternatives.md).

For Vercel/Netlify (Docusaurus), point to "Docusaurus" framework preset — build
command `npm run build`, output dir `build/`.

### Step 5: Validate

```sh
# MkDocs — build with --strict to fail on dead links
mkdocs build --strict

# Link checker (catches external dead links)
pip install linkchecker
linkchecker --check-extern site/

# Serve locally for preview
mkdocs serve
```

## Gotchas

- **`pymdownx.superfences` must be listed before `pymdownx.tabbed`** in
  `markdown_extensions`. Wrong order silently breaks nested content inside tabs.
- **`theme.features` differ between `mkdocs-material` and the built-in `mkdocs`
  theme.** Only `name: material` supports features like `navigation.tabs`.
  Including `features` under the built-in theme silently does nothing — no warning.
- **`mkdocs gh-deploy --force` in CI may fail** due to GitHub token permission
  scoping. Use `peaceiris/actions-gh-pages@v4` with `publish_dir: ./site` instead.
  If that fails, load `references/gh-pages-alternatives.md`.
- **Image paths in MkDocs are relative to `docs/`, not the markdown file.**
  `![alt](img/logo.png)` resolves to `docs/img/logo.png`. In Docusaurus, images
  live in `static/` and are root-relative: `![alt](/img/logo.png)`.
- **Search only indexes the `docs/` subtree.** Files outside `docs/` (e.g.,
  `README.md` at repo root) are invisible to the site search. Copy or symlink them.
- **Docusaurus versioned docs** are a Docusaurus-internal concept (`docusaurus
  docs:version`). The `versioned_docs/` directory is **not** the same as Git
  tags or branches.
- **`mkdocs gh-deploy --force` requires write access** to the repo. Use the
  peaceiris action (Step 4) which works with `GITHUB_TOKEN` scoped correctly.

## References

| File | When to load |
|------|-------------|
| [`references/gh-pages-alternatives.md`](references/gh-pages-alternatives.md) | If the peaceiris deploy (Step 4) fails, or for org pages / cross-repo / custom domain deployment |
| [`references/docusaurus-guide.md`](references/docusaurus-guide.md) | When using Docusaurus instead of MkDocs (React-heavy or multi-version projects) |
| [`references/just-the-docs.md`](references/just-the-docs.md) | When you need the simplest possible GitHub Pages docs with no build step |
| [`evals/evals.json`](evals/evals.json) | Test prompts with expected outputs for evaluating skill quality |