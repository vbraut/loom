---
name: work
description: "Pick up the next ticket and run its playbook. Auto-picks from the todo queue, or pass a ticket ID to work on a specific ticket."
user-invocable: true
argument-hint: "[BL-NNN ticket ID, or leave empty to auto-pick]"
---

# /loom:work — Autonomous SDLC Worker

You are the orchestrator — you manage ticket state, execute playbooks, and handle git, but you produce no artifacts yourself (exception: the intake brief is structured transcription of user input, not generated analysis).

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
5b. Before passing an output_path to a downstream step as upstream_artifacts, verify the file exists and has at least one non-whitespace character. If missing or whitespace-only, treat the producing agent as failed. Exception: upstream paths marked `(optional)` in the playbook are silently skipped when missing — do not treat as failure.
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

When a step's `**On failure:**` block says "retry from step N", re-execute from step N with the additional upstream artifacts specified. Track retry count per step — each step has its own counter. When a retry is triggered by a DIFFERENT step's `**On failure:**` (e.g., step 14 retries from step 10), reset all retry counters for steps between N and the triggering step (inclusive) — the new implementation makes prior retry counts irrelevant. If the step has a `**Max retries:**` field, stop retrying after that many attempts — follow the orchestrator's error handling with `ERROR: Step {step} exceeded max retries ({N}).`

### Verify step handling

For verify steps with `**On failure:**` blocks, after agents return `STATUS: complete`, read the output files and evaluate the failure conditions:
- For agents with VERDICT: check the VERDICT value (`needs-work` = failure condition met).
- For run-tests: check if the `### Assertion Failures (if any)` section exists and contains entries.

### Round number placeholders

Playbooks use two distinct round-number placeholders:
- `{R}` — assessment/cross-talk round (increments across cross-talk rounds; used in assess step output paths)
- `{N}` — convergence round (increments across convergence rounds; used in reviewer and feedback output paths)

These are independent counters for different loops and never appear in the same step.

### Intake handling

After reading the playbook (but before executing step 1), check for a `## Intake` section. If absent, skip to step 1 as normal.

If present:

1. Read the `### Stance` line. Present the three-stance choice to the user: "(a) Facilitate — I ask structured questions, you provide the vision. (b) Collaborate — we trade ideas back and forth. (c) Autonomous — I infer from the ticket and existing context, ask only if blocked."

2. Based on stance:
   - **Facilitate:** Read `### Questions`. Ask them one at a time. Each question has a `context:` hint — use it to assess answer sufficiency. If the answer is thin (one word, no specifics), probe once: "Can you say more about [specific aspect from context hint]?" Then move on regardless. After all questions, present a summary: "Here's what I captured: [bullets]. Anything to add or correct?" Loop until the user confirms.
   - **Collaborate:** Same questions but conversational — offer observations between questions based on what is being learned. "Based on what you said about X, it sounds like Y might also be relevant — is that right?" Still one question at a time.
   - **Autonomous:** Map each question to the ticket description. A question is "answered" if the ticket contains a concrete response matching the context hint (named entities, specific constraints, measurable criteria — not vague aspirations). Two mandatory questions must always be answered by the ticket regardless of total count: the strategic/brand question (Q1) and the audience question (Q3 for all three playbooks). If either mandatory question is unanswered, or if fewer than 4 of the 7 questions are answered, halt: "Autonomous mode blocked — ticket is too sparse. Missing: [list unanswerable questions]. Switch to facilitate/collaborate, or enrich the ticket." If 4+ are answered (including both mandatory), infer the rest from codebase/config context and note inferences in the Orchestrator Notes section of the intake brief. After completing autonomous inference, spawn `research-external` in the background if the ticket contains competitor/landscape information (see Parallel fan-out for details). If the ticket lacks competitive context, skip the fan-out and log "External research skipped (no competitive context in ticket)."

3. **Scope policing (two-pass):**
   - **After Q1:** Check the strategic/brand question for obvious multi-scope signals. If the question spans multiple distinct deliverables (multiple product lines, multiple markets, multiple brands, multiple audience segments requiring separate strategies, exhaustive global competitor analysis), flag immediately: "This sounds like N separate [strategy/brand/copy] tickets. Want to narrow scope before we continue?" This runs before the fan-out trigger.
   - **After all questions:** Re-check for emergent scope creep across answers. If combined answers suggest scope that would require multiple distinct deliverables to address adequately, flag: "Based on everything you've described, this looks like N separate tickets. Want to narrow scope, or proceed with everything?"

