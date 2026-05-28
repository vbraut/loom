---
task: "Implement Step 3: code-fix playbook — vertical slice"
base_branch: main
status: approved
approved: 2026-05-27T14:32:00
created: 2026-05-26
---

# Implementation Plan: Step 3 — code-fix Playbook Vertical Slice

## Executive Summary

Step 3 builds the first end-to-end playbook proving the full orchestrator loop: claim → playbook execution → convergence → transition. The deliverables are `playbooks/code-fix.md`, seven agents, a convergence handler as a shared module (`shared/convergence.md`), and updates to the orchestrator's agent invocation protocol.

A four-expert debate (Architect, Developer, QA, Tech Lead) identified convergence loop semantics as the critical gap — the orchestrator's Phase 2 ("read playbook and follow it") is insufficient for loops requiring state tracking. All four experts agreed on the solution: a convergence handler in `shared/convergence.md` with explicit imperative instructions. This preserves playbook authority — the playbook declares convergence parameters, the shared module implements the loop mechanics.

Ten elicitation methods refined the design further. The key findings: feedback routing uses output_path files directly (not ticket_notes for content — overflow risk with multi-round feedback); code-modifying agents edit the worktree AND write summaries to output_path; research-codebase-arch needs a 100-line budget; reviewers must produce structured findings with file:line references and severity; apply-review-fixes has a minimal-diff constraint; and run-tests handles no-test-suite gracefully with a warning note for the human gate.

An alignment gate (3 reviewers, 3 rounds) passed with 2 consecutive clean rounds. A post-gate study of two reference implementations — the `my-dev` personal skill and the reign production SDLC — identified four high-value patterns to adopt: a simplification reviewer in the convergence loop (reign uses this in every review gate to catch scope bloat from iterative fixes), agent timeout/retry protocol, secrets scanning before transition, and absolute path discipline for worktree-based agents. These are the "level-up" over the reference systems — Loom's playbook-driven composition and shared convergence module are already more extensible than either reference, and these additions bring the operational rigor of the production system.

The implementation is 15 steps across 4 phases. Phase 1 creates the shared convergence module, playbook, and updates infrastructure. Phase 2 creates the seven agents. Phase 3 updates validation. Phase 4 runs final checks. Confidence: **High** — the orchestrator skeleton and agent template are proven from steps 1-2; this step fills them with the first real content.

## Summary

Create the code-fix playbook (`playbooks/code-fix.md`), seven agents under `agents/`, and a convergence handler (`shared/convergence.md`). Update supporting files: both orchestrators (agent invocation protocol), `templates/skill-authoring.md` (reviewer output rules), `CLAUDE.md` (boundary clarification), and `scripts/validate.sh` (shared module check, playbook-agent cross-check).

The playbook flow is: `research-codebase-arch → implement → [CONVERGENCE: requirements-reviewer + regression-analyst + simplification-reviewer → apply-review-fixes] → run-tests`.

## Technical Approach

### Architecture

The playbook is a structured Markdown file the AI orchestrator reads and follows step by step. Each step names an agent, its inputs (upstream output paths), and its output path. The convergence block is a section with required fields that `shared/convergence.md` processes — the orchestrator reads this shared module when it encounters a convergence block, just as it reads `shared/claim.md` for Phase 1 and `shared/transition.md` for Phase 3.

Agents are Markdown instruction files (`AGENT.md`) spawned by the orchestrator as Claude subagents. Each receives the AGENT.md content plus context sections (`## output_path`, `## ticket_notes`, `## upstream_artifacts`). Doer agents modify the worktree and write change summaries to output_path. Reviewer agents write structured findings to output_path and include a VERDICT in their STATUS line.

### Convergence block format

The `## Convergence` section in a playbook uses bold-label key-value pairs:

```
## Convergence

**Agents:** requirements-reviewer, regression-analyst, simplification-reviewer (parallel)
**Verdict logic:** AND
**Max rounds:** 3
**On needs-work:** apply-review-fixes
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Convergence: {round} rounds, unresolved feedback — see artifacts."

**Reviewer output paths:**
- requirements-reviewer: `.loom/artifacts/{ticket_id}/requirements-review-r{N}.md`
- regression-analyst: `.loom/artifacts/{ticket_id}/regression-r{N}.md`
- simplification-reviewer: `.loom/artifacts/{ticket_id}/simplification-r{N}.md`

**Feedback agent output path:** `.loom/artifacts/{ticket_id}/fixes-r{N}.md`
```

`{N}` is replaced by the current round number at runtime. `{ticket_id}` is the ticket being worked on.

### Design decisions

1. **Convergence handler as a shared module, not duplicated in orchestrators.** Both `skills/work/SKILL.md` and `skills/review/SKILL.md` reference `shared/convergence.md` via a one-line instruction: "If the playbook contains a `## Convergence` section, read `shared/convergence.md` and follow it." This is consistent with how `shared/claim.md` and `shared/transition.md` work — the orchestrator delegates to a shared module for complex behavior. Single source of truth; no risk of the two orchestrators drifting.

2. **Structured Markdown playbook format, not YAML.** Playbooks use bold-label key-value pairs within standard Markdown sections. This keeps playbooks human-readable and consistent with the rest of the framework (all `.md` files). The convergence handler (Claude reading these fields) does not need a formal parser — it reads the `## Convergence` heading, then extracts the bold-labeled values. This is standard AI instruction-following, same as the orchestrator reading any other Markdown section. The format is shown above.

