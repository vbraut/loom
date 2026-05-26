---
name: review
description: "Review the next ticket at a gate. Auto-picks from the review queue, or pass a ticket ID."
user-invocable: true
argument-hint: "[BL-NNN ticket ID, or leave empty to auto-pick]"
---

# /loom:review — Human Review Gate

You are the orchestrator — you manage state, compose agents, and present results, but you evaluate no artifacts yourself.

## Phase 0: LOAD CONFIG

Read `shared/config.md` from the Loom plugin directory and follow it.

If config loading fails, stop immediately.

## Phase 1: DISPATCH

Read `shared/dispatch.md` from the Loom plugin directory and follow it.

- Mode: `review`
- Manual ID: `$ARGUMENTS` if the user provided one, otherwise empty (auto-pick)
- `backlog_cwd`: from config

If dispatch fails, stop.

## Phase 2: RESOLVE

Read `shared/resolve.md` from the Loom plugin directory and follow it.

If resolve fails, release the lock and stop.

## Phase 3: PRE-REVIEW

The playbook (loaded in Phase 2) has a review section specifying which agents to spawn.

If the playbook defines pre-review agents:
1. Read each agent's `AGENT.md` from `{loom_plugin_dir}/agents/{name}/AGENT.md`. If the agent directory does not exist: `ERROR: Agent '{name}' not found at {path}.`
2. Build context for each found agent (artifact paths, project context, `## output_path`, `## output_format`).
3. Spawn all found pre-review agents in parallel.
4. Collect their reports (file paths) and verdicts.

If the playbook does not define pre-review agents, proceed directly to Phase 5.

## Phase 4: SUMMARIZE + PLAN SUCCESSORS

### 4a. Summarize

If pre-review agents produced reports, spawn the `review-summarizer` agent:
- Input: paths to all pre-review agent reports
- Output: synthesized brief with key findings, risk areas, and recommendation

If the `review-summarizer` agent does not exist: `ERROR: Agent 'review-summarizer' not found.`

### 4b. Plan successors

1. Pre-fetch backlog state via MCP: `task_list()`
2. Spawn the `plan-successors` agent:
   - Input: completed ticket artifacts + full backlog state (passed as context — the agent receives all input from you, not from MCP, so it can only propose actions without executing them)
   - Output: proposed actions list (`create`, `update`, or `skip` with reasoning)
   - The agent deduplicates against the backlog context

If the `plan-successors` agent does not exist: `ERROR: Agent 'plan-successors' not found.`

## Phase 5: PRESENT

Present to the human reviewer:

1. **Ticket summary**: ID, title, type, description.
2. **Artifacts**: list all files in the worktree with brief descriptions.
3. **Review summary**: the review-summarizer's brief (if available).
4. **Pre-review findings**: link to each agent's report file (if any).
5. **Proposed successors**: list each proposed action with type, title, and reasoning (if any).

Ask: **Approve or Reject?**

If approving and successors were proposed, ask to confirm, modify, or reject each.

## Phase 6: ROUTE

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
