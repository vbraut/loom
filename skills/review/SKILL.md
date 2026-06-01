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

### Constraints

- Pass output paths between steps instead of reading file contents (downstream agents need the path, not a summary filtered through the orchestrator's interpretation)
- Leave all git operations to transition.md

### Agent invocation

When a step names an agent to invoke:

1. Read `{loom_plugin_dir}/agents/{name}/AGENT.md`. If not found: `ERROR: Agent '{name}' not found at {path}.`
2. **Resolve upstream artifacts.** When a playbook step specifies **Upstream:** paths, resolve them to absolute paths from the worktree root. When the **Upstream:** contains a retrieval instruction (e.g., "retrieve via MCP `task_view`"), execute the retrieval: call `task_view(ticket_id)`, extract the `references` list, verify each path exists and is non-empty, and use the valid paths.
3. Spawn via Agent tool: include AGENT.md content, `## output_path`, `## ticket_notes`, `## config` (containing `default_branch` and context paths), `## quality_principles` (from `shared/quality-principles.md`), and `## upstream_artifacts` with the resolved paths from step 2. All paths must be absolute. Set `cwd` to the worktree.
4. Check response for STATUS line: `complete`, `failed — {reason}`, or `complete — VERDICT: pass|needs-work`.
5. If failed: stop (error handling below).
6. If complete: register output via MCP `task_edit(ticket_id, addReferences=[output_path])`.
6b. Before passing an output_path to a downstream step as upstream_artifacts, verify the file exists and has at least one non-whitespace character. If missing or whitespace-only, treat the producing agent as failed.
7. For parallel agents: spawn all via multiple Agent tool calls.
8. If a step contains a `**Pre-fetch**` block, execute those instructions before spawning the agent for that step.

If `{review_playbook}` is set (from claim.md), read it and follow it. If a step contains convergence fields (`**Agents:**`, `**Verdict logic:**`, `**Max rounds:**`), read `shared/convergence.md` from the Loom plugin directory and follow it for that step.

If `{review_playbook}` is empty, skip Phase 2 — no review playbook agents to run. Retrieve work-phase artifact references via MCP `task_view(ticket_id)` and present them directly in the human gate.

## Phase 3: HUMAN GATE

Present to the human reviewer:

1. **Ticket summary**: ID, title, type, description.
2. **Artifacts**: list all output files produced during playbook execution (or work-phase artifacts if no review playbook ran).
3. **Agent findings**: reports or summaries from Phase 2 (skip if no review playbook ran).

Ask: **Approve or Reject?**

### Proposal handling

If the playbook included a ticket-planner step, read its output file. Parse each `### N` block under `## Proposals` as a proposal — extract Title, Type, Description, and Rationale fields. If no `### N` blocks exist under `## Proposals`, skip proposal handling.

For each proposal:

1. **Validate Type** — check that `playbooks/{Type}.md` exists. If not, flag the proposal to the human as having an invalid type.
2. **Present** — show Title, Type, Description, and Rationale.
3. **Ask** — approve, modify, or reject.
4. **On modify** — accept the human's changes, then re-validate (non-empty Title, valid Type). Loop until valid or rejected.
5. **On reject** — drop the proposal silently.

Collect only approved (possibly modified) proposals. Pass them to Phase 4 as `{approved_proposals}`.

## Phase 4: ROUTE

### On approval:

Read `shared/transition.md` and follow "Review approval transition". Pass `{approved_proposals}` (may be empty if all were rejected or no ticket-planner ran).

### On rejection:

Read `shared/transition.md` and follow "Review rejection transition".

## Error handling

If anything fails at any point:
1. Release the lock: `task_edit(ticket_id, assignee=["@released"])`
2. Print the error clearly
3. Stop — skip appending notes to the ticket (the human sees the failure in the terminal; ticket notes are for cross-session feedback, not error logs)
4. Worktree preserved

Status is not reverted — `review` is already dispatchable.