3. **Feedback routing via output_path files, not ticket_notes.** When convergence loops, the handler passes reviewer output_path references to apply-review-fixes as `## upstream_artifacts`. ticket_notes gets a one-line index per round only. This prevents context overflow — three rounds of full reviewer feedback in ticket_notes would consume ~1500 tokens of stale data.

4. **Code-modifying agents work in the worktree AND write to output_path.** The boundary rule constrains framework-level side effects (no backlog writes, no git operations). Code changes in the worktree ARE the agent's primary work — "work products" means files the agent is instructed to create or modify as part of its task. The output_path artifact is a tracking summary for the orchestrator and downstream agents.

5. **Three parallel reviewers, each with a distinct lens.** requirements-reviewer evaluates fix quality and correctness; regression-analyst checks for unintended side effects; simplification-reviewer catches scope bloat introduced by iterative fixes. Running all three in parallel adds negligible cost. This pattern is proven in the reign production SDLC, where simplification review is mandatory in every review gate — without it, convergence loops tend to accumulate complexity as apply-review-fixes patches issues by adding code rather than simplifying. Each reviewer is focused and reusable — step 5 (code-implementation) reuses all three.

6. **run-tests outside the convergence loop.** The convergence loop wraps reviewers + apply-review-fixes. run-tests is a final validation gate after convergence. If tests fail, the orchestrator's existing error handling kicks in. Keeping tests outside convergence avoids doubling the loop complexity for marginal benefit — reviewers should catch issues that would cause test failures.

7. **research-codebase-arch output format fixed for this step.** The output has four required sections (architecture, key files, patterns, build/test commands) with a 100-line budget. Future steps may extend this format; this step implements these four sections. If a section needs more than its share, the agent prioritizes: key files first (most actionable for downstream agents), then architecture, then patterns, then build/test. Truncation strategy: drop least-relevant items within each section, never drop a section entirely.

8. **All-pass exits convergence on any round.** If all reviewers return `pass` on round 1, convergence exits immediately — apply-review-fixes is never invoked. This isn't a special "shortcut" — it's what happens naturally when the verdict logic is satisfied. No special-case step needed.

9. **Failure takes precedence over needs-work.** When parallel reviewer agents run, one may fail while another returns needs-work. The convergence handler checks for failures first. If any agent returned `STATUS: failed`, convergence stops immediately and the orchestrator's error handling takes over. This prevents the handler from routing to apply-review-fixes with incomplete review data.

10. **Explicit STATUS parsing.** The convergence handler finds the last line of an agent's response that begins exactly with `STATUS: ` (including the space). VERDICT is extracted from the `VERDICT: pass` or `VERDICT: needs-work` suffix. The agent template specifies the exact format; the handler matches it literally. Matching is case-sensitive — agents must use the exact casing from the template (`STATUS`, `VERDICT`, `pass`, `needs-work`, `complete`, `failed`). Case mismatches are treated as missing STATUS lines.

11. **Output path validation before downstream pass.** Before passing an output_path to a downstream agent (as `## upstream_artifacts`), the orchestrator verifies the file exists and is non-empty (at least one non-whitespace character). If missing or empty, it treats the producing agent as failed. This catches silent agent failures where STATUS says `complete` but no artifact was written. This validation applies in two scopes: the orchestrator's agent invocation protocol validates between sequential playbook steps; the convergence handler validates within its loop (reviewer output paths before passing to the feedback agent). Same principle, different locations — convergence owns its internal validation.

12. **Simplification reviewer in convergence.** Adopted from the reign production SDLC, where simplification review is mandatory in every review gate. The simplification-reviewer evaluates whether the fix is over-engineered, whether apply-review-fixes introduced unnecessary complexity, and whether standard library or framework features could replace custom code. Its findings use the same structured format as other reviewers (file:line, severity, description, recommendation). This prevents the convergence loop from accreting complexity — a known failure mode where each fix round adds code to address findings, and the accumulated patches become harder to review than the original bug.

13. **Agent timeout with single retry.** If a spawned agent does not respond within a reasonable time (determined by the Claude subagent runtime), the convergence handler re-spawns it once. If the retry also fails, the agent is treated as failed. This prevents a hung agent from blocking the entire pipeline. The retry handles transient failures (context window exceeded on first attempt, temporary API issues); persistent failures are caught by the second attempt and routed to error handling.

14. **Secrets scanning in run-tests.** Before writing its final report, run-tests scans the worktree diff for accidentally committed secrets (API keys, tokens, credentials, private keys). Any findings are included in the test report with severity `must-fix`. This is adopted from my-dev, which runs secrets scanning before review. Placing it in run-tests is natural — it's the last agent before transition, and secrets are a "test" in the broadest sense (something that must pass before the code reaches a human reviewer).

15. **Absolute path discipline for worktree agents.** The orchestrator passes the worktree's absolute path in the agent invocation context (as part of `## output_path` and `## upstream_artifacts` — these paths are already resolved to absolute paths by the orchestrator). Agents that modify code or read files must use these absolute paths, not relative paths. This prevents path confusion when an agent's working directory differs from the worktree root — a failure mode observed in the my-dev reference implementation that was resolved by explicit absolute path passing.

