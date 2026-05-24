# Transition

Finalize after playbook execution completes.

## Work transition (after /loom:work playbook completes)

### 1. Commit worktree changes

In the worktree directory:
```bash
git add -A
git commit -m "loom({ticket_id}): {ticket_type} complete"
```

If there are no changes to commit, skip this step (the playbook may have committed nothing, which is valid for research-only steps).

### 2. Update ticket status

Via MCP:
```
task_edit(ticket_id, status="review")
```

### 3. Release lock

Via MCP:
```
task_edit(ticket_id, assignee=["@released"])
```

### 4. Stop

Print a summary: `Ticket {ticket_id} ({ticket_type}) → review. Worktree: {worktree_path}`

The worktree and branch are preserved for the review step.

## Review approval transition (after /loom:review approves)

### 1. Execute successor actions

For each confirmed successor from the plan-successors agent:
- `create`: `task_create(title=..., description=..., labels=[type], dependencies=[ticket_id], ...)`
- `update`: `task_edit(id=successor_id, ...)` with the specified changes

### 2. Transition ticket

Via MCP:
```
task_edit(ticket_id, status="done")
task_edit(ticket_id, assignee=["@released"])
```

### 3. Cleanup worktree

```bash
git worktree remove {worktree_path}
git branch -d loom/{ticket_id_lowercase}
```

## Review rejection transition

### 1. Append feedback

Via MCP:
```
task_edit(ticket_id, notesAppend=["{feedback_text}"])
```

### 2. Transition ticket

```
task_edit(ticket_id, status="todo")
task_edit(ticket_id, assignee=["@released"])
```

The worktree is preserved — the next /loom:work run will reuse it and see the feedback in ticket notes.

## Failure handling

On any failure during playbook execution (skill returns `STATUS: failed`, agent crashes, etc.):

1. Revert ticket status so dispatch can pick it up again:
   - If working (`active`): `task_edit(ticket_id, status="todo")`
   - If reviewing (`review`): status stays in `review` (already dispatchable)
2. Release lock: `task_edit(ticket_id, assignee=["@released"])`
3. Print the error and stop
4. The worktree is preserved with whatever partial artifacts exist
