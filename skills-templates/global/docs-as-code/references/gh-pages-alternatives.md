# GitHub Pages deployment alternatives

Load this when the standard `peaceiris/actions-gh-pages` deploy doesn't work.

## Peaceiris action (standard, recommended)

```yaml
- uses: peaceiris/actions-gh-pages@v4
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./site
```

Works for: user repos (`username.github.io`), org repos, project pages.

## Org pages with custom domain

When deploying to `https://org.github.io/` (not `https://org.github.io/repo/`):

```yaml
- uses: peaceiris/actions-gh-pages@v4
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./site
    destination_dir: docs   # optional: subdirectory within the org pages repo
```

The org pages repo must be `org.github.io` and the action must target that repo via `external_repository`.

## Cross-repo deploy

Deploy from `org/docs-repo` to `org/org.github.io`:

```yaml
- uses: peaceiris/actions-gh-pages@v4
  with:
    external_repository: org/org.github.io
    github_token: ${{ secrets.GH_PAGES_TOKEN }}  # need a PAT, not GITHUB_TOKEN
    publish_dir: ./site
```

**Gotcha:** GITHUB_TOKEN cannot write to another repo. You need a personal access token with `public_repo` scope, stored in secrets.

## MkDocs gh-deploy (fallback)

Use when the peaceiris action fails for reasons you can't diagnose:

```yaml
- name: Deploy
  run: |
    git config user.name github-actions
    git config user.email actions@github.com
    mkdocs gh-deploy --force
```

Requires the `mkdocs-material` pip package to be installed. Does NOT require additional tokens (uses the deploy key from `actions/checkout`).

## Vercel / Netlify

Better option for Docusaurus:
- Vercel: framework preset = "Docusaurus", build = `npm run build`, output = `build/`
- Netlify: `npx docusaurus build`, publish = `build/`

## Manual Pages

For repos that can't use Actions:

```sh
mkdocs build --strict
# Copy ./site/ contents to a gh-pages branch
git checkout --orphan gh-pages
rm -rf *
cp -r site/* .
git add . && git commit -m "deploy docs"
git push origin gh-pages --force
```