### Patterns reused

- Agent AGENT.md template from `templates/skill-authoring.md` (frontmatter, constraints, process, output, STATUS protocol)
- Agent invocation protocol from `skills/work/SKILL.md` Phase 2 (read AGENT.md, spawn, check STATUS, register output)
- Error handling from `skills/work/SKILL.md` (revert status, release lock, preserve worktree)
- Playbook routing from `shared/claim.md` step 2 (type label → playbook path)
- Shared module pattern from `shared/config.md`, `shared/claim.md`, `shared/transition.md`

## Risks & Open Questions

1. **AI interpretation variance.** The convergence handler is imperative instructions for Claude, not deterministic code. Different sessions may interpret round tracking or verdict checking slightly differently. Mitigation: use explicit numbered steps with named state ("set round = 1", "increment round") and unambiguous conditionals. STATUS parsing rule is documented.

2. **apply-review-fixes quality.** This agent applies feedback from two reviewers to code it didn't write. If feedback is vague or contradictory, fixes may be poor. Mitigation: reviewers must produce structured findings (file:line, severity, recommendation); apply-review-fixes has a minimal-diff constraint and conflict resolution rules; max rounds is the safety net.

3. **research-codebase-arch completeness.** As the first agent in the chain, a bad research brief degrades everything downstream. Mitigation: implement agent also has full codebase access and can explore beyond what research found. Research is context, not constraint.

4. **Convergence loop token cost.** Each round spawns 3 reviewers + 1 fixer. Three rounds = 12 agent invocations plus the initial implement. For complex bugs this is appropriate; for trivial fixes it's wasteful. Acceptable trade-off — reviewers run in parallel (wall-clock cost is ~1 reviewer), and the human reviews the output regardless.

5. **addReferences MCP semantics.** The plan assumes `addReferences` accumulates (each call adds to existing references). If the MCP method replaces instead, round N output paths would overwrite round N-1 references. Mitigation: verify behavior during implementation. If it replaces, accumulate paths in the orchestrator and pass the full list on each call.

6. **research-codebase-arch format scope.** The output format is designed for code-fix; step 5 (code-implementation) may need different research. If so, step 5 creates a new research agent — reuse is a bonus, not a constraint. The four-section format is fixed for this step's implementation; future steps may extend it with additional sections.

## Recommendations & Considerations

1. **validate.sh cross-check is best-effort.** The playbook-agent cross-check scans for agent names matching `agents/` directory names. It catches missing agents but won't catch agent names embedded in prose that don't match directory names. This is sufficient for structural validation — behavioral correctness is verified by end-to-end testing.

2. **The `.gitkeep` files in `agents/` and `playbooks/` should be removed.** They were placeholders for empty directories. Bundle removal with the creation of files in those directories (same step, not a separate step).

## Files to Modify / Create

### New files

- **NEW** `shared/convergence.md` — Convergence loop handler. Read by both orchestrators when a playbook contains `## Convergence`.
- **NEW** `playbooks/code-fix.md` — The playbook defining the code-fix workflow with numbered steps and a convergence block.
- **NEW** `agents/research-codebase-arch/AGENT.md` — Doer agent: explores codebase architecture, produces a context brief for downstream agents.
- **NEW** `agents/implement/AGENT.md` — Doer agent: reads research brief and ticket notes, fixes the bug in the worktree, writes change summary.
- **NEW** `agents/requirements-reviewer/AGENT.md` — Reviewer agent: evaluates fix quality, correctness, completeness. Returns VERDICT.
- **NEW** `agents/regression-analyst/AGENT.md` — Reviewer agent: checks for unintended side effects and behavioral changes. Returns VERDICT.
- **NEW** `agents/simplification-reviewer/AGENT.md` — Reviewer agent: checks for over-engineering, unnecessary complexity, and scope bloat in the fix. Returns VERDICT.
- **NEW** `agents/apply-review-fixes/AGENT.md` — Doer agent: reads reviewer feedback, applies targeted fixes to the worktree. Minimal-diff constraint.
- **NEW** `agents/run-tests/AGENT.md` — Doer agent: discovers and runs the project's test suite, scans for secrets, reports results.

### Modified files

- `skills/work/SKILL.md` — Add convergence reference to Phase 2. Add `## upstream_artifacts` to agent invocation protocol. Add output_path validation step. Add absolute path discipline rule.
- `skills/review/SKILL.md` — Same four changes as work/SKILL.md.
- `templates/skill-authoring.md` — Add "Doer vs. reviewer output" section clarifying STATUS line rules, output_path semantics for code-modifying agents, and reviewer findings format contract.
- `CLAUDE.md` — Clarify boundary rule 2: "Agents write tracking artifacts to `output_path` and work products to the worktree (files the agent is instructed to create or modify as part of its task) — no backlog writes, no git operations."
- `scripts/validate.sh` — Add `convergence` to shared modules check. Add playbook-agent cross-check section.

### Removed files

- `agents/.gitkeep` — Removed in the same step as agent directory creation.
- `playbooks/.gitkeep` — Removed in the same step as playbook creation.

## Implementation Steps

### Phase 1: Shared module, playbook, and infrastructure

**Step 1. Create `shared/convergence.md`.**

