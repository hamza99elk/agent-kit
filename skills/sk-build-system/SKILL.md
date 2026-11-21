---
name: sk-build-system
description: >
  Build a production-quality .pi/SYSTEM.md file — Pi's full system prompt replacement.
  Unlike AGENTS.md (hierarchical, directory-walking, merges) and APPEND_SYSTEM.md
  (additive guardrails on top of Pi's built-in prompt), SYSTEM.md completely replaces
  Pi's default system prompt. This strips Pi of its built-in coding tools (read, write,
  edit, bash). Use this skill ONLY when the user explicitly asks for a custom non-coding
  agent, a specialized persona that doesn't need code manipulation, or when they say
  "I want to replace Pi's system prompt entirely". Do NOT use this skill for standard
  project conventions, code style, or behavioral guardrails — those belong in AGENTS.md
  (see sk-build-agents-md) or APPEND_SYSTEM.md (see sk-build-append-system). This skill
  is for advanced use cases only: custom chat agents, domain-specific Q&A bots, research
  assistants, or any scenario where Pi's built-in coding capabilities are unwanted.
---

# sk-build-system — Full System Prompt Replacement (SYSTEM.md)

`.pi/SYSTEM.md` completely replaces Pi's default system prompt. This is the most
powerful — and most dangerous — instruction file. When SYSTEM.md exists, Pi loses
its built-in coding persona, its knowledge of its own tools (read, write, edit, bash),
and all default behavior. You are starting from a blank slate.

Only use this for **custom non-coding agents** where Pi's built-in toolset is
unwanted or actively harmful.

---

## 1. Understand when SYSTEM.md is appropriate

| Mechanism | Composition | Trust needed? | Effect on Pi |
|---|---|---|---|
| **`AGENTS.md`** | Merges all files found along directory walk | No | Adds context, keeps all Pi capabilities |
| **`.pi/APPEND_SYSTEM.md`** | Replaces global APPEND_SYSTEM.md | Yes | Adds instructions, keeps all Pi capabilities |
| **`.pi/SYSTEM.md`** | Replaces Pi's core prompt entirely | Yes | **Strips all Pi capabilities** — you must redefine everything |

### When to use SYSTEM.md (rare)

- ✅ Building a custom non-coding agent (e.g., a research assistant that only reads docs)
- ✅ A domain-specific Q&A bot that should never touch files
- ✅ A security-focused agent that should never run bash or edit files
- ✅ A customer-facing chat persona with no coding capabilities
- ✅ When the user explicitly says "replace the system prompt" or "I don't want Pi's tools"

### When NOT to use SYSTEM.md (almost always)

- ❌ Standard project conventions or code style (use APPEND_SYSTEM.md)
- ❌ Per-directory architecture context (use AGENTS.md)
- ❌ Behavioral guardrails or boundaries (use APPEND_SYSTEM.md)
- ❌ Adding commands or test patterns (use AGENTS.md or APPEND_SYSTEM.md)
- ❌ Any project where Pi needs to read, write, or edit files

**Default recommendation: NEVER use SYSTEM.md unless you're certain.**
When in doubt, ask the user. 9 times out of 10, they want APPEND_SYSTEM.md.

---

## 2. CRITICAL: What you lose with SYSTEM.md

When you write `.pi/SYSTEM.md`, Pi **loses access to all of its built-in capabilities**:

| Lost capability | What that means |
|---|---|
| `read` tool | Cannot read files |
| `write` tool | Cannot create or write files |
| `edit` tool | Cannot edit files |
| `bash` tool | Cannot run commands |
| Hatchet tools | Cannot dispatch workflows |
| Design system tools | Cannot audit UI or look up components |
| All other built-in tools | Gone — unless you explicitly instruct Pi to use them |

If you need any of these tools, **you must list them explicitly** in SYSTEM.md
and describe when to use each one. This is why APPEND_SYSTEM.md is the safer
default — it preserves all of Pi's built-in tool knowledge.

