---
name: review
description: "Review the next ticket at a gate. Auto-picks from the review queue, or pass a ticket ID."
user-invocable: true
argument-hint: "[BL-NNN ticket ID, or leave empty to auto-pick]"
---

# /loom:review — Human Review Gate

Pick up a ticket in review, run pre-review agents, present artifacts for human approval.

**You are the orchestrator.** Same rules as /loom:work — you manage state, compose agents, never do domain work.

---

## Phase 0: LOAD CONFIG

Read `orchestrator/shared/config.md` from the Loom plugin directory and follow it.

This gives you: `backlog_cwd`, `context` slots, `version`. If config loading fails, stop immediately.

---

## Phase 1: DISPATCH

Read `orchestrator/shared/dispatch.md` from the Loom plugin directory and follow it.

- Mode: `review`
- Manual ID: `$ARGUMENTS` if the user provided one, otherwise empty (auto-pick)
- `backlog_cwd`: from the config loaded in Phase 0

If dispatch fails, stop.

---

## Phase 1b: RESOLVE

Read `orchestrator/shared/resolve.md` from the Loom plugin directory and follow it.

This gives you: ticket type, playbook content, ticket notes, worktree path. The worktree already exists from the `/loom:work` run — resolve finds it and syncs it with main.

If resolve fails, release the lock and stop.

---

## Phase 2: PRE-REVIEW

The playbook (loaded in Phase 1b) has a review section that specifies which agents to spawn for pre-review analysis.

If the playbook defines pre-review agents:
1. Build context for each agent (artifact paths from the worktree, project context, `## output_path`, `## output_format`).
2. Spawn all pre-review agents in parallel.
3. Collect their reports (file paths) and verdicts.

---

## Phase 2b: SUMMARIZE

Spawn the `review-summarizer` agent:
- Input: paths to all pre-review agent reports
- Output: synthesized brief with key findings, risk areas, and recommendation
- The summarizer writes its report to `output_path`

---

## Phase 3: PLAN SUCCESSORS

1. Pre-fetch backlog state via MCP: `task_list()` — get the full ticket list.
2. Spawn the `plan-successors` agent:
   - Input: completed ticket artifacts + full backlog state (passed as context, not via MCP)
   - Output: proposed actions list:
     - `create`: new ticket with type, title, description, refs, dependency
     - `update`: modify an existing ticket
     - `skip`: already covered by an existing ticket (with reasoning)
   - The agent deduplicates against the backlog context.
   - The agent has NO MCP access — you control all input.

---

## Phase 4: PRESENT

Present to the human reviewer:

1. **Ticket summary**: ID, title, type, description.
2. **Artifacts**: list all files in the worktree with brief descriptions.
3. **Review summary**: the review-summarizer's synthesized brief.
4. **Pre-review findings**: link to each agent's report file.
5. **Proposed successors**: list each proposed action with type, title, and reasoning.

Ask the human: **Approve or Reject?**

If approving, also ask them to confirm, modify, or reject each proposed successor action.

---

## Phase 5: ROUTE

### On approval:

Read `orchestrator/shared/transition.md` and follow the "Review approval transition" section:
1. Execute confirmed successor actions via MCP (create tickets with dependencies, update existing tickets).
2. Transition: `task_edit(ticket_id, status="done")`, release lock.
3. Cleanup: merge branch into main, delete worktree and branch.

### On rejection:

Read `orchestrator/shared/transition.md` and follow the "Review rejection transition" section:
1. Collect feedback from the human (what to fix, what's wrong).
2. Append feedback to ticket notes via MCP.
3. Transition: `task_edit(ticket_id, status="todo")`, release lock.
4. The worktree is preserved — the next /loom:work run will reuse it.

---

## Error handling

If anything fails at any point:
1. Release the lock: `task_edit(ticket_id, assignee=["@released"])`
2. Print the error clearly
3. Stop — do not retry, do not append notes to the ticket
4. The worktree is preserved with whatever artifacts exist