The convergence handler, following the shared module style from `templates/skill-authoring.md` (imperative checklist, numbered steps, no preamble beyond a one-line purpose).

Purpose line: "Handle convergence loops declared in playbooks."

Steps (imperative, ~30 lines):

1. Parse the `## Convergence` section from the playbook. Extract: **Agents** (names and parallel flag), **Verdict logic** (AND or OR), **Max rounds** (integer), **On needs-work** (feedback agent name), **On max rounds** (instruction text), **Reviewer output paths** (per-agent path templates with `{N}` placeholder), **Feedback agent output path** (path template with `{N}` placeholder).

2. Set `round` to 1. Maintain this variable throughout the convergence loop — do not reset it.

3. Spawn each reviewer agent listed in **Agents**. For parallel agents, spawn all via multiple Agent tool calls in a single response. Resolve all path placeholders: replace `{ticket_id}` with the current ticket ID and `{N}` with the current `round` value. Pass fully resolved absolute paths to agents. If a spawned agent does not respond (timeout), re-spawn it once. If the retry also fails, treat the agent as `STATUS: failed — agent timeout after retry`.

4. For each agent response, parse the STATUS line: find the last line beginning exactly with `STATUS: `. If it contains `VERDICT: `, extract the verdict value (`pass` or `needs-work`). If the STATUS line has no VERDICT suffix (e.g., a doer agent mistakenly listed as a reviewer), treat as `STATUS: failed — missing VERDICT in reviewer response`. If no STATUS line is found at all, treat as `STATUS: failed — no STATUS line in response`.

5. Check for failures first. If any agent returned `STATUS: failed`, stop — follow the orchestrator's error handling. Do not proceed to verdict evaluation or the feedback agent. (Agent failure takes precedence over needs-work verdicts from other parallel agents.)

6. Evaluate the verdict logic. AND: all agents must have `VERDICT: pass`. OR: at least one agent must have `VERDICT: pass`.

7. If verdict is satisfied: convergence is complete. Register reviewer output paths via `addReferences`. Return to the orchestrator — it continues with the next playbook step after the convergence block.

8. If verdict is not satisfied and `round` is less than **Max rounds**: verify each reviewer output_path file exists and has at least one non-whitespace character (if missing or whitespace-only, treat the reviewer as failed — go to step 5 handling). Spawn the feedback agent from **On needs-work**, passing all reviewer output_path references as `## upstream_artifacts`. Use the feedback agent output path template with `{N}` = current round. When the feedback agent completes, verify its output_path exists. Register all output paths from this round via `addReferences`. Increment `round`. Go to step 3.

9. If `round` equals or exceeds **Max rounds** and verdict is not satisfied: follow the **On max rounds** instruction from the convergence block (typically: append a note to ticket_notes). Return to the orchestrator — it continues with the next playbook step.

**Step 2. Update `skills/work/SKILL.md` — convergence reference and invocation protocol.**

Four changes:

(a) After "Read `{loom_plugin_dir}/playbooks/{type}.md` and follow it," add: "If the playbook contains a `## Convergence` section, read `shared/convergence.md` from the Loom plugin directory and follow it."

(b) In the "Agent invocation" protocol, update step 2: include `## upstream_artifacts` when the playbook step specifies upstream paths (the playbook step text says "Upstream: ..." — this is how the orchestrator knows which steps have upstreams). The orchestrator resolves all placeholders (`{ticket_id}`, `{N}`) before passing paths. Format:

```
## upstream_artifacts
- research brief: .loom/artifacts/BL-042/research.md
```

This is prompt context — the agent reads it as part of its instructions, not a file to parse. Same mechanism as `## output_path` and `## ticket_notes`.

(c) After step 5 (register output), add step 5b: "Before passing an output_path to a downstream step as upstream_artifacts, verify the file exists and has at least one non-whitespace character. If missing or whitespace-only, treat the producing agent as failed."

(d) Add to the agent invocation protocol: "All paths passed to agents (output_path, upstream_artifacts) must be absolute paths resolved from the worktree root. The orchestrator resolves all placeholders and relative paths before passing them to agents."

**Step 3. Update `skills/review/SKILL.md` — same four changes.**

Identical to step 2. The review orchestrator's Phase 2 has the same agent invocation protocol and needs the same convergence reference. Review playbooks (step 4 of the master plan) may include convergence blocks.

**Step 4. Create `playbooks/code-fix.md`.**

Remove `playbooks/.gitkeep` in the same step.

The playbook has these sections:

A header line stating the playbook name (`code-fix`) and that it requires `pr: true` for transition.

**Steps section** with four numbered entries plus a convergence block:

1. **Research** — Agent: `research-codebase-arch`. Input: ticket_notes (bug description). Output path: `.loom/artifacts/{ticket_id}/research.md`. Purpose: understand the codebase architecture, locate the bug, identify relevant files and patterns.

2. **Implement** — Agent: `implement`. **Upstream:** research output path (`.loom/artifacts/{ticket_id}/research.md`). Output path: `.loom/artifacts/{ticket_id}/changes.md`. Purpose: fix the bug in the worktree, write a change summary.

