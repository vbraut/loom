# Backlog.md MCP Tool Contract

The orchestrator calls these MCP tools to manage ticket state. The MCP server must be configured in the project's `.mcp.json` pointing at the Backlog.md repo.

## Operations

| Operation | MCP Tool | Caller | When |
|-----------|----------|--------|------|
| View ticket | `task_view(id)` | Orchestrator | Dispatch (read metadata), Initialize (read type/notes) |
| Acquire lock | `task_edit(id, assignee=["@work-{ts}"])` | Orchestrator | Dispatch (after next-task.sh picks) |
| Acquire review lock | `task_edit(id, assignee=["@review-{ts}"])` | Orchestrator | Review dispatch |
| Release lock | `task_edit(id, assignee=["@released"])` | Orchestrator | Transition, rejection, failure |
| Update status | `task_edit(id, status="active")` | Orchestrator | Dispatch (todo→active) |
| Transition to review | `task_edit(id, status="review")` | Orchestrator | Post-playbook transition |
| Transition to done | `task_edit(id, status="done")` | Orchestrator | Review approval |
| Reject to todo | `task_edit(id, status="todo")` | Orchestrator | Review rejection |
| Add reference | `task_edit(id, addReferences=[path])` | Orchestrator | After skill produces output |
| Append feedback | `task_edit(id, notesAppend=["..."])` | Orchestrator | Review rejection |
| Create ticket | `task_create(title, type, ...)` | Orchestrator | Successor creation |
| List tickets | `task_list(status="todo")` | Orchestrator | Dispatch fallback |
| List all tickets | `task_list()` | Orchestrator | Pre-fetch for plan-successors |
| Search tickets | `task_search(query)` | Orchestrator | Ad-hoc lookups |

## Lock format

- Work lock: `@work-{unix_timestamp}` (e.g., `@work-1716500000`)
- Review lock: `@review-{unix_timestamp}`
- Release: `@released`
- Stale threshold: 12 hours (configurable)

## Who calls what

- **Only the orchestrator** calls MCP tools. Skills and agents never touch ticket state.
- **Skills** produce artifacts in the worktree. The orchestrator registers them via `task_edit(addReferences=...)`.
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
