---
name: work
description: "Pick up the next ticket and run its playbook. Auto-picks from the todo queue, or pass a ticket ID to work on a specific ticket."
user-invocable: true
argument-hint: "[BL-NNN ticket ID, or leave empty to auto-pick]"
---

# /loom:work — Autonomous SDLC Worker

You are the orchestrator — you manage state, compose skills and agents, and route steps, but you produce no artifacts yourself.

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

- Route work to skills and agents; read their verdicts and output paths (the orchestrator evaluates nothing itself — skills produce artifacts, agents judge quality)
- Pass output paths to downstream steps instead of reading file contents (downstream skills need the path, not a summary filtered through the orchestrator's interpretation)
- Leave all git state commands to transition.md (committing mid-playbook creates partial commits that break review). Exception: skills in `skills/ship/` may run `git push` and create PRs.

### For each skill step:

1. Read the skill's `SKILL.md` from the Loom plugin (path given in playbook). If not found: `ERROR: Skill not found at {path}.`
2. Build the Agent tool prompt:
   - Include the SKILL.md content
   - Add curated `## field` context blocks as specified by the playbook
   - Always include `## output_path` pointing to where the skill should write
   - Include `## ticket_notes` with the ticket's notes (feedback context)
3. Spawn the subagent with `cwd` set to the worktree path.
4. Read the agent's text response. Check for `STATUS: complete` or `STATUS: failed — {reason}`.
5. If failed: revert status to `todo`, release lock, stop.
6. If complete: verify the output file exists at `output_path`. Register it via MCP: `task_edit(ticket_id, addReferences=[output_path])`. Proceed to next step.

### For each agent step:

1. Build context for each agent (curated `## field` blocks + `## output_path` + `## output_format`).
2. Spawn all agents in parallel via multiple Agent tool calls.
3. Read each agent's text response. Extract the status/verdict line: `STATUS: complete — VERDICT: pass|needs-work`.
4. For convergence: follow the playbook's convergence rules (max rounds, pass criteria). If needs-work, route to the playbook's fix skill, then re-run the agents.
5. If the playbook's convergence cap is reached without passing, add findings to an Open Questions section and proceed.

## Phase 4: TRANSITION

Read `shared/transition.md` from the Loom plugin directory and follow the "Work transition" section.

## Error handling

If anything fails at any point:
1. Revert status so dispatch can re-pick: `task_edit(ticket_id, status="todo")`
2. Release the lock: `task_edit(ticket_id, assignee=["@released"])`
3. Print the error clearly
4. Stop — the human sees the failure in the terminal, so skip appending notes to the ticket (it would duplicate what they already see and clutter the ticket for the next run)
5. The worktree is preserved with whatever artifacts exist
