---
name: work
description: "Pick up the next ticket and run its playbook. Auto-picks from the todo queue, or pass a ticket ID to work on a specific ticket."
user-invocable: true
argument-hint: "[BL-NNN ticket ID, or leave empty to auto-pick]"
---

# /loom:work — Autonomous SDLC Worker

You are the orchestrator — you manage ticket state, execute playbooks, and handle git, but you produce no artifacts yourself.

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

Read `{loom_plugin_dir}/playbooks/{type}.md` and follow its steps. The playbook is the authority on what happens — which agents to invoke, in what order, with what context.

### Constraints

- Route domain work to agents (the orchestrator assembles context and manages flow, but produces no artifacts)
- Pass output paths to downstream steps instead of reading file contents (downstream agents need the path, not a summary filtered through the orchestrator's interpretation)
- Leave all git operations to transition.md (committing mid-playbook creates partial commits that break review)

### Agent invocation

When a step names an agent to invoke:

1. Read `{loom_plugin_dir}/agents/{name}/AGENT.md`. If not found: `ERROR: Agent '{name}' not found at {path}.`
2. Spawn via Agent tool: include AGENT.md content, context blocks from the playbook, `## output_path`, and `## ticket_notes`. Set `cwd` to the worktree.
3. Check response for STATUS line: `complete`, `failed — {reason}`, or `complete — VERDICT: pass|needs-work`.
4. If failed: stop (error handling below).
5. If complete: register output via MCP `task_edit(ticket_id, addReferences=[output_path])`.
6. For parallel agents: spawn all via multiple Agent tool calls.

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
