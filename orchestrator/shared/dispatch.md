# Dispatch

Pick up the next ticket for processing.

## Inputs

- **mode**: `work` or `review` (set by the calling skill)
- **manual_id**: optional ticket ID from user argument (e.g., `BL-042`)
- **backlog_cwd**: from config

## Auto-pick flow (no manual_id)

1. Run the dispatch script:
   ```bash
   BACKLOG_CWD="{backlog_cwd}" {loom_plugin_dir}/scripts/next-task.sh {mode} "@{mode}-$(date +%s)"
   ```
   - `{loom_plugin_dir}` is the absolute path to the Loom plugin directory.
   - The assignee argument is a timestamped session ID.

2. Check exit code:
   - **0**: Read ticket ID from stdout. Proceed.
   - **1**: No eligible tickets. Print `No eligible tickets for /loom:{mode}. Nothing to do.` and stop.
   - **2**: Lock contention. Print `Dispatch lock contention — another session is claiming a ticket. Try again shortly.` and stop.
   - **3**: Usage error. This is a framework bug — halt with the error message.

3. Set the timestamped lock via MCP (overwrites the script's assignee with a canonical timestamp):
   ```
   task_edit(id, assignee=["@{mode}-{unix_timestamp}"])
   ```

4. If mode is `work`, transition status:
   ```
   task_edit(id, status="active")
   ```

5. Read full ticket metadata via MCP:
   ```
   task_view(ticket_id)
   ```
   Store the result as `ticket_data`.

## Manual pick flow (manual_id provided)

1. Read ticket via MCP: `task_view(manual_id)`

2. Validate status:
   - For `work` mode: ticket must be in `todo` status. If not: `ERROR: Ticket {id} is in '{status}' status, expected 'todo'. Only todo tickets can be worked.`
   - For `review` mode: ticket must be in `review` status. If not: `ERROR: Ticket {id} is in '{status}' status, expected 'review'.`

3. Validate assignee is free:
   - Assignee must be empty, `@none`, `@released`, or a stale timestamp (>12h old).
   - If locked by another active session: `ERROR: Ticket {id} is locked by {assignee}. Wait for the other session to finish or check if it crashed.`

4. Acquire lock and transition (same as auto-pick steps 3-4).

## Output

After dispatch completes:
- `ticket_id` — the claimed ticket ID
- `ticket_data` — full ticket metadata from task_view (title, description, labels, notes, references, etc.)
