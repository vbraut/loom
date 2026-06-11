# Transition

Finalize after playbook execution completes. Use the project's `default_branch` from config (defaults to `main`).

All backlog mutations follow `shared/backlog.md`. Each transition writes the ticket exactly ONCE — status, assignee, notes, and references batched into a single `backlog task edit` call with the echo suppressed.

## Gathering references

`--ref` replaces the whole list, so every transition edit that registers references must write the full union:

1. **Existing:** parse the `References:` line from claim's `ticket_data` (already in context — no extra backlog call). Empty if the line is absent.
2. **New:** every output path recorded in completed-step records of `{worktree_path}/.loom/artifacts/{ticket_id}/progress.md` (work phase), plus the `{review_refs}` list (review phase). Convert any absolute path under `{worktree_path}` to its worktree-relative form.
3. Union both, preserving order and dropping duplicates. Pass each as a separate `--ref` flag.

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

### 3. Update ticket — one batched edit

Gather references (see "Gathering references" above), then set status, release the lock, and register references in a single call:

```bash
ERR=$(BACKLOG_CWD="{backlog_cwd}" backlog task edit {ticket_id} -s review -a @released --ref "{ref_1}" --ref "{ref_2}" ... --plain 2>&1 >/dev/null)
```

Non-zero exit: report `backlog edit failed: {ERR}` and follow Failure handling.

### 4. Stop

Print: `Ticket {ticket_id} ({ticket_type}) → review. Worktree: {worktree_path}`

If `{pr_url}` was captured in step 2, also print: `PR: {pr_url}`

## Review approval transition (after /loom:review approves)

### 1. Create approved tickets

If `{approved_proposals}` is empty (all proposals were rejected, or the proposals file was empty), skip this step.

For each approved proposal:

```bash
BACKLOG_CWD="{backlog_cwd}" backlog task create "{Title}" -d "{Description}" -l "type:{Type}" --dep {ticket_id} --plain 2>&1 | head -3
```

The `head -3` keeps only the file path and new ticket ID for the completion message — the body echo is discarded.

### 2. Transition ticket — one batched edit

Gather references (see "Gathering references" above; include `{review_refs}` from the review run), then:

```bash
ERR=$(BACKLOG_CWD="{backlog_cwd}" backlog task edit {ticket_id} -s done -a @released --ref "{ref_1}" --ref "{ref_2}" ... --plain 2>&1 >/dev/null)
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

### 1. Reset progress

Delete `{worktree_path}/.loom/artifacts/{ticket_id}/progress.md` if it exists — rejection means the work must be redone with the feedback, so the next run must execute the full playbook rather than resume.

### 2. Transition ticket — one batched edit

Append the rejection feedback, set status, release the lock, and register the review-phase references (see "Gathering references"; include `{review_refs}`) in a single call. Use a real newline inside the quoted note string, and keep the `--- REVIEW REJECTION ---` delimiter so review-summarizer can identify prior rejection feedback on re-review:

```bash
ERR=$(BACKLOG_CWD="{backlog_cwd}" backlog task edit {ticket_id} --append-notes "--- REVIEW REJECTION ---
{feedback_text}" -s todo -a @released --ref "{ref_1}" --ref "{ref_2}" ... --plain 2>&1 >/dev/null)
```

The worktree is preserved — the next /loom:work run reuses it with feedback in ticket notes.

## Failure handling

On any failure during playbook execution:

1. Revert status (if needed) and release the lock in ONE batched edit:
   - If working (`active`):
     ```bash
     ERR=$(BACKLOG_CWD="{backlog_cwd}" backlog task edit {ticket_id} -s todo -a @released --plain 2>&1 >/dev/null)
     ```
   - If reviewing (`review` — status stays, already dispatchable):
     ```bash
     ERR=$(BACKLOG_CWD="{backlog_cwd}" backlog task edit {ticket_id} -a @released --plain 2>&1 >/dev/null)
     ```
2. Print the error and stop (include any cleanup failures from step 1)
4. Skip appending notes to the ticket (the human sees the error in the terminal; ticket notes are for cross-session review feedback, not error logs)
5. Worktree is preserved with partial artifacts
