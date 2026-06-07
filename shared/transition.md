# Transition

Finalize after playbook execution completes. Use the project's `default_branch` from config (defaults to `main`).

## Work transition (after /loom:work playbook completes)

### 1. Commit worktree changes

```bash
git -C {worktree_path} add -A -- . ':!.loom'
```

If the playbook's completion step declares **Deliverables**, also stage each listed path — these are project deliverables that happen to live under `.loom/`. Skip any path that does not exist (e.g., optional mocks that were skipped):

```bash
git -C {worktree_path} add --force {deliverable_path_1} {deliverable_path_2} ...
```

The `--force` flag overrides the `:!.loom` exclusion for these specific files.

Check for staged changes:

```bash
git -C {worktree_path} diff --cached --quiet
```

If exit 0, there are no staged changes — skip the commit and step 2.

Otherwise, commit:

```bash
git -C {worktree_path} commit -m "$(cat <<'EOF'
loom({ticket_id}): {ticket_title}
EOF
)"
```

Use a heredoc (as shown) to avoid shell metacharacters in the ticket title breaking the command. The pathspec `:!.loom` excludes framework process artifacts (reviewer outputs, convergence rounds, fix summaries). Deliverables declared by the playbook are committed explicitly.

### 2. Push and open PR (if `create_pr` is true)

```bash
git -C {worktree_path} push -u origin loom/{ticket_id_lowercase}
gh pr create --head loom/{ticket_id_lowercase} --base {default_branch} --title "loom({ticket_id}): {ticket_title}" --body "$(cat <<'EOF'
{PR body}
EOF
)"
```

Capture the PR URL from the `gh pr create` output. Store it as `{pr_url}` for the completion message.

**PR body composition:** Read `.loom/artifacts/{ticket_id}/changes.md` (the implement agent's change summary). If it exists, use its `## Approach` and `## Tradeoffs` sections as the PR body. If it does not exist (artifact-only playbook), use the ticket description from `## ticket_notes` and list each committed deliverable path under a `## Deliverables` heading so the reviewer knows which files to review. Prefix the body with:
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

If `{pr_url}` was captured in step 2, also print: `PR: {pr_url}`

## Review approval transition (after /loom:review approves)

### 1. Create approved tickets

If `{approved_proposals}` is empty (all proposals were rejected, or the proposals file was empty), skip this step.

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

### 3. Wait for PR merge

Ask the human: "Is the PR merged?" Wait for confirmation before proceeding. The PR is the merge mechanism — the orchestrator never merges locally.

### 4. Cleanup

Run these commands from the **project root** (not from a worktree):

```bash
git checkout {default_branch}
git pull origin {default_branch}
git worktree remove --force {worktree_path}
git branch -d loom/{ticket_id_lowercase}
```

If `git branch -d` fails (refuses due to unmerged commits), verify the PR was actually merged via `gh pr view --head loom/{ticket_id_lowercase} --json state --jq '.state'`. If `MERGED`, use `git branch -D`. If not merged, stop and tell the human.

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

1. Attempt BOTH cleanup operations independently (do not skip 1b if 1a fails):
   a. Revert status so dispatch can re-pick:
      - If working (`active`): `task_edit(ticket_id, status="todo")`
      - If reviewing (`review`): status stays (already dispatchable)
   b. Release lock: `task_edit(ticket_id, assignee=["@released"])`
2. Print the error and stop (include any cleanup failures from step 1)
4. Skip appending notes to the ticket (the human sees the error in the terminal; ticket notes are for cross-session review feedback, not error logs)
5. Worktree is preserved with partial artifacts
