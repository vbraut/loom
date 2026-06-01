# Transition

Finalize after playbook execution completes. Use the project's `default_branch` from config (defaults to `main`).

## Work transition (after /loom:work playbook completes)

### 1. Commit worktree changes

```bash
git add -A -- ':!.loom'
git diff --cached --quiet
```

If `git diff --cached --quiet` exits 0, there are no staged changes — skip the commit and step 2.

Otherwise, commit:

```bash
git commit -m "$(cat <<'EOF'
loom({ticket_id}): {ticket_title}
EOF
)"
```

Use a heredoc (as shown) to avoid shell metacharacters in the ticket title breaking the command. The pathspec `:!.loom` excludes all framework artifacts — they are ephemeral process state, not project deliverables.

### 2. Push and open PR (if `create_pr` is true)

```bash
git -C {worktree_path} push -u origin loom/{ticket_id_lowercase}
gh pr create --head loom/{ticket_id_lowercase} --base {default_branch} --title "loom({ticket_id}): {ticket_title}" --body "$(cat <<'EOF'
{PR body}
EOF
)"
```

**PR body composition:** Read `.loom/artifacts/{ticket_id}/changes.md` (the implement agent's change summary). If it exists, use its `## Approach` and `## Summary` sections as the PR body. If it does not exist (e.g., non-code playbook), use the ticket description from `## ticket_notes` instead. Prefix the body with:
```
**Ticket:** {ticket_id} — {ticket_title}
**Type:** {ticket_type}
```

### 3. Update ticket status

```
task_edit(ticket_id, status="review")
```

### 4. Release lock

```
task_edit(ticket_id, assignee=["@released"])
```

### 5. Stop

Print: `Ticket {ticket_id} ({ticket_type}) → review. Worktree: {worktree_path}`

## Review approval transition (after /loom:review approves)

### 1. Create approved tickets

If `{approved_proposals}` is empty (no ticket-planner ran, or all proposals were rejected), skip this step.

For each approved proposal:

```
task_create(
  title={Title},
  description={Description},
  labels=["type:{Type}"],
  dependencies=[ticket_id]
)
```

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

If merge conflicts: prefer default branch for config, dependencies, and infrastructure (conflicts here break builds/deploys). For code files, three-way merge preserving both sides' intent. If unresolvable, `git merge --abort`, stop, and let the human merge manually.

## Review rejection transition

### 1. Append feedback

```
task_edit(ticket_id, notesAppend=["--- REVIEW REJECTION ---\n{feedback_text}"])
```

Use the `--- REVIEW REJECTION ---` delimiter so review-summarizer can identify prior rejection feedback on re-review.

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
