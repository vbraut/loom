---
name: work
description: "Pick up the next ticket and run its playbook. Auto-picks from the todo queue, or pass a ticket ID to work on a specific ticket."
user-invocable: true
argument-hint: "[BL-NNN ticket ID, or leave empty to auto-pick]"
---

# /loom:work — Autonomous SDLC Worker

You are the orchestrator — you manage state, compose agents, and route steps, but you produce no artifacts yourself.

## Phase 0: LOAD CONFIG

Read `shared/config.md` from the Loom plugin directory and follow it.

If config loading fails, stop immediately.

## Phase 1: DISPATCH

Read `shared/dispatch.md` from the Loom plugin directory and follow it.

- Mode: `work`
- Manual ID: `$ARGUMENTS` if the user provided one, otherwise empty (auto-pick)
- `backlog_cwd`: from config

If dispatch fails (no tickets, lock contention), stop.

## Phase 2: RESOLVE

Read `shared/resolve.md` from the Loom plugin directory and follow it.

If resolve fails (no matching playbook, worktree error), revert status to `todo`, release the lock via `task_edit(ticket_id, assignee=["@released"])`, and stop.

## Phase 3: EXECUTE PLAYBOOK

Follow the playbook content loaded in Phase 2. The playbook is a natural-language step sequence — execute each step in order.

### Constraints

- Route work to agents; read their verdicts and output paths (the orchestrator evaluates nothing itself)
- Pass output paths to downstream steps instead of reading file contents (downstream agents need the path, not a summary filtered through the orchestrator's interpretation)
- Leave all git operations to transition.md (committing mid-playbook creates partial commits that break review).

### For each step:

1. Read the agent's `AGENT.md` from `{loom_plugin_dir}/agents/{name}/AGENT.md`. If not found: `ERROR: Agent '{name}' not found at {path}.`
2. Build the Agent tool prompt:
   - Include the AGENT.md content
   - Add curated `## field` context blocks as specified by the playbook
   - Always include `## output_path` pointing to where the agent should write
   - Include `## ticket_notes` with the ticket's notes (feedback context)
3. Spawn the subagent with `cwd` set to the worktree path. When the playbook specifies multiple agents for a step, spawn all in parallel via multiple Agent tool calls.
4. Read each agent's text response. Check for `STATUS: complete`, `STATUS: failed — {reason}`, or `STATUS: complete — VERDICT: pass|needs-work`.
5. If failed: revert status to `todo`, release lock, stop.
6. If complete without verdict: verify the output file exists at `output_path`. Register it via MCP: `task_edit(ticket_id, addReferences=[output_path])`. Proceed to next step.
7. For convergence (verdict-bearing steps): follow the playbook's convergence rules (max rounds, pass criteria). If needs-work, route to the playbook's fix agent, then re-run. If the convergence cap is reached without passing, add findings to an Open Questions section and proceed.

## Phase 4: TRANSITION

- `create_pr`: `true` if the playbook declares `pr: true`, otherwise `false`

Read `shared/transition.md` from the Loom plugin directory and follow the "Work transition" section.

## Error handling

If anything fails at any point:
1. Revert status so dispatch can re-pick: `task_edit(ticket_id, status="todo")`
2. Release the lock: `task_edit(ticket_id, assignee=["@released"])`
3. Print the error clearly
4. Stop — the human sees the failure in the terminal, so skip appending notes to the ticket (it would duplicate what they already see and clutter the ticket for the next run)
5. The worktree is preserved with whatever artifacts exist
