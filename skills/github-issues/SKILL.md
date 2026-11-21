---
name: github-issues
description: >
  Create, update, and manage GitHub issues using the session's MCP GitHub tools. Use when the user says
  "create an issue", "file a bug", "request a feature", "update issue X", "set priority", "set start date",
  "create a label", "rename a label", "list repo labels", "link issues", "add dependency", "blocked by",
  "blocking", "search issues", "list issues", "add comment", or any GitHub issue management task. Also use
  for sub-issue management, milestone management, issue fields, and project board operations.
---

# GitHub Issues — issue management via MCP GitHub tools

Source: Adapted from `github/awesome-copilot/skills/github-issues/`

---

## Available tools

This session has `mcp__github__*` tools available. The primary tools for issue management are:

| Tool | Purpose |
|------|---------|
| `mcp__github__issue_read` | Read issue details, sub-issues, comments, labels (methods: get, get_comments, get_sub_issues, get_labels) |
| `mcp__github__list_issues` | List and filter repository issues by state, labels, date |
| `mcp__github__search_issues` | Search issues across repos using GitHub search syntax |
| `mcp__github__issue_write` | Create or update an issue (methods: create, update). Supports title, body, type, labels, assignees, milestone, and issue fields |
| `mcp__github__add_issue_comment` | Add a comment or a reaction to an issue |
| `mcp__github__sub_issue_write` | Add, remove, or reprioritize a sub-issue |
| `mcp__github__projects_list` | List projects, project fields, project items, status updates |
| `mcp__github__projects_get` | Get details of a project, field, item, or status update |
| `mcp__github__projects_write` | Add/update/delete project items, create status updates |

## Workflow

1. **Determine action**: Create, update, query, or manage labels/milestones?
2. **Gather context**: Get repo info, existing labels, milestones. Use the MCP tool `mcp__github__list_issues` with appropriate filters or `mcp__github__search_issues` for cross-repo searches.
3. **Structure content**: Use the appropriate template from `references/templates.md`
4. **Execute**: Use MCP tools. Prefer `mcp__github__issue_write` for creates/updates.
5. **Confirm**: Report the issue URL back to the user

## Creating issues

Use `mcp__github__issue_write` with method `create`:

```json
{
  "method": "create",
  "owner": "org-or-user",
  "repo": "repo-name",
  "title": "Issue title",
  "body": "Issue body in markdown"
}
```

### Optional parameters

Add any of these to the create call:

- `type` — Issue type (Bug, Feature, Task, Epic, etc.)
- `labels` — Array of label names
- `assignees` — Array of GitHub usernames
- `milestone` — Milestone number

### Issue types

Issue types are organization-level metadata (Bug, Feature, Task, etc.). **Prefer issue types over labels for categorization.** When issue types are available, use the `type` parameter instead of applying equivalent labels like `bug` or `enhancement`. Only fall back to labels when the org has no issue types configured.

To discover available types:
```bash
gh api graphql -f query='{ organization(login: "ORG") { issueTypes(first: 10) { nodes { name } } } }' --jq '.data.organization.issueTypes.nodes[].name'
```

### Title guidelines

- Be specific and actionable
- Keep under 72 characters
- When issue types are set, don't add redundant prefixes like `[Bug]`
- Examples:
  - `Login fails with SSO enabled` (with type=Bug)
  - `Add dark mode support` (with type=Feature)
  - `Add unit tests for auth module` (with type=Task)

### Body structure

Always use the templates in `references/templates.md`. Choose based on issue type:

| User Request | Template |
|--------------|----------|
| Bug, error, broken, not working | Bug Report |
| Feature, enhancement, add, new | Feature Request |
| Task, chore, refactor, update | Task |

## Updating issues

Use `mcp__github__issue_write` with method `update`:

```json
{
  "method": "update",
  "owner": "...",
  "repo": "...",
  "issue_number": 123,
  "state": "closed",
  "title": "Updated title"
}
```

Only include fields you want to change. Available fields: `title`, `body`, `state` (open/closed), `labels`, `assignees`, `milestone`.

## Examples

### Example 1: Bug report

**User**: "Create a bug issue — the login page crashes when using SSO"

**Action**: Call `mcp__github__issue_write` with:
- method: create
- title: "Login page crashes when using SSO"
- type: "Bug"
- body: structured bug report from templates.md

### Example 2: Feature request

**User**: "Create a feature request for dark mode with high priority"

**Action**: Call `mcp__github__issue_write` with:
- method: create
- title: "Add dark mode support"
- type: "Feature"
- labels: ["high-priority"]
- body: structured feature request from templates.md

## Common labels

| Label | Use For |
|-------|---------|
| `bug` | Something isn't working |
| `enhancement` | New feature or improvement |
| `documentation` | Documentation updates |
| `good first issue` | Good for newcomers |
| `help wanted` | Extra attention needed |
| `question` | Further information requested |
| `high-priority` | Urgent issues |

## Read operations

For reading and searching issues, use MCP tools:

- `mcp__github__issue_read(method: "get", issue_number: N)` — Get issue details
- `mcp__github__issue_read(method: "get_comments", issue_number: N)` — Get comments
- `mcp__github__issue_read(method: "get_labels")` — Get available labels
- `mcp__github__issue_read(method: "get_sub_issues", issue_number: N)` — Get sub-issues
- `mcp__github__list_issues(...)` — List repo issues with filters
- `mcp__github__search_issues(query: "...")` — Search across repos

## Tips

- Always confirm the repository context before creating issues
- Ask for missing critical information rather than guessing
- Link related issues when known: `Related to #123`
- For updates, fetch current issue first to preserve unchanged fields
- When creating sub-issues, use `mcp__github__sub_issue_write`
- For project board management, use `mcp__github__projects_write`