---

## 3. Check before writing

Before creating `.pi/SYSTEM.md`:

1. Confirm with the user: *"SYSTEM.md completely replaces Pi's default prompt. That means Pi loses its built-in coding tools (read, write, edit, bash). Are you sure you want this?"*
2. If unsure, recommend `.pi/APPEND_SYSTEM.md` instead — it adds rules without removing tools.
3. If the user confirms, ask: *"Do you need any of Pi's built-in tools? I can include instructions for them in the SYSTEM.md."*
4. If they need any tools, list them explicitly in the SYSTEM.md with usage guidance.

---

## 4. Create the file

Place at `<cwd>/.pi/SYSTEM.md`. Ensure `.pi/` directory exists.

**File must be named `SYSTEM.md` — not `APPEND_SYSTEM.md`, not `AGENTS.md`.**

### No YAML frontmatter

`.pi/SYSTEM.md` is plain Markdown. No frontmatter.

---

## 5. Write the file

### Structure — full persona, no assumptions

Since Pi has no default behavior, you must define **everything**:

**Identity and purpose:**

```markdown
You are a <role>. Your purpose is to <core function>.

- You operate within these boundaries: <scope>
- You do NOT: <forbidden behaviors>
- You always: <required behaviors>
```

**Capabilities — explicitly define what tools are available:**

```markdown
## Capabilities
- You can <action 1> using <method>
- You can <action 2> using <method>
- You CANNOT: <actions you cannot perform>
```

**If you want to include some of Pi's built-in tools**, list them explicitly:

```markdown
## Available tools
- **read:** Read file contents. Use this to examine source files, configs, and docs.
- **bash:** Run shell commands. Use this for builds, tests, git operations.
- **web_search:** Search the web for current information.
- **fetch_content:** Fetch a specific URL and extract its content.
```

**Domain knowledge:**

```markdown
## Domain
- <topic 1>: <key facts or rules>
- <topic 2>: <key facts or rules>
- <reference material>: <where to find it>
```

**Output format — define how responses should be structured:**

```markdown
## Output rules
- Always <rule 1>
- Never <rule 2>
- Use <format> for <situation>
```

**Boundaries:**

```markdown
## Boundaries
- ✅ Always: <what you should always do>
- ⚠️ Ask first: <what needs approval from user>
- 🚫 Never: <what is forbidden>
```

---

## 6. Validate

Manual checks:
- ✅ Named `SYSTEM.md` — not `APPEND_SYSTEM.md`, not `AGENTS.md`
- ✅ Located inside `.pi/` directory
- ✅ Plain Markdown — no YAML frontmatter
- ✅ User confirmed they want full system prompt replacement
- ✅ If Pi tools are needed, they are listed explicitly with usage guidance
- ✅ Persona is fully defined (no assumptions inherited from Pi's defaults)
- ✅ Boundaries cover all three tiers (always / ask-first / never)
- ✅ Output format is specified

---

## 7. Report

Full path, one-line persona/role description, whether Pi built-in tools were
retained (and which ones), and key boundaries.

Remind user to run `/reload` in Pi after saving.

Emphasize: *"SYSTEM.md replaces Pi's entire system prompt. If you later want to
add rules without removing Pi's built-in tools, replace this with
`.pi/APPEND_SYSTEM.md` instead."*

---

## Templates

Use `assets/templates/` for starting points:

- `assets/templates/system-custom-agent.md` — full custom non-coding agent
- `assets/templates/system-with-tools.md` — custom agent that retains some Pi tools

## References

- `references/refinement.md` — how to iterate after mistakes (shared with sk-build-agents-md and sk-build-append-system)
- `~/.pi/agent/docs/configuration.md` — canonical Pi configuration docs

## Related skills

- **sk-build-agents-md** — for AGENTS.md (hierarchical context files, no trust needed)
- **sk-build-append-system** — for APPEND_SYSTEM.md (additive guardrails, keeps Pi tools)