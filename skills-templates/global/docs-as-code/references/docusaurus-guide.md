# Docusaurus Guide

Load this when scaffolding with Docusaurus instead of MkDocs Material.

## When to use Docusaurus

- You need **multi-version documentation** (one site per API major version).
- Your project is **React-heavy** or already uses a JS/TS stack.
- You need **React/MDX components** in documentation pages.

## Scaffold

```sh
npx create-docusaurus@latest my-docs classic --typescript
cd my-docs
```

## Configuration — `docusaurus.config.ts`

```ts
export default {
  title: "My Docs",
  url: "https://docs.example.com",
  baseUrl: "/",
  favicon: "img/favicon.ico",
  themeConfig: {
    navbar: {
      items: [
        { type: "docSidebar", sidebarId: "docs", label: "Docs" },
        { href: "https://github.com/org/repo", label: "GitHub" },
      ],
    },
  },
};
```

## Multi-version docs

```sh
# Create a versioned snapshot (e.g., for v1.0)
npx docusaurus docs:version 1.0
```

This creates `versioned_docs/` and `versioned_sidebars/` directories. Each version
is a Docusaurus concept — not the same as Git tags or branches.

## CI/CD (Vercel / Netlify)

Point the framework preset to "Docusaurus": build command `npm run build`, output
dir `build/`.

## Gotchas

- **Versioned docs ≠ Git tags.** Docusaurus versioning is managed via CLI, not
  Git branches. Don't confuse them.
- **Image paths** are root-relative from `static/`: `![alt](/img/logo.png)`.
- **Search** only indexes files in the docs tree — `README.md` at the repo root
  is invisible unless copied or symlinked.