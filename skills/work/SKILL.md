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

## Phase 1: CLAIM

Read `shared/claim.md` from the Loom plugin directory and follow it.

- Mode: `work`
- Manual ID: `$ARGUMENTS` if the user provided one, otherwise empty (auto-pick)
- `backlog_cwd`: from config

## Phase 2: EXECUTE PLAYBOOK

### Constraints

- Pass output paths to downstream steps instead of reading file contents (downstream agents need the path, not a summary filtered through the orchestrator's interpretation)
- Leave all git operations to transition.md (committing mid-playbook creates partial commits that break review)

### Agent invocation

When a step names an agent to invoke:

1. Read `{loom_plugin_dir}/agents/{name}/AGENT.md`. If not found: `ERROR: Agent '{name}' not found at {path}.`
2. Spawn via Agent tool: include AGENT.md content, `## output_path`, `## ticket_notes`, and `## upstream_artifacts` when the playbook step specifies upstream paths (marked with **Upstream:** in the step text). All paths passed to agents must be absolute, resolved from the worktree root. Set `cwd` to the worktree.
3. Check response for STATUS line: `complete`, `failed — {reason}`, or `complete — VERDICT: pass|needs-work`.
4. If failed: stop (error handling below).
5. If complete: register output via MCP `task_edit(ticket_id, addReferences=[output_path])`.
5b. Before passing an output_path to a downstream step as upstream_artifacts, verify the file exists and has at least one non-whitespace character. If missing or whitespace-only, treat the producing agent as failed.
6. For parallel agents: spawn all via multiple Agent tool calls.

Read `{loom_plugin_dir}/playbooks/{type}.md` and follow it. If the playbook contains a `## Convergence` section, read `shared/convergence.md` from the Loom plugin directory and follow it.

## Phase 3: TRANSITION

- `create_pr`: `true` if the playbook declares `pr: true`, otherwise `false`

Read `shared/transition.md` from the Loom plugin directory and follow the "Work transition" section.

## Error handling

If anything fails at any point:
1. Revert status so the ticket is re-claimable: `task_edit(ticket_id, status="todo")`
2. Release the lock: `task_edit(ticket_id, assignee=["@released"])`
3. Print the error clearly
4. Stop — the human sees the failure in the terminal, so skip appending notes to the ticket (it would duplicate what they already see and clutter the ticket for the next run)
5. The worktree is preserved with whatever artifacts exist
