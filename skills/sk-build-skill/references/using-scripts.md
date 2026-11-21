# Using scripts in skills

Load this reference when the skill needs bundled executables for parsing, validation, transformation, or other repeated mechanical work.

## Self-contained script patterns

### Python (PEP 723)

```python
# /// script
# dependencies = [ "requests>=2.31" ]
# ///
import requests
```

Run: `uv run scripts/script.py`

### TypeScript (Deno)

```typescript
#!/usr/bin/env -S deno run
import * as cheerio from "npm:cheerio@1.0.0";
```

Run: `deno run scripts/script.ts`

### TypeScript (Bun)

```typescript
#!/usr/bin/env bun
import * as cheerio from "cheerio@1.0.0";
```

Run: `bun run scripts/script.ts`

## Agentic script design

- **No interactive prompts** — agent can't respond to TTY. Accept input via flags, env vars, or stdin.
- **`--help` output** — primary way the agent learns the interface. Include brief description, flags, examples.
- **Helpful errors** — say what went wrong, what was expected, what to try.
- **Structured output** — JSON to stdout, diagnostics to stderr.
- **Idempotent** — "create if not exists" over "create and fail on duplicate".
- **`--dry-run`** — for destructive ops, let the agent preview.
- **Meaningful exit codes** — document them in `--help`.

---

*Full guide: https://agentskills.io/skill-creation/using-scripts.md*