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
2. Spawn via Agent tool: include AGENT.md content, `## output_path`, `## ticket_notes`, `## config` (containing `default_branch` and context paths), `## quality_principles` (from `shared/quality-principles.md`), and `## upstream_artifacts` when the playbook step specifies upstream paths (marked with **Upstream:** in the step text). When a step has `**Upstream for {agent}:**`, use that for the named agent instead of the default `**Upstream:**`. All paths passed to agents must be absolute, resolved from the worktree root. Set `cwd` to the worktree.
3. Check response for STATUS line: `complete`, `failed — {reason}`, or `complete — VERDICT: pass|needs-work`.
4. If failed: stop (error handling below).
5. If complete: register output via MCP `task_edit(ticket_id, addReferences=[output_path])`.
5b. Before passing an output_path to a downstream step as upstream_artifacts, verify the file exists and has at least one non-whitespace character. If missing or whitespace-only, treat the producing agent as failed.
6. For parallel agents: spawn all via multiple Agent tool calls. When a step has `**Agent output paths:**` (keyed per agent name), look up each agent's name in the list and pass its path as `## output_path`. When a step has a single `**Output path:**`, all agents in that step share the same path (only valid for single-agent steps).
7. If a step contains a `**Pre-fetch**` block, execute those instructions before spawning the agent for that step.

### Named agent spawning

When a playbook step marks agents as `(named, parallel)`, spawn each agent with the `name` parameter set to the agent's name (e.g., `assess-inversion`, `persona-pm`). Named agents can be resumed later via SendMessage for cross-talk rounds. For persona-reviewer instances, use the name format `persona-{persona_name}` (e.g., `persona-pm`, `persona-dev`, `persona-security`).

### Cross-talk handling

When a playbook step contains cross-talk fields (`**Named agents:**`, `**Max rounds:**`), read `shared/cross-talk.md` from the Loom plugin directory and follow it for that step. Cross-talk resumes named agents from the preceding assess step via SendMessage — do not respawn them.

### Quality principles

Read `{loom_plugin_dir}/shared/quality-principles.md` once at the start of Phase 2. Include its content as `## quality_principles` in every agent invocation.

### Conditional steps

When a step contains a `**When:**` field, evaluate the condition before executing:
- `config.context.{key}`: check if the `context.{key}` path is defined in sdlc.config.yml. If not defined, skip the agent or step.

When a step contains a `**Skip when:**` field, evaluate the condition. If the condition is true, skip the entire step. Conditions may reference prior agent output (e.g., "create-mocks output contains 'no UI changes'") — read the referenced output file to evaluate.

When a reviewer line within a convergence step has an inline `(when: ...)` condition, evaluate it the same way. Include the reviewer only if the condition is met.

### Persona-reviewer invocation

When a step specifies `persona-reviewer` with a `**Persona selection:**` block:

1. Read the persona selection rules from the step (which personas are always included, which are dynamic).
2. For dynamic selection, read the ticket description and upstream artifacts (PRD, plan, research brief) to determine relevant domains. Selection heuristics:
   - UI/frontend changes → `ux`, `craft`
   - Auth, payments, PII → `security`
   - Database, schema, migrations → `data`
   - Infrastructure, deployment → `devops`
   - API-only, no UI → `qa` instead of `ux`
   - Cross-cutting, multi-system → `tech-lead`, `architect`
   - User-facing flows → `end-user`
   - Process-heavy, multi-team coordination → `sm`
   - Public-facing documentation, API docs, help text → `tech-writer`
3. Read `{loom_plugin_dir}/personas/_universal.md` and the selected persona file `{loom_plugin_dir}/personas/{name}.md`.
4. Spawn `persona-reviewer` with an additional `## persona` section containing: the universal principles first, then a `---` separator, then the persona file content.
5. Each persona-reviewer instance gets the output path defined in the playbook's **Agent output paths:** (e.g., `.loom/artifacts/{ticket_id}/persona-{name}-r{R}.md`).

### Elicit-approach invocation

When spawning `elicit-approach`, include an additional `## method_registry` section containing the content of `{loom_plugin_dir}/shared/elicitation-methods.csv`.

### Retry protocol

When a step's `**On failure:**` block says "retry from step N", re-execute from step N with the additional upstream artifacts specified. Track retry count per step — each step has its own counter that persists across re-entries (if step 14 retries from step 10, step 12's counter is not reset when re-entered). If the step has a `**Max retries:**` field, stop retrying after that many attempts — follow the orchestrator's error handling with `ERROR: Step {step} exceeded max retries ({N}).`

### Verify step handling

For verify steps with `**On failure:**` blocks, after agents return `STATUS: complete`, read the output files and evaluate the failure conditions:
- For agents with VERDICT: check the VERDICT value (`needs-work` = failure condition met).
- For run-tests: check if the `### Assertion Failures` section exists and contains entries.

### Round number placeholders

Playbooks use two distinct round-number placeholders:
- `{R}` — assessment/cross-talk round (increments across cross-talk rounds; used in assess step output paths)
- `{N}` — convergence round (increments across convergence rounds; used in reviewer and feedback output paths)

These are independent counters for different loops and never appear in the same step.

### Playbook execution

Read `{loom_plugin_dir}/playbooks/{type}.md` and follow it. If a step contains convergence fields (`**Agents:**`, `**Verdict logic:**`, `**Max rounds:**`), read `shared/convergence.md` from the Loom plugin directory and follow it for that step. If a step contains cross-talk fields (`**Named agents:**`, `**Max rounds:**` without `**Verdict logic:**`), read `shared/cross-talk.md` and follow it for that step.

## Phase 3: TRANSITION

- `create_pr`: `true` if the playbook declares `pr: true`, otherwise `false`

Read `shared/transition.md` from the Loom plugin directory and follow the "Work transition" section.

## Error handling

If anything fails at any point:
1. Attempt BOTH cleanup operations independently (do not skip step 1b if step 1a fails):
   a. Revert status so the ticket is re-claimable: `task_edit(ticket_id, status="todo")`
   b. Release the lock: `task_edit(ticket_id, assignee=["@released"])`
2. Print the error clearly (include any cleanup failures from step 1)
3. Stop — the human sees the failure in the terminal, so skip appending notes to the ticket (it would duplicate what they already see and clutter the ticket for the next run)
4. The worktree is preserved with whatever artifacts exist
