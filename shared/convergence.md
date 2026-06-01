# Convergence

Handle convergence loops declared in playbooks.

## Steps

1. **Parse the convergence fields** from the current playbook step. Extract:
   - **Agents** — names and `(parallel)` flag
   - **Verdict logic** — `AND` (all must pass) or `OR` (at least one must pass)
   - **Max rounds** — integer
   - **Consecutive clean rounds** — integer (default 1 if not specified). Convergence exits only after this many consecutive rounds where all reviewers return `VERDICT: pass`.
   - **On needs-work** — feedback agent name
   - **On max rounds** — instruction text
   - **Upstream for reviewers** — paths to pass as `## upstream_artifacts` to each reviewer
   - **Reviewer output paths** — per-agent path templates with `{N}` placeholder
   - **Feedback agent output path** — path template with `{N}` placeholder

2. **Set `round` to 1 and `consecutive_clean` to 0.** Maintain these variables throughout — do not reset them.

3. **Spawn reviewer agents.** For agents marked `(parallel)`, spawn all via multiple Agent tool calls in a single response. Resolve path placeholders: replace `{ticket_id}` with the current ticket ID and `{N}` with the current `round` value. All paths must be absolute (resolved from the worktree root). For rounds > 1, include in each reviewer's `## upstream_artifacts` in addition to the playbook-defined upstream:
   - `{last_feedback_output}` — the feedback agent's summary (only if a feedback agent ran in the prior round; omit for consecutive clean rounds where no feedback was needed)
   - All reviewer output_paths from the prior round — enables cross-examination (each reviewer can see what other reviewers found and whether the feedback agent's response was adequate)

   If an agent does not respond (timeout), re-spawn it once. If the retry also fails, treat as `STATUS: failed — agent timeout after retry`.

4. **Parse each STATUS line.** Find the last line beginning exactly with `STATUS: ` (case-sensitive). Extract `VERDICT: pass` or `VERDICT: needs-work` if present. If no VERDICT suffix on a reviewer: treat as `STATUS: failed — missing VERDICT in reviewer response`. If no STATUS line found: treat as `STATUS: failed — no STATUS line in response`.

5. **Check for failures first.** If any agent returned `STATUS: failed`, stop — follow the orchestrator's error handling. Do not proceed to verdict evaluation or the feedback agent (failure takes precedence over needs-work from other agents).

6. **Evaluate verdict logic.** AND: all agents must have `VERDICT: pass`. OR: at least one.

7. **If verdict satisfied:** increment `consecutive_clean`. If `consecutive_clean` >= **Consecutive clean rounds**: convergence is complete — continue with the next playbook step. Otherwise: increment `round`. If `round` > Max rounds, go to step 9. Otherwise go to step 3 (run another clean round to confirm stability).

8. **If verdict not satisfied and `round` < Max rounds:** reset `consecutive_clean` to 0. Verify each reviewer output_path file exists and has at least one non-whitespace character (if missing or whitespace-only, treat the reviewer as failed — go to step 5). Spawn the feedback agent from **On needs-work**, passing all reviewer output_path references AND the playbook-defined reviewer upstream artifacts (e.g., research.md, changes.md) as `## upstream_artifacts`. Use the feedback agent output path template with `{N}` = current round. When the feedback agent completes:
   - Check its STATUS line. If `STATUS: failed`: stop — follow the orchestrator's error handling.
   - Verify its output_path exists and is non-empty. If missing or empty: treat as failed.
   - Store the feedback agent's output_path as `{last_feedback_output}`.
   - Store all reviewer output_paths from this round.
   - Increment `round`. Go to step 3.

9. **If `round` >= Max rounds and convergence not complete:** follow the **On max rounds** instruction from the convergence block. If the instruction includes "Append to ticket_notes", call `task_edit(ticket_id, notesAppend=[text])` with the quoted text, replacing `{round}` with the current round value. Return to the orchestrator — continue with the next playbook step.
