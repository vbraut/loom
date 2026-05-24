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

## Phase 2: RESOLVE

Read `orchestrator/shared/resolve.md` from the Loom plugin directory and follow it.

This gives you: ticket type, playbook content, ticket notes, worktree path. The worktree already exists from the `/loom:work` run — resolve finds it and syncs it with main.

If resolve fails, release the lock and stop.

---

## Phase 3: PRE-REVIEW

The playbook (loaded in Phase 2) has a review section that specifies which agents to spawn for pre-review analysis.

If the playbook defines pre-review agents:
1. Read each agent's `AGENT.md` from `{loom_plugin_dir}/agents/{name}/AGENT.md`. If the agent directory does not exist, skip it and note the missing agent in the review summary.
2. Build context for each found agent (artifact paths from the worktree, project context, `## output_path`, `## output_format`).
3. Spawn all found pre-review agents in parallel.
4. Collect their reports (file paths) and verdicts.

If no pre-review agents are defined or all are missing, proceed directly to Phase 5 (PRESENT) with no agent reports.

---

## Phase 4: SUMMARIZE + PLAN SUCCESSORS

### 4a. Summarize

If pre-review agents produced reports, spawn the `review-summarizer` agent:
- Input: paths to all pre-review agent reports
- Output: synthesized brief with key findings, risk areas, and recommendation
- The summarizer writes its report to `output_path`

If the `review-summarizer` agent does not exist, skip summarization. Present the individual agent reports directly in Phase 5.

### 4b. Plan successors

1. Pre-fetch backlog state via MCP: `task_list()` — get the full ticket list.
2. Spawn the `plan-successors` agent:
   - Input: completed ticket artifacts + full backlog state (passed as context, not via MCP)
   - Output: proposed actions list:
     - `create`: new ticket with type, title, description, refs, dependency
     - `update`: modify an existing ticket
     - `skip`: already covered by an existing ticket (with reasoning)
   - The agent deduplicates against the backlog context.
   - The agent has NO MCP access — you control all input.

If the `plan-successors` agent does not exist, skip successor planning. Present no proposed successors in Phase 5.

---

## Phase 5: PRESENT

Present to the human reviewer:

1. **Ticket summary**: ID, title, type, description.
2. **Artifacts**: list all files in the worktree with brief descriptions.
3. **Review summary**: the review-summarizer's synthesized brief (if available).
4. **Pre-review findings**: link to each agent's report file (if any agents ran).
5. **Proposed successors**: list each proposed action with type, title, and reasoning (if successor planning ran).

Ask the human: **Approve or Reject?**

If approving and successors were proposed, also ask them to confirm, modify, or reject each proposed successor action.

---

## Phase 6: ROUTE

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

Status is NOT reverted — `review` is already a dispatchable status, so dispatch can re-pick the ticket without a status change.
