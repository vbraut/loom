# Convergence

Handle convergence loops declared in playbooks.

## Steps

1. **Parse the `## Convergence` section** from the playbook. Extract:
   - **Agents** — names and `(parallel)` flag
   - **Verdict logic** — `AND` (all must pass) or `OR` (at least one must pass)
   - **Max rounds** — integer
   - **On needs-work** — feedback agent name
   - **On max rounds** — instruction text
   - **Reviewer output paths** — per-agent path templates with `{N}` placeholder
   - **Feedback agent output path** — path template with `{N}` placeholder

2. **Set `round` to 1.** Maintain this variable throughout — do not reset it.

3. **Spawn reviewer agents.** For agents marked `(parallel)`, spawn all via multiple Agent tool calls in a single response. Resolve path placeholders: replace `{ticket_id}` with the current ticket ID and `{N}` with the current `round` value. All paths must be absolute (resolved from the worktree root). For rounds > 1, include `{last_feedback_output}` in each reviewer's `## upstream_artifacts` alongside the playbook-defined upstream (the feedback agent's summary contains pushed-back findings and reasoning that reviewers need to re-evaluate). If an agent does not respond (timeout), re-spawn it once. If the retry also fails, treat as `STATUS: failed — agent timeout after retry`.

4. **Parse each STATUS line.** Find the last line beginning exactly with `STATUS: ` (case-sensitive). Extract `VERDICT: pass` or `VERDICT: needs-work` if present. If no VERDICT suffix on a reviewer: treat as `STATUS: failed — missing VERDICT in reviewer response`. If no STATUS line found: treat as `STATUS: failed — no STATUS line in response`.

5. **Check for failures first.** If any agent returned `STATUS: failed`, stop — follow the orchestrator's error handling. Do not proceed to verdict evaluation or the feedback agent (failure takes precedence over needs-work from other agents).

6. **Evaluate verdict logic.** AND: all agents must have `VERDICT: pass`. OR: at least one.

7. **If verdict satisfied:** convergence is complete. Register reviewer output paths via `addReferences`. Return to the orchestrator — continue with the next playbook step after the convergence block.

8. **If verdict not satisfied and `round` < Max rounds:** verify each reviewer output_path file exists and has at least one non-whitespace character (if missing or whitespace-only, treat the reviewer as failed — go to step 5). Spawn the feedback agent from **On needs-work**, passing all reviewer output_path references as `## upstream_artifacts`. Use the feedback agent output path template with `{N}` = current round. When the feedback agent completes, verify its output_path exists. Register all output paths from this round via `addReferences`. Store the feedback agent's output_path as `{last_feedback_output}`. Increment `round`. Go to step 3.

9. **If `round` >= Max rounds and verdict not satisfied:** follow the **On max rounds** instruction from the convergence block. Return to the orchestrator — continue with the next playbook step.
