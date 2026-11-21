# Pi instruction file refinement guide

Load this reference when the user has a working Pi instruction file (`APPEND_SYSTEM.md`
or `SYSTEM.md`) but Pi makes mistakes on specific tasks and needs more detail added.

## When to refine

The best instruction files grow through iteration, not upfront planning. Add detail when
Pi makes mistakes — not preemptively.

## What to add per mistake

| Pi mistake | Add to instruction file |
|---|---|
| Wrong file modified | Expand Boundaries section |
| Wrong command used | Add exact command with flags to Commands |
| Incorrect code style | Add a code example showing the right pattern |
| Missed test | Add "run tests before commits" to boundaries |
| Wrong directory | Add exact paths with purpose to File Structure |
| Wrong tool selected | Add a tool-preference instruction to Commands |

## Example — growing an instruction file

Start minimal in `.pi/APPEND_SYSTEM.md`:

```markdown
You are an expert test engineer for this project.

## Commands
- **Test:** `npm test`

## Boundaries
- ✅ Write to `tests/`
- 🚫 Never modify `src/`
```

After Pi writes a test that passes but misses edge cases:

```markdown
## Commands
- **Test:** `npm test` (runs Jest, must pass)
- **Coverage:** `npx jest --coverage` (verify branch coverage)

## Boundaries
- ✅ Write to `tests/`
- ✅ Cover edge cases: empty state, error state, loading state
- 🚫 Never modify `src/`
- 🚫 Never remove a failing test — ask first
```

## Principles

- **Commands early** — put executable commands in an early section.
- **Code examples over explanations** — one snippet showing your style beats three paragraphs
  describing it.
- **Three-tier boundaries** — always-do, ask-first, never-do.
- **Cover six core areas:** commands, testing, project structure, code style, git workflow,
  boundaries.
- **No frontmatter** — Pi instruction files are plain Markdown.

## Pi-specific notes

- `APPEND_SYSTEM.md` **adds** to the existing system prompt — use this for project rules.
- `SYSTEM.md` **replaces** the entire system prompt — use only when you need full control.
- `.pi/` files take precedence over `~/.pi/agent/` files of the same name.
- Files with the same name are **not** combined — the project-level one wins entirely.
- Run `/reload` in Pi after changing any instruction file.

## Common locations

| Intent | File | Path |
|---|---|---|
| Per-project rules | `APPEND_SYSTEM.md` | `repo-root/.pi/APPEND_SYSTEM.md` |
| User-wide rules | `APPEND_SYSTEM.md` | `~/.pi/agent/APPEND_SYSTEM.md` |
| Full system prompt override | `SYSTEM.md` | `.pi/SYSTEM.md` |

---

*Source: ~/.pi/agent/docs/pi-agent-config.md*