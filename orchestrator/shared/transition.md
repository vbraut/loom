# Transition

Finalize after playbook execution completes. Use the project's default branch from config (`default_branch`, defaults to `main`). All references to `main` below use this value.

## Work transition (after /loom:work playbook completes)

### 1. Commit worktree changes

In the worktree directory, stage and commit all changes. The project's `.gitignore` applies — it prevents secrets, binaries, and OS metadata from being staged.

```bash
git add -A
git commit -m "$(cat <<'EOF'
loom({ticket_id}): {ticket_title}
EOF
)"
```

Use a heredoc (as shown) to avoid shell metacharacters in the ticket title breaking the command. Use the ticket title from `ticket_data` so git history is readable.

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

### 3. Merge and cleanup

Merge the worktree branch into the default branch, then clean up. First verify the project root is on the default branch with a clean working tree:

```bash
git checkout {default_branch}
git merge loom/{ticket_id_lowercase} --no-edit
git worktree remove {worktree_path}
git branch -d loom/{ticket_id_lowercase}
```

If `git checkout` fails (dirty working tree or wrong branch), stop and let the human resolve the project root state. The ticket is already `done` and the branch is preserved.

If the merge has conflicts, resolve them using the same strategy as `resolve.md` step 4 (prefer default branch for non-artifact files, prefer worktree for artifacts). If conflicts cannot be resolved, stop and let the human handle the merge manually.

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
4. Do not append notes or error details to the ticket — the human sees the failure in the terminal
5. The worktree is preserved with whatever partial artifacts exist
