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

Read `shared/backlog.md` from the Loom plugin directory — every backlog read and mutation in this skill follows it (CLI only, explicit `BACKLOG_CWD`, batched mutations, suppressed echo).

## Phase 1: CLAIM

Read `shared/claim.md` from the Loom plugin directory and follow it.

- Mode: `work`
- Manual ID: `$ARGUMENTS` if the user provided one, otherwise empty (auto-pick)
- `backlog_cwd`: from config

## Phase 2: EXECUTE PLAYBOOK

### Constraints

- Pass output paths to downstream steps instead of reading file contents (downstream agents need the path, not a summary filtered through the orchestrator's interpretation)
- Git commits happen in exactly two places: the convergence checkpoint commits defined in shared/convergence.md, and transition.md. No other mid-playbook git write operations (ad-hoc partial commits break review)

### Progress tracking

The progress file is `{worktree_path}/.loom/artifacts/{ticket_id}/progress.md` — an append-only log that makes failed runs resumable instead of re-running the whole pipeline.

- **On Phase 2 start:** if the file exists, resume — a step is complete when its most recent record says `complete`, its output files still exist and are non-empty, and no later `retry from step {M}` line with `M <=` that step number appears. Begin execution at the first incomplete step and log which steps were skipped. If the file doesn't exist, start from the beginning.
- **After each step completes** (including intake and checkpoint approvals), append: `step {N} — {agent name(s)} — complete — {output path(s)}`. For intake: `intake — complete — .loom/artifacts/{ticket_id}/intake-brief.md`. Record worktree-relative paths (e.g., `.loom/artifacts/{ticket_id}/research.md`) — transition registers every recorded path as a ticket reference. Loop steps (convergence, cross-talk) are recorded only on full completion — a partially finished loop restarts from round 1 on resume.
- **When a retry protocol triggers**, append: `retry from step {N}` (this invalidates completion records for steps >= N, so resume re-executes them).
- **Cross-talk cannot be resumed cold:** it messages live agents by ID, and a new session has none. If the first incomplete step is a cross-talk step, resume from the preceding assess step instead (re-spawning the named agents).
- **On resume of an intake playbook:** if intake is recorded complete but `external-research.md` is missing and the await step has not yet run, re-spawn `research-external` in the background using the intake brief — the original background agent died with the failed session.

### Agent invocation

When a step names an agent to invoke:

1. Read `{loom_plugin_dir}/agents/{name}/AGENT.md`. If not found: `ERROR: Agent '{name}' not found at {path}.`
2. Spawn via Agent tool with `subagent_type` set to `loom:{name}:{name}` (e.g., `loom:implement:implement`, `loom:research-codebase-arch:research-codebase-arch`). If the agent's frontmatter declares `model:`, pass that value as the Agent tool's `model` parameter (the explicit parameter guarantees the tier even when the registry holds a stale plugin snapshot). Include AGENT.md content, `## output_path`, `## worktree_path` (absolute path from claim, e.g., `{project_root}/.loom/worktrees/{ticket_id_lowercase}/`), `## ticket_notes`, `## config` (containing `default_branch`, `rigor`, and context paths), `## quality_principles` (from `shared/quality-principles.md`), and `## upstream_artifacts` when the playbook step specifies upstream paths (marked with **Upstream:** in the step text). When a step has `**Upstream for {agent}:**`, use that for the named agent instead of the default `**Upstream:**`. All paths passed to agents must be absolute, resolved from the worktree root.
3. Check response for STATUS line: `complete`, `failed — {reason}`, or `complete — VERDICT: pass|needs-work`.
4. If failed: stop (error handling below).
5. If complete: no backlog call — the step's progress record (see Progress tracking) is the registration ledger; all recorded output paths are written to the ticket as references in ONE batched edit at transition (shared/transition.md). Exception: convergence and cross-talk steps follow their own recording rules (shared/convergence.md, shared/cross-talk.md) — only final-round outputs are recorded.
5b. Before passing an output_path to a downstream step as upstream_artifacts, verify the file exists and has at least one non-whitespace character. If missing or whitespace-only, treat the producing agent as failed. Exception: upstream paths marked `(optional)` in the playbook are silently skipped when missing — do not treat as failure.
6. For parallel agents: spawn all via multiple Agent tool calls. When a step has `**Agent output paths:**` (keyed per agent name), look up each agent's name in the list and pass its path as `## output_path`. When a step has a single `**Output path:**`, all agents in that step share the same path (only valid for single-agent steps).
7. If a step contains a `**Pre-fetch**` block, execute those instructions before spawning the agent for that step.

### Named agent spawning

When a playbook step marks agents as `(named, parallel)`, spawn each agent with the `name` parameter set to the agent's name (e.g., `assess-inversion`, `persona-pm`). Track the agent ID returned by each Agent tool call — cross-talk rounds resume agents by ID, not by name (agents are no longer addressable by name after completing). For persona-reviewer instances, use the name format `persona-{persona_name}` (e.g., `persona-pm`, `persona-dev`, `persona-security`).

### Cross-talk handling

When a playbook step contains cross-talk fields (`**Named agents:**`, `**Max rounds:**`), read `shared/cross-talk.md` from the Loom plugin directory and follow it for that step. Cross-talk resumes agents from the preceding assess step via SendMessage using their tracked agent IDs — do not respawn them.

### Quality principles

Read `{loom_plugin_dir}/shared/quality-principles.md` once at the start of Phase 2. Include its content as `## quality_principles` in every agent invocation.

### Conditional steps

When a step contains a `**When:**` field, evaluate the condition before executing:
- `config.context.{key}`: check if the `context.{key}` path is defined in sdlc.config.yml. If not defined, skip the agent or step.
- `rigor is {value}`: compare against `{rigor}` from claim (light / standard / full).

When a step contains a `**Skip when:**` field, evaluate the condition. If the condition is true, skip the entire step. Conditions may reference prior agent output (e.g., "create-mocks output contains 'no UI changes'") or `rigor is {value}` — read the referenced output file to evaluate output conditions.

When a reviewer line within a convergence step has an inline `(when: ...)` condition, evaluate it the same way. Include the reviewer only if the condition is met.

When a step contains a `**When rigor is {value}:**` field, apply the modification it describes (reduced agent list, reduced persona selection) only when `{rigor}` matches; otherwise execute the step as written.

### Relevance evaluation

Before spawning an agent, check its AGENT.md frontmatter for a `relevance` field. If present, evaluate conditions against the current worktree state:

- `diff_has: [patterns]` — run `git -C {worktree_path} diff --name-only {default_branch}` and check whether at least one changed file matches any of the glob patterns (shell-style: `*.ts` matches `src/foo.ts`). If the diff is empty (no implementation yet — e.g., plan convergence), the condition passes and the agent runs. If the diff is non-empty and no files match, skip the agent — log "Skipping {agent_name}: diff has no files matching relevance patterns." For convergence steps, a skipped agent counts as `VERDICT: pass` — do not create its output file and do not treat the missing output as a failure.

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
3. Read the selected persona file `{loom_plugin_dir}/personas/{name}.md`.
4. Spawn `persona-reviewer` with an additional `## persona` section containing the persona file content (quality principles are already injected as `## quality_principles`, like every agent).
5. Each persona-reviewer instance gets the output path defined in the playbook's **Agent output paths:** (e.g., `.loom/artifacts/{ticket_id}/persona-{name}-r{R}.md`).

### Elicit-approach invocation

When spawning `elicit-approach`, include an additional `## method_registry` section containing the content of `{loom_plugin_dir}/shared/elicitation-methods.csv`.

### Retry protocol

When a step's `**On failure:**` block says "retry from step N", re-execute from step N with the additional upstream artifacts specified. Track retry count per step — each step has its own counter. When a retry is triggered by a DIFFERENT step's `**On failure:**` (e.g., step 14 retries from step 10), reset all retry counters for steps between N and the triggering step (inclusive) — the new implementation makes prior retry counts irrelevant. If the step has a `**Max retries:**` field, stop retrying after that many attempts — follow the orchestrator's error handling with `ERROR: Step {step} exceeded max retries ({N}).`

### Verify step handling

For verify steps with `**On failure:**` blocks, after agents return `STATUS: complete`, read the output files and evaluate the failure conditions:
- For agents with VERDICT: check the VERDICT value (`needs-work` = failure condition met).
- For run-tests: check if the `### Assertion Failures (if any)` section exists and contains entries.

When a verify step declares scoped optimization fields (`**Test-only optimization:**`, `**UI-only optimization:**`) and a retry is triggered, follow "Scoped retry convergence" in `shared/convergence.md` when re-running the convergence step.

### Round number placeholders

Playbooks use two distinct round-number placeholders:
- `{R}` — assessment/cross-talk round (increments across cross-talk rounds; used in assess step output paths)
- `{N}` — convergence round (increments across convergence rounds; used in reviewer and feedback output paths)

These are independent counters for different loops and never appear in the same step.

### Intake, checkpoint, and await steps

If the playbook contains an `## Intake` section, read `shared/intake.md` from the Loom plugin directory before executing step 1 and follow it. It covers the intake conversation, `**Checkpoint:**` fields, and await steps (steps with an `**Output path:**` but no `**Agent:**`) — these mechanisms only occur in intake playbooks.

### Playbook execution

Read `{loom_plugin_dir}/playbooks/{type}.md` and follow it. If a step contains convergence fields (`**Agents:**`, `**Verdict logic:**`, `**Max rounds:**`), read `shared/convergence.md` from the Loom plugin directory and follow it for that step. If a step contains cross-talk fields (`**Named agents:**`, `**Max rounds:**` without `**Verdict logic:**`), read `shared/cross-talk.md` and follow it for that step.

## Phase 3: TRANSITION

- `create_pr`: `true` if the playbook declares `pr: true`, otherwise `false`

Read `shared/transition.md` from the Loom plugin directory and follow the "Work transition" section.

## Error handling

If anything fails at any point:
1. Attempt ALL cleanup operations independently (do not skip later steps if earlier ones fail):
   a. Revert status and release the lock in ONE batched edit (shared/backlog.md):
      ```bash
      ERR=$(BACKLOG_CWD="{backlog_cwd}" backlog task edit {ticket_id} -s todo -a @released --plain 2>&1 >/dev/null)
      ```
   b. If a background agent was spawned during intake and has not completed, log "Background agent may still be running — its output will be picked up or re-spawned on resume."
2. Print the error clearly (include any cleanup failures from step 1)
3. Stop — the human sees the failure in the terminal, so skip appending notes to the ticket (it would duplicate what they already see and clutter the ticket for the next run)
4. The worktree, artifacts, and progress file are preserved — the next `/loom:work` run on this ticket resumes from the first incomplete step (see Progress tracking)