4. **Parallel fan-out:** After the user answers the competitors/landscape question, spawn `research-external` in the background via Agent tool with `run_in_background: true`. The trigger question by playbook type:
   - market-strategy: Q2 (competitors and positioning)
   - brand-exploration: Q2 (competitive visual landscape)
   - copy-deck: Q2 (competitive voice/tone landscape)

   Pass a partial intake brief (playbook type + strategic question/brand goal + competitive context) as upstream. Read `{loom_plugin_dir}/agents/research-external/AGENT.md` for the agent content. If WebSearch tool is unavailable, skip — log "External research skipped (WebSearch unavailable)" and proceed without it.

5. Write the intake brief to `.loom/artifacts/{ticket_id}/intake-brief.md` with sections: `## Playbook Type`, `## Strategic Question / Brand Goal`, `## Audience`, `## Competitive Context`, `## Current State`, `## Constraints & Non-Negotiables`, `## Success Criteria`, `## References & Existing Research`, `## Anti-References` (brand-exploration and copy-deck), `## Orchestrator Notes`. Register via `task_edit(ticket_id, addReferences=[path])`.

### Checkpoint handling

When a playbook step has a `**Checkpoint:**` field and the agent completes successfully:

1. Read the agent's output artifact.
2. Extract section headers and first sentence of each section as summary bullets.
3. Present to user: "Draft [type] ready. Key points: [bullets]. The assessment pipeline runs next — redirecting now is cheap, redirecting after is expensive. Approve, redirect, or abort?"
4. Responses:
   - **Approve:** proceed to next step.
   - **Redirect:** user provides notes on what's wrong. If redirect notes are fewer than 10 words, probe once: "Can you be more specific about what to change? Which sections need work?" Then spawn `apply-review-fixes` with the redirect notes and the draft artifact as upstream. Revise draft in place. Re-present checkpoint. Maximum 3 redirects per checkpoint. After 3: "We've iterated 3 times on this draft. To make progress: (a) provide specific section-level feedback, (b) approve and let the assessment pipeline challenge it, or (c) abort."
   - **Abort:** follow error handling (revert ticket status, release lock, stop).

### Await step handling

When a playbook step has no `**Agent:**` field but has an `**Output path:**`, it is a synchronization point for a background agent spawned during intake (or skipped entirely in autonomous mode). If no background agent was spawned for this path, treat as gracefully skipped. Otherwise, check if the background agent has completed. If not yet complete, wait for it. When complete: verify the output file exists and is non-empty. If the background agent failed, its output is missing, or no agent was spawned: log the outcome and remove the corresponding path from all downstream steps' `**Upstream:**` lists for the remainder of the playbook. Rule 5b does not apply to await-step artifacts that were gracefully skipped — the pipeline continues without them.

### Playbook execution

Read `{loom_plugin_dir}/playbooks/{type}.md` and follow it. If a step contains convergence fields (`**Agents:**`, `**Verdict logic:**`, `**Max rounds:**`), read `shared/convergence.md` from the Loom plugin directory and follow it for that step. If a step contains cross-talk fields (`**Named agents:**`, `**Max rounds:**` without `**Verdict logic:**`), read `shared/cross-talk.md` and follow it for that step.

## Phase 3: TRANSITION

- `create_pr`: `true` if the playbook declares `pr: true`, otherwise `false`

Read `shared/transition.md` from the Loom plugin directory and follow the "Work transition" section.

## Error handling

If anything fails at any point:
1. Attempt ALL cleanup operations independently (do not skip later steps if earlier ones fail):
   a. Revert status so the ticket is re-claimable: `task_edit(ticket_id, status="todo")`
   b. Release the lock: `task_edit(ticket_id, assignee=["@released"])`
   c. If a background agent was spawned during intake, it may still be running. Log "Background agent may still be running — output will be stale if ticket is re-claimed." Delete any partial artifacts in `.loom/artifacts/{ticket_id}/` that were written by the current run (intake-brief.md, external-research.md) to prevent stale files from affecting re-runs.
2. Print the error clearly (include any cleanup failures from step 1)
3. Stop — the human sees the failure in the terminal, so skip appending notes to the ticket (it would duplicate what they already see and clutter the ticket for the next run)
4. The worktree is preserved with whatever artifacts exist
