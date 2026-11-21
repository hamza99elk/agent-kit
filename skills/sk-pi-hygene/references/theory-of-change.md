# Theory of Change — Why Context Hierarchy Matters

This reference explains the reasoning behind the four-layer model. Load it when you need to justify a restructuring decision or when the user asks "why does this matter?"

## The context budget problem

Pi's context window is finite. Every rule, token contract, import path, and DB table that sits in `AGENTS.md` or `APPEND_SYSTEM.md` consumes that budget on *every* turn — even when the task is unrelated.

A 200-line AGENTS.md file with design system rules occupies the same budget when the agent is writing a database migration as when it's building a page. The agent can filter, but filtering itself consumes reasoning tokens.

## Skills are the release valve

Skills loaded on-demand have zero baseline cost. A 300-line skill with workflows, gotchas, and references costs nothing until the agent encounters a task that matches its description. This is why:

- Step-by-step workflows → skill
- API error catalogs → skill references
- Common pitfalls → skill gotchas
- Design system golden rules → either workspace SYSTEM.md or a skill

## The progressive density principle

From: *The Design of Agentic Systems* (paraphrased)

> Each layer of context should be *just specific enough* to be useful at that scope, and no more.

This means:

- **Global (~/.pi/):** Only rules that are true regardless of project. The God File Rule fits — it's a code convention about file structure. The Analygo design layout rules don't — they're specific to one framework and one design system.

- **Repo root (AGENTS.md):** Only the map and the compass. Tell the agent what's in the repo and how to find deeper rules. Don't give the agent the full rulebook at the front gate.

- **Subtree (apps/ AGENTS.md):** Directory orientation and pointers. "You're in the apps layer. There's a SYSTEM.md with full details. Here are the no-go zones."

- **Workspace (SYSTEM.md):** The full manual. This replaces the prompt entirely because the agent is now "inside" the workspace and needs all the rules.

## Why SYSTEM.md replaces (not merges) the prompt

Pi's architecture: when `cd` enters a directory with `.pi/SYSTEM.md`, that file becomes the new system prompt. It does NOT merge with the parent SYSTEM.md or AGENTS.md.

This means:
- The SYSTEM.md must be self-contained for the workspace
- It cannot assume AGENTS.md rules are still in effect
- BUT: AGENTS.md rules *are* merged into context from the directory walk
- So SYSTEM.md + AGENTS.md = the full behavioral context

The hybrid model:
- AGENTS.md provides structural/orientation context (directory walk, always loaded)
- SYSTEM.md provides behavioral instructions (prompt replacement, dense)
- APPEND_SYSTEM.md provides universal guardrails (project trust, supplement)

## When to use each mechanism

| You want to... | Use | Because |
|---|---|---|
| Tell every session about a universal coding convention | Global `APPEND_SYSTEM.md` | Always loaded, applies to all projects |
| Orient the agent in a new repo | Root `AGENTS.md` | Directory-walked into any session in the repo |
| Show which sub-apps exist and where SYSTEM.md lives | Subtree `AGENTS.md` | Merged upward, visible in all child directories |
| Give the agent full behavioral rules for a workspace | `.pi/SYSTEM.md` | Replaces prompt, can be as dense as needed |
| Share a step-by-step workflow that's too detailed for SYSTEM.md | A skill | Loaded on-demand, zero baseline cost |
| Enforce a project-wide policy (no deep imports, contract-first) | `.pi/APPEND_SYSTEM.md` | Project trust, supplements AGENTS.md without bloating it |
| Document common failure modes for a specific API | Skill references | Loaded only when the error occurs |