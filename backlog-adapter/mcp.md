# Backlog.md MCP Tool Contract

The orchestrator calls these MCP tools to manage ticket state. The MCP server must be configured in the project's `.mcp.json` pointing at the Backlog.md repo.

## Tools used by Loom

Backlog.md MCP exposes 20 tools. Loom uses a subset:

| Operation | MCP Tool | Parameters | Caller |
|-----------|----------|------------|--------|
| View ticket | `task_view` | `id` (string, required) | Orchestrator (dispatch, resolve) |
| Acquire lock | `task_edit` | `id`, `assignee: ["@work-{ts}"]` | Orchestrator (dispatch) |
| Release lock | `task_edit` | `id`, `assignee: ["@released"]` | Orchestrator (transition, failure) |
| Update status | `task_edit` | `id`, `status: "active"` | Orchestrator (dispatch: todo→active) |
| Add reference | `task_edit` | `id`, `addReferences: [path]` | Orchestrator (after skill output) |
| Append feedback | `task_edit` | `id`, `notesAppend: ["..."]` | Orchestrator (rejection) |
| Create successor | `task_create` | `title`, `labels: [type]`, `dependencies: [ticket_id]`, ... | Orchestrator (successor creation) |
| List tickets | `task_list` | `status` (optional string) | Orchestrator (pre-fetch for plan-successors) |
| Search tickets | `task_search` | `query` (optional string) | Orchestrator (ad-hoc lookups) |

### Parameter details (from Backlog.md MCP schema)

**`task_create`** — required: `title` (string). Optional: `description`, `status`, `priority`, `labels` (string[]), `assignee` (string[]), `dependencies` (string[]), `references` (string[]), `acceptanceCriteria` (string[]), and others. Ticket type is stored as a label, not a separate field.

**`task_edit`** — required: `id` (string). All other fields optional. Supports both replace and append patterns: `notesAppend` (string[], appends), `notesSet` (string, replaces), `notesClear` (boolean). Same pattern for `references`/`addReferences`/`removeReferences`, `plan`, `finalSummary`, `acceptanceCriteria`.

**`task_list`** — all optional: `status`, `assignee`, `milestone`, `labels` (string[]), `search`, `limit`.

**`task_view`** — required: `id`. Returns full ticket metadata.

**`task_search`** — all optional: `query`, `status`, `priority`, `modifiedFiles` (string[]), `limit`.

## Lock format

- Work lock: `@work-{unix_timestamp}` (e.g., `@work-1716500000`)
- Review lock: `@review-{unix_timestamp}`
- Free states: empty, `@none`, `@released`
- Stale threshold: 12 hours — locks older than this are treated as free (abandoned session)

## Who calls what

- **Only the orchestrator** calls MCP tools. Skills and agents never touch ticket state.
- **Skills** produce artifacts in the worktree. The orchestrator registers them via `task_edit(id, addReferences=[...])`.
- **Agents** write reports to `output_path`. They never call MCP tools.

## MCP server setup

The project's `.mcp.json` must include the Backlog.md MCP server:

```json
{
  "mcpServers": {
    "backlog": {
      "command": "backlog",
      "args": ["mcp", "start", "--cwd", "/path/to/backlog-repo"]
    }
  }
}
```

The `--cwd` path must match `project.backlog_cwd` in `sdlc.config.yml`.

## Status enum

The MCP server reads valid statuses from the backlog repo's `backlog.config.yml`. Loom uses the 5-stage model: `backlog`, `todo`, `active`, `review`, `done`.
