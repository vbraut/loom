---
name: review
description: "Review the next ticket at a gate. Auto-picks from the review queue, or pass a ticket ID."
user-invocable: true
argument-hint: "[BL-NNN ticket ID, or leave empty to auto-pick]"
---

# /loom:review — Human Review Gate

You are the orchestrator — you manage ticket state, execute playbooks, and present results, but you evaluate no artifacts yourself.

## Phase 0: LOAD CONFIG

Read `shared/config.md` from the Loom plugin directory and follow it.

If config loading fails, stop immediately.

## Phase 1: CLAIM

Read `shared/claim.md` from the Loom plugin directory and follow it.

- Mode: `review`
- Manual ID: `$ARGUMENTS` if the user provided one, otherwise empty (auto-pick)
- `backlog_cwd`: from config

## Phase 2: EXECUTE PLAYBOOK

Read `{loom_plugin_dir}/playbooks/{type}.md` and follow it.

### Constraints

- Pass output paths between steps instead of reading file contents (downstream agents need the path, not a summary filtered through the orchestrator's interpretation)
- Leave all git operations to transition.md

### Agent invocation

When a step names an agent to invoke:

1. Read `{loom_plugin_dir}/agents/{name}/AGENT.md`. If not found: `ERROR: Agent '{name}' not found at {path}.`
2. Spawn via Agent tool: include AGENT.md content, `## output_path`, and `## ticket_notes`. Set `cwd` to the worktree.
3. Check response for STATUS line: `complete`, `failed — {reason}`, or `complete — VERDICT: pass|needs-work`.
4. If failed: stop (error handling below).
5. If complete: register output via MCP `task_edit(ticket_id, addReferences=[output_path])`.
6. For parallel agents: spawn all via multiple Agent tool calls.

## Phase 3: HUMAN GATE

Present to the human reviewer:

1. **Ticket summary**: ID, title, type, description.
2. **Artifacts**: list all output files produced during playbook execution.
3. **Agent findings**: reports or summaries from Phase 2.

Ask: **Approve or Reject?**

If the playbook included a successor-planning step and proposals exist, ask the human to confirm, modify, or reject each.

## Phase 4: ROUTE

### On approval:

Read `shared/transition.md` and follow "Review approval transition".

### On rejection:

Read `shared/transition.md` and follow "Review rejection transition".

## Error handling

If anything fails at any point:
1. Release the lock: `task_edit(ticket_id, assignee=["@released"])`
2. Print the error clearly
3. Stop — skip appending notes to the ticket (the human sees the failure in the terminal; ticket notes are for cross-session feedback, not error logs)
4. Worktree preserved

Status is not reverted — `review` is already dispatchable.
