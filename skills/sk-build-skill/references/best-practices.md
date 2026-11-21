# Best practices reference

Load this reference when designing a new skill's structure, scope, or instruction patterns.

## Spending context wisely

- **Add what the agent lacks, omit what it knows.** If the agent would get it wrong without the instruction, keep it. If not, cut it.
- **Start from real expertise** — extract from hands-on tasks and real corrections, not generic references.
- **Refine with real execution** — run the skill, then iterate. One pass of execute-then-revise noticeably improves quality.

## Patterns for effective instructions

| Pattern | When |
|---|---|
| **Gotchas section** | Always. Highest-value content. |
| **Templates for output format** | When output must follow a specific structure (agents match templates better than prose). |
| **Checklists** | Multi-step workflows with dependencies or validation gates. |
| **Validation loops** | When the agent should self-check before proceeding. |
| **Plan-validate-execute** | Batch or destructive operations. |
| **Bundled scripts** | When the agent reinvents the same logic each run. |

## Calibrating control

- **Give freedom** when multiple approaches are valid. Explain *why* — agents make better decisions with understanding.
- **Be prescriptive** when operations are fragile, consistency matters, or a specific sequence must be followed.
- **Provide defaults, not menus** — pick one recommended approach, mention alternatives briefly.
- **Favor procedures over declarations** — teach *how to approach* a class, not *what to produce* for one instance.

## Progressive disclosure

- Keep SKILL.md ≤500 lines, ≤5K tokens.
- Move detail to `references/`. Tell the agent *when* to load each file: "Read X if Y happens".

---

*Full guide: https://agentskills.io/skill-creation/best-practices.md*