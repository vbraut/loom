---
name: work
description: "Pick up the next ticket and run its playbook. Auto-picks from the todo queue, or pass a ticket ID to work on a specific ticket."
user-invocable: true
argument-hint: "[BL-NNN ticket ID, or leave empty to auto-pick]"
---

# /loom:work — Autonomous SDLC Worker

Pick up a ticket, run its type's playbook, transition to review.

**You are the orchestrator.** You manage state (status, locks, worktrees). You compose skills and agents. You never do domain work — skills produce artifacts, agents review them. You read verdicts, count convergence, route steps. That is your job.

---

## Phase 0: LOAD CONFIG

Read `orchestrator/shared/config.md` from the Loom plugin directory and follow it.

This gives you: `backlog_cwd`, `default_branch`, `context` slots, `version`. If config loading fails, stop immediately.

---

## Phase 1: DISPATCH

Read `orchestrator/shared/dispatch.md` from the Loom plugin directory and follow it.

- Mode: `work`
- Manual ID: `$ARGUMENTS` if the user provided one, otherwise empty (auto-pick)
- `backlog_cwd`: from the config loaded in Phase 0

If dispatch fails (no tickets, lock contention), stop. Do not proceed.

---

## Phase 2: RESOLVE

Read `orchestrator/shared/resolve.md` from the Loom plugin directory and follow it.

This gives you: ticket type, playbook content, ticket notes (feedback), worktree path.

If resolve fails (no matching playbook, worktree error), revert status to `todo`, release the lock via `task_edit(ticket_id, assignee=["@released"])`, and stop.

---

## Phase 3: EXECUTE PLAYBOOK

Follow the playbook content you loaded in Phase 2 (resolve). The playbook is a natural-language step sequence — read it and execute each step in order.

### For each skill step:

1. Read the skill's `SKILL.md` from the Loom plugin (path given in playbook).
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

### Rules:

- **Never read output file contents.** Pass output paths to downstream steps. Read only the verdict from the agent's text response.
- **Never do domain work.** You don't write specs, review code, or evaluate quality. Skills and agents do that.
- **Never run git state commands** (commit, merge, checkout, worktree) during playbook execution. Only transition.md does that at the end. Exception: skills in `skills/ship/` may run `git push` and create PRs. No other skills may run any git commands.

---

## Phase 4: TRANSITION

Read `orchestrator/shared/transition.md` from the Loom plugin directory and follow the "Work transition" section.

This commits all worktree changes, transitions the ticket to `review`, and releases the lock.

---

## Error handling

If anything fails at any point:
1. Revert status so dispatch can re-pick: `task_edit(ticket_id, status="todo")`
2. Release the lock: `task_edit(ticket_id, assignee=["@released"])`
3. Print the error clearly
4. Stop — do not retry, do not append notes to the ticket
5. The worktree is preserved with whatever artifacts exist