3. **Review** — The `## Convergence` block (using the format shown in "Convergence block format" above). Three parallel reviewers: requirements-reviewer, regression-analyst, simplification-reviewer. **Upstream:** research output path (`.loom/artifacts/{ticket_id}/research.md`) and implement change summary (`.loom/artifacts/{ticket_id}/changes.md`) — reviewers receive architecture context and change details alongside the worktree. Reviewer output paths: `.loom/artifacts/{ticket_id}/requirements-review-r{N}.md`, `.loom/artifacts/{ticket_id}/regression-r{N}.md`, and `.loom/artifacts/{ticket_id}/simplification-r{N}.md`. Feedback agent output path: `.loom/artifacts/{ticket_id}/fixes-r{N}.md`. On max rounds: append note and continue.

4. **Test** — Agent: `run-tests`. Input: none (runs from worktree). Output path: `.loom/artifacts/{ticket_id}/test-results.md`.

5. **Completion** — Declare `pr: true` so the orchestrator's Phase 3 creates a PR.

**Pre-completion checklist** (the orchestrator verifies all items before proceeding to Phase 3):
- [ ] research-codebase-arch produced output
- [ ] implement produced output and modified worktree
- [ ] Convergence ran (passed or hit max rounds with note)
- [ ] run-tests produced output (with test results and secrets scan)
- [ ] All output paths registered via addReferences

**Step 5. Update `templates/skill-authoring.md`.**

Add a new section after "Agent template" titled "## Doer vs. reviewer output". Content:

- **Doer agents** (e.g., implement, apply-review-fixes, run-tests) produce work products in the worktree (code changes, test runs) and write a tracking summary to output_path. Their STATUS line is `complete` or `failed — {reason}`. They never return VERDICT.

- **Reviewer agents** (e.g., requirements-reviewer, regression-analyst) evaluate artifacts and produce structured findings at output_path. Their STATUS line includes a VERDICT: `complete — VERDICT: pass` or `complete — VERDICT: needs-work`.

- **Reviewer findings format.** Each finding in a reviewer's output must include: (1) file path (relative to the worktree root) and line number, (2) severity — `must-fix` (blocks pass), `should-fix` (strongly recommended), or `nit` (optional improvement), (3) description of the issue, (4) concrete recommendation. File paths must be worktree-relative (e.g., `src/utils/config.ts:42`, not absolute paths) so apply-review-fixes can locate files consistently regardless of where the worktree is mounted. This structure is required because apply-review-fixes uses severity to prioritize fixes and file:line to locate the code. Vague findings like "needs improvement" are not actionable.

- **output_path semantics**: output_path is the agent's tracking artifact registered to the ticket via `addReferences`. Code-modifying agents (doers) also edit source files in the worktree — this is their primary work, not a side effect. The boundary rule applies to framework-level operations: no backlog writes, no git operations, no framework file modifications.

**Step 6. Clarify CLAUDE.md boundary rule 2.**

Change the current rule 2 from:
"Agents write to `output_path` only — no backlog writes, no git operations."

To:
"Agents write tracking artifacts to `output_path` and work products to the worktree (files the agent is instructed to create or modify as part of its task) — no backlog writes, no git operations."

This clarifies that code-modifying agents are expected to edit source files in the worktree. "Work products" is defined in parentheses to prevent overly broad interpretation.

### Phase 2: Agents

All agents follow the template in `templates/skill-authoring.md`. Each has YAML frontmatter (`name`, `description`, optionally `tools` and `model`), a one-sentence role, Constraints section (hardest first, positive framing), Process section (imperative steps), and Output section with STATUS line format. Each AGENT.md stays under the 200-line budget.

**Step 7. Create `agents/research-codebase-arch/AGENT.md`.**

Remove `agents/.gitkeep` in the same step.

Frontmatter: name `research-codebase-arch`, description explaining it explores project architecture and produces a context brief for downstream agents.

Role: Explores the project's architecture, locates relevant code for the ticket, and produces a structured context brief.

