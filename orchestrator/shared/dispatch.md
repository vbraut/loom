# Dispatch

Pick up the next ticket for processing.

## Auto-pick flow (no manual_id)

1. Run the dispatch script:
   ```bash
   BACKLOG_CWD="{backlog_cwd}" "{loom_plugin_dir}/scripts/next-task.sh" {mode} "@{mode}-$(date +%s)"
   ```

2. Check exit code:
   - **0**: Read ticket ID from stdout. Proceed.
   - **1**: No eligible tickets. Print `No eligible tickets for /loom:{mode}. Nothing to do.` and stop.
   - **2**: Lock contention. Print `Dispatch lock contention — another session is claiming a ticket. Try again shortly.` and stop.
   - **3**: Usage error. This is a framework bug — halt with the error message.
   - **Any other code** (e.g., 127 = script not found): Print the error and stop.

3. If mode is `work`, transition status via MCP:
   ```
   task_edit(id, status="active")
   ```
   For `review` mode, skip — ticket is already in `review` status.

4. Read full ticket metadata: `task_view(ticket_id)`

## Manual pick flow (manual_id provided)

1. Read ticket via MCP: `task_view(manual_id)`

2. Validate status:
   - For `work` mode: must be `todo`. If not: `ERROR: Ticket {id} is in '{status}' status, expected 'todo'.`
   - For `review` mode: must be `review`. If not: `ERROR: Ticket {id} is in '{status}' status, expected 'review'.`

3. Validate assignee is free:
   - Must be empty, `@none`, `@released`, or a stale timestamp (>12h old).
   - If locked: `ERROR: Ticket {id} is locked by {assignee}. Wait for the other session to finish or check if it crashed.`

4. Acquire lock via MCP:
   ```
   task_edit(id, assignee=["@{mode}-{unix_timestamp}"])
   ```

   Steps 3-4 are not atomic — another session could lock between check and acquire. Known MCP limitation (no compare-and-set). Low risk for manual picks.

5. Transition status and read metadata (same as auto-pick steps 3-4).
