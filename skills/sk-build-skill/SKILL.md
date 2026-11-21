---
name: sk-build-skill
description: >
  Build a production-quality Agent Skills skill from scratch per agentskills.io. Use when the user asks to
  build, create, author, or scaffold an agent skill, or when they mention SKILL.md, agentskills.io, or
  packaging domain know-how into a reusable skill format. Covers the full lifecycle: capture intent,
  scope + interview, write draft, create test prompts, run eval viewer for human review, iterate.
  Does NOT cover description optimization (trigger evals) — see references/ for that.
---

# sk-build-skill — Agent Skills Factory

Spec: https://agentskills.io/specification.md
Best practices: https://agentskills.io/skill-creation/best-practices.md

---

## 1. Capture intent first

Understand what the user actually wants before writing anything. Ask:

1. **What should the skill enable the agent to do?** (Specific behavior, not "be better")
2. **When should it trigger?** (User phrases, contexts, adjacent domains where it's useful but not obvious)
3. **What's the expected output format?**
4. **Do they want test cases?** Skills with objectively verifiable outputs (file transforms, code gen, data extraction) benefit from evals. Subjective outputs (writing style, design) often don't.

Extract answers from conversation history if the user already demonstrated the workflow. Confirm with the user before proceeding.

## 2. Discover & avoid duplicates

Scan `.pi/skills/` then `~/.pi/agent/skills/` for name **and** capability overlap.
- Exact name match → report path + summary, stop.
- Same capability under different name → suggest merging or distinct scope. Never duplicate silently.

## 3. Interview & scope

Ask proactively about: edge cases, input/output formats, example files, success criteria, dependencies. Wait to write test prompts until this is ironed out.

| Good | Too narrow | Too broad |
|---|---|---|
| repeatable workflow agent gets wrong | trivial command model handles alone | unrelated domains crammed together |
| domain knowledge agent lacks (API, conventions) | one-off lookup | reads like a book chapter |
| fragile multi-step with validation gates | generic knowledge model already knows | |

Frame the description with **user intent**: "Use this skill when…" Lead with trigger contexts, including adjacent domains where it helps but the user might not name it. **Err pushy over narrow** — models undertrigger skills. All "when to use" info goes in the description, not the body.

## 4. Create the directory

Project-local: `.pi/skills/<name>/`
Global: `~/.pi/agent/skills/<name>/`

```
├── SKILL.md              # Required
├── scripts/              # Optional: tested, self-contained executables
├── references/           # Optional: focused reference docs, loaded on demand
├── assets/               # Optional: templates, schemas
└── evals/                # Optional: test cases (evals.json) + input files
```

Name: lowercase alphanumeric + hyphens only, matches parent dir.

## 5. Write SKILL.md

### Frontmatter

```yaml
name: <kebab-case>          # matches dir
description: >              # ≤1024 chars. imperative, trigger-oriented. ALL trigger context here.
license:                     # optional
compatibility:               # optional: env requirements
metadata:                    # optional: key-value
```

### Body — choose sections that fit

**Gotchas** — highest-value section. Concrete corrections the agent *will* get wrong without being told. Source from real corrections. Update iteratively.

**Procedures** — teach *how*, not just *what*. Prefer imperative form. Use `[ ] Step N` checklists for multi-step, plan-validate-execute for destructive ops, validation loops.

**Define output formats** — provide a template. Agents pattern-match better against concrete structures than prose descriptions.

**Examples** — show both good and bad where helpful. Format as Input → Output pairs.

**Explain the why** — use theory of mind. Instead of heavy "ALWAYS/NEVER MUST" rules, explain *why* something matters. Models follow instructions more reliably when they understand the purpose.

**Defaults, not menus** — pick one approach. Mention alternatives briefly as escape hatches.

**Progressive disclosure** — keep SKILL.md ≤500 lines. Move detail to `references/`. Organize by variant when a skill covers multiple domains (e.g., `references/aws.md`, `references/gcp.md`). Tell the agent *when* to load each reference: "If X fails, read references/y.md". For large reference files (>300 lines), include a table of contents.

**Leave out** — generic knowledge model already knows, exhaustive edge-case catalogues, single-task-specific instructions.

## 6. Bundle scripts (when needed)

For repeated mechanical work that the agent would reinvent each run:

- Self-contained, inline dependencies (PEP 723 for Python, `npm:` for Deno, `bundler/inline` for Ruby)
- `--help` with flags + examples
- Helpful error messages: what went wrong, what was expected, what to try
- Structured output (JSON) to stdout, diagnostics to stderr
- Idempotent where possible; `--dry-run` for destructive ops
- Meaningful exit codes

See `references/using-scripts.md` for patterns.

## 7. Create test prompts & run eval viewer

Save test cases to `evals/evals.json`. Start with 2-3 realistic prompts — the kind of thing a real user would actually type. Don't write assertions yet. Share them with the user and confirm before running.

After running, **generate the eval viewer** before analyzing results yourself — get outputs in front of the human ASAP:

```bash
python -m eval-viewer.generate_review.py <workspace>/iteration-N --skill-name "<name>"
```

Or for headless: `--static <output_path>`.

For the full eval loop (with-skill + baseline runs, grading, aggregation, review, iterate), see `references/evaluating-skills.md`.

## 8. Validate

Manual checks:
- Name: lowercase + hyphens only, no consecutive hyphens, doesn't start/end with `-`
- Parent dir name matches `name`
- Description ≤1024 chars, imperative, user-intent focused
- All "when to use" info in description, not body
- No heavy "ALWAYS/NEVER MUST" — explain the why instead

## 9. Report

Full path, one-line summary, key sections included (step-by-step, gotchas, scripts, evals, references).

---

## Templates

- `assets/templates/skill-sketch.md` — quick outline template
- `assets/templates/skill-complete.md` — full SKILL.md

## References

- `references/evaluating-skills.md` — full eval loop: spawn runs, grade, aggregate, review, iterate
- `references/using-scripts.md` — script design patterns for agentic use
- `references/best-practices.md` — deep best-practices reference