Constraints (key ones):
- Output must be under 100 lines (downstream agents receive this as context — larger briefs push their own instructions toward context limits). If a section needs more than its share, prioritize: key files first, then architecture, then patterns, then build/test. Truncate within sections by dropping least-relevant items — never omit a section entirely.
- Focus on what downstream agents need: architecture patterns, key files to modify, build/test commands, relevant conventions.
- Read actual code — no assumptions about project structure.
- Write to output_path only (this agent doesn't modify source code).

Process: Read ticket_notes for bug description → explore project root for structure → identify architecture patterns → locate files relevant to the bug → discover build and test commands → write structured brief to output_path.

Output format (four required sections — future steps may extend):
1. Architecture Overview — key components, framework, dependencies
2. Key Files — files most relevant to the ticket, with brief descriptions
3. Patterns — coding conventions, common patterns, idioms found in the codebase
4. Build & Test — exact commands to build, lint, and test the project

STATUS: `complete` or `failed — {reason}`.

**Step 8. Create `agents/implement/AGENT.md`.**

Frontmatter: name `implement`, description explaining it fixes bugs by modifying source code in the worktree.

Role: Reads the research brief and ticket description, then fixes the bug in the worktree.

Constraints (key ones):
- Read the research brief at the upstream_artifacts path before making changes (it contains architecture context, key files, and conventions).
- Only modify files directly related to the bug — no drive-by refactors, no scope creep.
- Follow the project's existing patterns and conventions (as documented in the research brief).
- Write a change summary to output_path listing each file modified and what changed.

Process: Read upstream research brief → read ticket_notes for bug description → locate the bug → implement the fix → verify the fix addresses the described issue → write change summary to output_path.

STATUS: `complete` or `failed — {reason}`.

**Step 9. Create `agents/requirements-reviewer/AGENT.md`.**

Frontmatter: name `requirements-reviewer`, description explaining it evaluates code changes for correctness and quality.

Role: Reviews code changes against the ticket requirements and codebase standards.

Constraints (key ones):
- Every finding must use the structured findings format from `templates/skill-authoring.md` (file:line using worktree-relative paths, severity, description, recommendation).
- Read the research brief and change summary from upstream_artifacts for architecture context and change scope before evaluating.
- Evaluate against the ticket's requirements (from ticket_notes), not personal preferences.
- Check: correctness (does the fix address the bug?), completeness (are all aspects handled?), quality (does it follow project patterns from the research brief?), safety (could it introduce new issues?).

Evaluation criteria: correctness of the fix, completeness relative to ticket description, adherence to project patterns from research brief, absence of introduced vulnerabilities or anti-patterns.

Output: Findings report at output_path using the structured findings format. If no issues found, write a brief confirmation of what was reviewed and why it passes.

STATUS: `complete — VERDICT: pass` or `complete — VERDICT: needs-work` or `failed — {reason}`.

**Step 10. Create `agents/regression-analyst/AGENT.md`.**

Frontmatter: name `regression-analyst`, description explaining it checks code changes for unintended side effects.

Role: Analyzes whether the bug fix could cause regressions or unintended behavioral changes.

Constraints (key ones):
- Read the research brief and change summary from upstream_artifacts for architecture context and change scope.
- Focus on behavioral changes, not style differences — flag only things that could break existing functionality.
- Check callers and dependents of modified functions/components.
- Examine test coverage: are the changed code paths tested? Are there tests that might break?
- Every finding must use the structured findings format from `templates/skill-authoring.md` (file:line using worktree-relative paths, severity, description, recommendation).

Evaluation criteria: unintended side effects in callers/dependents, behavioral changes in modified functions, test coverage gaps for changed paths, API contract changes.

Output: Regression analysis at output_path with structured findings.

STATUS: `complete — VERDICT: pass` or `complete — VERDICT: needs-work` or `failed — {reason}`.

**Step 11. Create `agents/simplification-reviewer/AGENT.md`.**

Frontmatter: name `simplification-reviewer`, description explaining it evaluates code changes for unnecessary complexity and scope bloat.

Role: Reviews code changes to identify over-engineering, unnecessary complexity, and opportunities to use standard patterns instead of custom code.

Constraints (key ones):
- Read the research brief and change summary from upstream_artifacts for architecture context and conventions — this informs what "standard patterns" look like in this codebase.
- Every finding must use the structured findings format from `templates/skill-authoring.md` (file:line using worktree-relative paths, severity, description, recommendation).
- Focus on three questions: (1) Does the fix introduce more complexity than the bug warrants? (2) Could standard library or framework features replace any custom code? (3) Did iterative fix rounds accumulate unnecessary changes (files modified that aren't related to the original bug)?
- Do not flag the core implementation approach — that's requirements-reviewer's domain. Focus on whether the approach is implemented with minimal complexity.
- A fix that is correct but unnecessarily complex is `should-fix`, not `must-fix`. Reserve `must-fix` for cases where the complexity introduces a maintenance or correctness risk.

Evaluation criteria: unnecessary abstraction layers, custom code that duplicates framework features, files modified beyond the bug's scope, verbose error handling for impossible cases, dead code introduced by fix iterations.

Output: Simplification analysis at output_path with structured findings. If the fix is appropriately scoped and simple, write a brief confirmation.

STATUS: `complete — VERDICT: pass` or `complete — VERDICT: needs-work` or `failed — {reason}`.

**Step 12. Create `agents/apply-review-fixes/AGENT.md`.**

Frontmatter: name `apply-review-fixes`, description explaining it applies targeted fixes based on reviewer feedback.

Role: Reads reviewer feedback and makes targeted fixes in the worktree.

Constraints (key ones — hardest first):
- Minimal diffs only — change only the lines reviewers flagged. "Minimal" means: if a reviewer flags line 42, modify line 42 and directly related lines (e.g., a variable declaration used on 42). Do not rearrange surrounding code, rename unrelated variables, or reformat untouched blocks. (Prevents churn where fixes introduce new issues that trigger another review round.)
- Never rewrite the core implementation approach. If a reviewer suggests an architectural change, flag it in the output summary rather than attempting it (architectural changes need the implement agent, not patch-level fixes).
- On conflicting feedback — two findings on the same file:line with different recommendations: keep the current code for the conflicted lines and note both recommendations in the output summary for the next review round to resolve.
- Prioritize by severity: `must-fix` items first, then `should-fix`, then `nit`.

Process: Read all upstream reviewer artifacts (paths provided in `## upstream_artifacts`) → extract actionable items with file:line references → apply fixes in severity-priority order → write a summary of what was changed and what was deferred to output_path.

STATUS: `complete` or `failed — {reason}`.

**Step 13. Create `agents/run-tests/AGENT.md`.**

Frontmatter: name `run-tests`, description explaining it discovers and runs the project's test suite.

Role: Discovers the project's test infrastructure and runs the test suite.

Constraints (key ones):
- Run tests from the worktree directory (the worktree has the bug fix applied).
- If no test suite is found (no test runner, no test files), return `STATUS: complete` with a note in the output: "No test suite discovered. Searched: [list what was checked — e.g., package.json scripts, Makefile, pytest.ini, etc.]." This signals to the human gate that tests weren't run, while providing enough detail to know what was attempted.
- Use the build and test commands from the upstream research brief if available (via `## upstream_artifacts`), otherwise discover them from common patterns (package.json scripts, Makefile targets, pytest, etc.).
- Report exact test output: which tests passed, which failed, failure messages.
- Test failures are reported in the output but the agent still returns `STATUS: complete` — test failures are data for the human, not agent execution errors. Return `STATUS: failed` only for execution errors (test runner crashed, command not found, etc.).
- Before writing the final report, scan the worktree diff (`git diff` of all changes) for accidentally committed secrets: API keys, tokens, credentials, private keys, .env file contents. Report any findings in the output with severity `must-fix` and the file:line where the secret appears. This is a lightweight check, not a comprehensive security audit — it catches obvious leaks that would otherwise reach the human reviewer.

Process: Check upstream_artifacts for research brief's Build & Test section → if not available, discover test runner from project files → run the test suite → scan worktree diff for secrets → collect results → write report to output_path.

STATUS: `complete` or `failed — {reason}`.

### Phase 3: Validation infrastructure

**Step 14. Update `scripts/validate.sh`.**

Two changes:

(a) In the "Shared modules" section, add `convergence` to the list alongside `config`, `claim`, and `transition`. This checks that `shared/convergence.md` exists.

(b) Add a new section after "Playbooks" titled "Playbook-agent cross-check". For each playbook `.md` file, scan for words that match existing `agents/` directory names and verify each has an `AGENT.md` file. Report missing agents as errors. Note: this is a best-effort heuristic — it catches missing agents but won't catch agent names that differ from directory names or agent names embedded in compound phrases. Sufficient for structural validation; behavioral correctness is verified by end-to-end testing.

### Phase 4: Final checks

**Step 15. Run `scripts/validate.sh`.**

Execute the validation script. Expect: all existing checks pass, new agents pass frontmatter/naming checks, new playbook passes naming check, shared module check passes (convergence.md exists), cross-check passes (all referenced agents exist). Fix any errors before considering the step complete.

## Acceptance Criteria

### Structural (verified by validate.sh)
- `scripts/validate.sh` passes with 0 errors.
- All seven agent AGENT.md files have valid frontmatter (name, description match directory name).
- `playbooks/code-fix.md` is non-empty, kebab-case filename, trailing newline.
- `shared/convergence.md` exists and is non-empty.
- The convergence reference appears in both `skills/work/SKILL.md` and `skills/review/SKILL.md`.
- Playbook-agent cross-check confirms all agents referenced in code-fix.md exist.

### Behavioral (verified by end-to-end testing)
- Given a project with `sdlc.config.yml` and a `type:code-fix` ticket in `todo` status, when `/loom:work` is invoked, then the orchestrator claims the ticket, reads `playbooks/code-fix.md`, spawns research-codebase-arch, then implement, then reads `shared/convergence.md` and runs the convergence loop with requirements-reviewer, regression-analyst, and simplification-reviewer (parallel), then runs run-tests, and transitions to `review`.
- Given all reviewers return `pass` on round 1, then convergence exits immediately (all-pass satisfies verdict logic), apply-review-fixes is not invoked, and run-tests executes.
- Given a reviewer returns `needs-work`, then apply-review-fixes runs with all three reviewer output paths as upstream_artifacts, and reviewers re-run on the updated worktree.
- Given 3 rounds of `needs-work` verdicts, then the orchestrator appends a convergence note to ticket_notes and proceeds to run-tests.
- Given a reviewer agent fails (STATUS: failed) while another returns needs-work, then the orchestrator stops immediately (failure takes precedence), reverts ticket to `todo`, and releases the lock.
- Given a reviewer agent times out, then the convergence handler re-spawns it once. If the retry also times out, the agent is treated as failed.
- Given a project with no test suite, then run-tests returns `complete` with a discovery note listing what was searched, not `failed`.
- Given a worktree diff contains an API key, then run-tests reports it as a `must-fix` finding in the test report.

## Edge Cases & Error Handling

| Scenario | Handling |
|---|---|
| No test suite in project | run-tests returns `complete` + discovery note listing what was searched |
| Bug file doesn't exist | implement returns `failed — file not found` |
| Reviewers always disagree | Max rounds → append note → transition with notes → human gate |
| Vague ticket description | research does best effort; implement may fail → human reviews |
| Worktree exists from prior run | claim.md merges with default branch |
| No convergence block in playbook | Sequential execution (no loop) — convergence handler not invoked |
| Agent AGENT.md not found | Orchestrator stops with error (existing behavior) |
| apply-review-fixes makes code worse | Next review round catches it; max rounds is the safety net |
| Conflicting reviewer feedback | apply-review-fixes keeps current code, flags conflict in output |
| Agent returns `complete` but no output file | Output path validation catches it; treated as agent failure |
| Mixed fail + needs-work in parallel reviewers | Failure takes precedence; convergence stops immediately |
| addReferences replaces instead of accumulates | Verify during implementation; if replaces, accumulate in orchestrator and pass full list |
| Convergence note format for human gate | Free text appended to ticket_notes; human reads it in Phase 3 of review |
| Tests not run between convergence rounds | By design — run-tests executes once after convergence, not between rounds. Reviewers catch issues pre-test; tests are a final gate. |
| Stale file:line in reviewer findings after fixes | Each convergence round re-runs reviewers on the updated worktree — findings are fresh per round. |
| Agent timeout during convergence | Re-spawn once; if retry also times out, treat as failed. Prevents hung agents from blocking the pipeline. |
| Secrets in worktree diff | run-tests scans diff and reports as `must-fix` in test report. Human reviewer sees it before transition. |
| Simplification reviewer flags core approach | simplification-reviewer is scoped to complexity, not correctness. Core approach flags are `should-fix` at most, not `must-fix`. Panel-reviewer owns correctness. |
| Convergence loop accumulates complexity | simplification-reviewer catches this pattern — its primary purpose. Findings route through apply-review-fixes like any other reviewer. |

## Testing Strategy

This step produces Markdown instruction files, not executable code. Testing is manual integration against a real project with a real backlog:

1. **Structural validation:** Run `scripts/validate.sh` — confirms all files have correct frontmatter, naming, hygiene, and cross-references.

2. **End-to-end smoke test:** Create a `type:code-fix` ticket in a test backlog with a real bug. Run `/loom:work`. Verify the orchestrator:
   - Claims the ticket
   - Reads code-fix.md
   - Spawns agents in the correct order
   - Reads shared/convergence.md for the convergence block
   - Handles convergence (if reviewers return needs-work)
   - Transitions to review

3. **All-pass on round 1:** Create a trivial bug that reviewers will pass immediately. Verify apply-review-fixes is not invoked and run-tests executes directly after convergence.

4. **Convergence loop:** Create a bug where the initial fix is incomplete. Verify the convergence loop runs multiple rounds, apply-review-fixes receives reviewer output paths as upstream_artifacts, and round numbers increment correctly.

5. **No-test-suite:** Point at a project with no tests. Verify run-tests returns `complete` with a discovery note.

6. **Agent failure mid-convergence:** Simulate an agent failure during review (e.g., corrupt AGENT.md). Verify the orchestrator stops immediately and reverts ticket status.

### Alignment Gate Summary
- Rounds: 3
- Team: Adversarial Reviewer, Edge Case Hunter, Simplification Reviewer
- Total findings: 63 raw across all rounds, deduplicated to ~50 unique
- Critical resolved: 3 (Round 1); Round 2 and 3 produced 0 valid Critical
- Consecutive clean rounds: 2
- Key improvements applied: convergence handler extracted to shared/convergence.md (DRY); redundant round-1 shortcut removed; concrete convergence block format with example; upstream_artifacts added to agent invocation protocol; explicit STATUS parsing with exact prefix matching; output path validation with non-whitespace threshold; failure-first precedence for parallel agents; reviewer findings format contract consolidated in template; conflict definition tightened to same file:line; placeholder resolution responsibility clarified; validation boundary between orchestrator and convergence handler documented; missing-VERDICT handling specified

### Post-Revision Alignment Gate Summary
- Rounds: 2
- Team: Adversarial Reviewer, Edge Case Hunter, Simplification Reviewer
- Total findings: 69 raw across 2 rounds (~29 unique after dedup)
- Critical findings: 0 valid in both rounds (6 flagged as Critical were downgraded — repeat findings from prior gate, runtime properties not plan parameters, controlled-input parsing)
- Consecutive clean rounds: 2
- Key improvements applied: reviewers now receive research brief and change summary as upstream context; reviewer findings use worktree-relative paths (not absolute); STATUS parsing explicitly case-sensitive
- Findings evaluated but not adopted: step consolidation suggestions (implementation steps are intentionally granular for a first vertical slice — easier to track progress); convergence handler verbosity reduction (detail level was validated by prior 3-round gate); research brief format versioning (premature — revisit at step 5)

### Post-Gate Revision: Reference Implementation Study
- Sources studied: `~/.claude/skills/my-dev/` (personal dev skill, 7 step files), `~/dev/reign/.claude/skills/sdlc-work/` (production SDLC, 435-line orchestrator + 25 specialized agents)
- Patterns adopted: simplification-reviewer in convergence (from reign — mandatory in every review gate), agent timeout/retry protocol (from reign — crash-safe atomicity), secrets scanning in run-tests (from my-dev — pre-review security check), absolute path discipline for worktree agents (from my-dev — prevents path confusion)
- Net changes: 6 agents → 7 agents, 14 steps → 15 steps (renumbered), 4 new design decisions (12-15), 4 new edge cases, 2 new behavioral acceptance criteria
- Patterns evaluated but not adopted: cascading classification (too coupled to spec-driven workflow), spec loopback (code-fix doesn't use specs), frozen spec sections (no specs), reign's 4 ticket types (Loom uses playbooks instead — more extensible), brand/design-system agents (domain-specific)
- Loom advantages confirmed: declarative playbooks (vs hardcoded step files), shared convergence module (vs inline logic), plugin architecture (vs project-embedded), structured findings format with severity tiers, output path validation, failure-first precedence
