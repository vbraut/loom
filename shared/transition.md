# Transition

Finalize after playbook execution completes. Use the project's `default_branch` from config (defaults to `main`).

## Work transition (after /loom:work playbook completes)

### 1. Commit worktree changes

```bash
git add -A
git commit -m "$(cat <<'EOF'
loom({ticket_id}): {ticket_title}
EOF
)"
```

Use a heredoc (as shown) to avoid shell metacharacters in the ticket title breaking the command.

If there are no changes to commit, skip this step.

### 2. Update ticket status

```
task_edit(ticket_id, status="review")
```

### 3. Release lock

```
task_edit(ticket_id, assignee=["@released"])
```

### 4. Stop

Print: `Ticket {ticket_id} ({ticket_type}) → review. Worktree: {worktree_path}`

## Review approval transition (after /loom:review approves)

### 1. Execute successor actions

For each successor action the human approved:
- `create`: `task_create(title=..., description=..., labels=[type], dependencies=[ticket_id], ...)`
- `update`: `task_edit(id=successor_id, ...)` with the specified changes

### 2. Transition ticket

```
task_edit(ticket_id, status="done")
task_edit(ticket_id, assignee=["@released"])
```

### 3. Merge and cleanup

First verify the project root is on the default branch with a clean working tree:

```bash
git checkout {default_branch}
git merge loom/{ticket_id_lowercase} --no-edit
git worktree remove {worktree_path}
git branch -d loom/{ticket_id_lowercase}
```

If `git checkout` fails (dirty working tree), stop. The ticket is already `done` and the branch is preserved.

If merge conflicts, resolve using the strategy in `resolve.md` step 4. If unresolvable, stop and let the human merge manually.

## Review rejection transition

### 1. Append feedback

```
task_edit(ticket_id, notesAppend=["{feedback_text}"])
```

### 2. Transition ticket

```
task_edit(ticket_id, status="todo")
task_edit(ticket_id, assignee=["@released"])
```

The worktree is preserved — the next /loom:work run reuses it with feedback in ticket notes.

## Failure handling

On any failure during playbook execution:

1. Revert status so dispatch can re-pick:
   - If working (`active`): `task_edit(ticket_id, status="todo")`
   - If reviewing (`review`): status stays (already dispatchable)
2. Release lock: `task_edit(ticket_id, assignee=["@released"])`
3. Print the error and stop
4. Skip appending notes to the ticket (the human sees the error in the terminal; ticket notes are for cross-session review feedback, not error logs)
5. Worktree is preserved with partial artifacts
