---
name: strat-task-warrior
description: >
  Task Warrior integration for the strategy agent — query, add, modify, and organize
  tasks in hamza-workspace. Use when reviewing tasks, adding new work items, prioritizing,
  mapping tasks to roadmap phases, or maintaining the task structure conventions.
---

# strat-task-warrior — Strategy Task Warrior Bridge

## Conventions

- Projects use dot-notation: `analygo.mvp`, `analygo.ecosystem`, `personal.health`
- Tags for context: `+thinking`, `+blocked`, `+delegated`, `+this-week`
- Priority: H=blocker, M=this-week, L=backlog

## Common queries

| Need | Command |
|------|---------|
| All pending | `task status:pending list` |
| By project | `task project:analygo.mvp status:pending list` |
| This week | `task +this-week list` |
| Blocked | `task +blocked list` |
| Export for analysis | `task status:pending export` |

## Add task

```bash
task add "description" project:<name> +<tag>
```

## Modify

```bash
task <id> modify priority:H
task <id> modify +this-week
task <id> done
```
