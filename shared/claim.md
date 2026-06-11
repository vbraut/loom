# Claim

Claim a ticket and prepare it for execution: pick, lock, type, worktree.

All backlog commands follow `shared/backlog.md` (explicit `BACKLOG_CWD`, batched mutations, suppressed echo).

## 1. Pick and lock

### Auto-pick (no manual_id)

1. Run the dispatch script:
   ```bash
   BACKLOG_CWD="{backlog_cwd}" "{loom_plugin_dir}/scripts/next-task.sh" {mode} "@{mode}-$(date +%s)"
   ```

2. Check exit code:
   - **0**: Read ticket ID from stdout. Proceed.
   - **1**: No eligible tickets. Print `No eligible tickets for /loom:{mode}. Nothing to do.` and stop.
   - **2**: Lock contention. Print `Dispatch lock contention — another session is claiming a ticket. Try again shortly.` and stop.
   - **3**: Usage error. This is a framework bug — halt with the error message.
   - **4**: Claim failed — the task was picked but assignment failed (race condition or CLI error). Print `Claim failed for the selected ticket. Try again.` and stop.
   - **Any other code** (e.g., 127 = script not found): Print the error and stop.

3. Transition status and read the ticket in ONE call — the edit echo is the full view:
   - `work` mode:
     ```bash
     BACKLOG_CWD="{backlog_cwd}" backlog task edit {id} -s active --plain
     ```
     Use the printed output as `ticket_data`. Non-zero exit = claim failed (exit code 4 semantics above).
   - `review` mode (no status change):
     ```bash
     BACKLOG_CWD="{backlog_cwd}" backlog task {id} --plain
     ```

### Manual pick (manual_id provided)

1. Acquire the dispatch lock to prevent TOCTOU races (same mkdir-based mechanism as `next-task.sh`):
   ```bash
   LOCK="{backlog_cwd}/.loom/dispatch.lock"
   mkdir -p "$(dirname "$LOCK")"
   ```
   Before attempting `mkdir "$LOCK"`, check for stale locks: if `"$LOCK"` exists and is older than 600 seconds (based on directory mtime), remove it with `rmdir "$LOCK"` (matches next-task.sh's stale lock cleanup).
   ```bash
   mkdir "$LOCK"
   ```
   If `mkdir "$LOCK"` fails (directory already exists and not stale): `ERROR: Dispatch lock contention — another session is claiming a ticket. Try again shortly.`

**Important:** If ANY step below (2-7) fails for any reason, release the dispatch lock (`rmdir "$LOCK"`) before reporting the error. The dispatch lock must not outlive the manual pick sequence.

2. Read the ticket: `BACKLOG_CWD="{backlog_cwd}" backlog task {manual_id} --plain` — use the output as `ticket_data`.

3. Validate status:
   - For `work` mode: must be `todo`. If not: `rmdir "$LOCK"`, then `ERROR: Ticket {id} is in '{status}' status, expected 'todo'.`
   - For `review` mode: must be `review`. If not: `rmdir "$LOCK"`, then `ERROR: Ticket {id} is in '{status}' status, expected 'review'.`

4. Validate assignee is free:
   - Must be empty, `@none`, `@released`, or a stale timestamp (>12h old).
   - If locked: `rmdir "$LOCK"`, then `ERROR: Ticket {id} is locked by {assignee}. Wait for the other session to finish or check if it crashed.`

5. Acquire the lock — and for `work` mode, batch the status transition into the same edit:
   - `work` mode:
     ```bash
     ERR=$(BACKLOG_CWD="{backlog_cwd}" backlog task edit {id} -a "@work-{unix_timestamp}" -s active --plain 2>&1 >/dev/null)
     ```
   - `review` mode:
     ```bash
     ERR=$(BACKLOG_CWD="{backlog_cwd}" backlog task edit {id} -a "@review-{unix_timestamp}" --plain 2>&1 >/dev/null)
     ```
   Non-zero exit: `rmdir "$LOCK"`, then `ERROR: Failed to lock ticket {id}: {ERR}`.

6. Release the dispatch lock: `rmdir "$LOCK"`.

7. Use the ticket data from step 2 as `ticket_data` — the lock/status edit changes no field the playbook reads.

## 2. Determine ticket type

Read the `type:` label from `ticket_data` (e.g., `type:code-fix` → type is `code-fix`).

- **No `type:` label**: `ERROR: Ticket {ticket_id} has no type: label.`
- **Multiple `type:` labels**: `ERROR: Ticket {ticket_id} has multiple type: labels: [{values}].`
- **Rigor**: read the optional `rigor:` label (`rigor:light`, `rigor:standard`, `rigor:full`). Default to `standard` when absent or unrecognized. Expose as `{rigor}` — playbooks scale assessment depth and reviewer panels with it.
- **Playbook resolution**: resolve the playbook filename based on mode:
  - `work` mode: `{type}.md` — must exist. If not: `ERROR: No playbook for type '{type}' in work mode (expected: playbooks/{type}.md)`
  - `review` mode: `{type}-review.md` — optional. If it exists, set `{review_playbook}` to the path. If not, set `{review_playbook}` to empty (the review orchestrator will run the default review sequence: review-summarizer → ticket-planner).

## 3. Ensure worktree

Worktree path is relative to the **project root** (the directory containing `sdlc.config.yml`).

- Branch name: `loom/{ticket_id_lowercase}` (e.g., `loom/bl-042`)
- Worktree path: `{project_root}/.loom/worktrees/{ticket_id_lowercase}/`

Use the project's `default_branch` from config (defaults to `main`).

**If the worktree already exists** (prior run, rejection, or review pickup):
- If there are uncommitted changes: `git -C {worktree_path} add -A -- . ':!.loom' && git -C {worktree_path} commit -m "loom: preserve partial artifacts from prior run"` (skip if working tree is clean). The `:!.loom` pathspec keeps .loom/ artifacts ephemeral.
- Sync: `git -C {worktree_path} merge {default_branch} --no-edit`
- On merge conflict: prefer default branch for non-artifact files — config, dependencies, infrastructure (conflicts here break builds/deploys). Prefer worktree for artifact files — specs, plans, reviews, mocks under `.claude/` or `.loom/` (these represent the ticket's work-in-progress). For code files, three-way merge preserving both sides' intent.
- If unresolvable: `git merge --abort`, report the conflict, stop.

**If no worktree exists:**
- If branch `loom/{ticket_id_lowercase}` already exists (orphaned): `git worktree add {worktree_path} loom/{ticket_id_lowercase}`, then sync as above.
- Otherwise: `git branch loom/{ticket_id_lowercase} {default_branch}`, then `git worktree add {worktree_path} loom/{ticket_id_lowercase}`
