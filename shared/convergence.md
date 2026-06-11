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

3. **Spawn reviewer agents.** For agents marked `(parallel)`, spawn all via multiple Agent tool calls in a single response. Resolve path placeholders: replace `{ticket_id}` with the current ticket ID and `{N}` with the current `round` value. All paths must be absolute (resolved from the worktree root). Include the **Upstream for reviewers** paths (parsed in step 1) as the base `## upstream_artifacts` for each reviewer in every round. Include a `## panel` section listing the other reviewers running in this step — agents with dual standalone/panel behavior (e.g., adversarial-reviewer) use it to avoid duplicating specialist findings. When the convergence target is a plan or spec (not code), append this note to every reviewer prompt: "This is a plan review. Plans describe architecture — what to change and why. Do not flag missing function signatures, mock body shapes, assertion syntax, payload schemas, or other code-level implementation details. Those are the implement agent's responsibility and will be caught during code convergence."

   For rounds > 1, also include `{last_feedback_output}` in each reviewer's `## upstream_artifacts` (only if a feedback agent ran in the prior round; omit for consecutive clean rounds where no feedback was needed). The feedback summary contains the cumulative findings ledger — reviewers do not receive each other's raw outputs; the ledger carries that signal at a fraction of the tokens. Append this note to every reviewer prompt in rounds > 1:

   "Convergence round {N}. The feedback summary in your upstream contains a findings ledger covering all reviewers' prior findings and their resolution. Focus this round on (a) the changes listed in the feedback summary and (b) verifying your own prior findings were addressed — do not re-review unchanged areas you already passed. Do not re-flag a finding whose ledger status is `pushed-back` unless you cite new evidence the pushback did not address; re-flags without new evidence are recorded as `contested` and escalated to the human rather than fixed."

   If an agent does not respond (timeout), re-spawn it once. If the retry also fails, treat as `STATUS: failed — agent timeout after retry`.

4. **Parse each STATUS line.** Find the last line beginning exactly with `STATUS: ` (case-sensitive). Extract `VERDICT: pass` or `VERDICT: needs-work` if present. If no VERDICT suffix on a reviewer: treat as `STATUS: failed — missing VERDICT in reviewer response`. If no STATUS line found: treat as `STATUS: failed — no STATUS line in response`.

4b. **Severity-gate the verdict.** A reviewer returning `VERDICT: needs-work` only triggers another round if its findings include at least one `must-fix` or `should-fix` issue. If all findings are `nit`-only, treat the verdict as `pass` for convergence purposes (the nit findings are still written to the reviewer output for the record, but do not block convergence). To evaluate: scan the reviewer's output for lines containing `**must-fix**` or `**should-fix**`. If none are found, override the verdict to `pass`.

5. **Check for failures first.** If any agent returned `STATUS: failed`, stop — follow the orchestrator's error handling. Do not proceed to verdict evaluation or the feedback agent (failure takes precedence over needs-work from other agents).

5b. **Track reviewer outputs.** Hold each reviewer's output_path for this round. Do not record intermediate rounds — only the final round's reviewer outputs are recorded in the exit sequence, so downstream consumers see the verdicts that actually stand. (Feedback agent outputs are tracked every round in step 8 — they carry the round history and ledger.)

6. **Evaluate verdict logic.** AND: all agents must have `VERDICT: pass`. OR: at least one.

7. **If verdict satisfied:** increment `consecutive_clean`. If `consecutive_clean` >= **Consecutive clean rounds**: convergence is complete — run the **Exit sequence** below, then continue with the next playbook step. Otherwise: increment `round`. If `round` > Max rounds, go to step 9. Otherwise go to step 3 (run another clean round to confirm stability).

8. **If verdict not satisfied and `round` < Max rounds:** reset `consecutive_clean` to 0. Verify each reviewer output_path file exists and has at least one non-whitespace character (if missing or whitespace-only, treat the reviewer as failed — go to step 5). Spawn the feedback agent from **On needs-work**, passing as `## upstream_artifacts`: all reviewer output_path references from this round, the playbook-defined reviewer upstream artifacts (e.g., research.md, changes.md), and `{last_feedback_output}` from the prior round when one exists (the feedback agent carries its findings ledger forward from it). Use the feedback agent output path template with `{N}` = current round. When the feedback agent completes:
   - Check its STATUS line. If `STATUS: failed`: stop — follow the orchestrator's error handling.
   - Verify its output_path exists and is non-empty. If missing or empty: treat as failed.
   - Track the feedback agent's output_path for the exit sequence's progress record — no backlog call.
   - Store the feedback agent's output_path as `{last_feedback_output}`.
   - Increment `round`. Go to step 3.

9. **If `round` >= Max rounds and convergence not complete:** follow the **On max rounds** instruction from the convergence block. If the instruction includes "Append to ticket_notes", hold the quoted text (replacing `{round}` with the current round value) and write it in the exit sequence's telemetry edit — one batched call with two `--append-notes` flags. If `consecutive_clean` > 0, append to the note: " (last {consecutive_clean} round(s) clean, awaiting confirmation)". Run the **Exit sequence** below, then return to the orchestrator — continue with the next playbook step.

## Exit sequence

Run once per convergence step, at completion (step 7) or max rounds (step 9):

1. **Record final outputs.** List in this step's progress record (see the work skill's Progress tracking): each reviewer output_path from the final round, plus every round's feedback agent output_path. No backlog call — the progress record is the artifact ledger the review phase resolves upstream from; recording only final-round reviewer outputs keeps intermediate rounds out of downstream consumption.
2. **Checkpoint commit.** Commit the converged state so retry detection has an exact baseline:
   ```bash
   git -C {worktree_path} add -A -- . ':!.loom'
   git -C {worktree_path} diff --cached --quiet || git -C {worktree_path} commit -m "loom({ticket_id}): convergence checkpoint — {step title}, round {round}"
   ```
   Record the resulting HEAD as `{last_convergence_commit}` for this step (consumed by Scoped retry convergence below). Document-only convergences (artifacts under `.loom/`) stage nothing and produce no commit — record HEAD as-is.
3. **Telemetry.** Append one line to ticket notes so panel composition and round caps can be tuned from real runs (shared/backlog.md — include the held max-rounds note from step 9 as a second `--append-notes` flag when one exists):
   ```bash
   ERR=$(BACKLOG_CWD="{backlog_cwd}" backlog task edit {ticket_id} --append-notes "Telemetry — {step title}: {round} round(s), exit: {clean | max-rounds}, contested: {count from the latest ledger, 0 if no feedback ran}" --plain 2>&1 >/dev/null)
   ```

## Scoped retry convergence

A verify step may declare optimization fields (`**Test-only optimization:**`, `**UI-only optimization:**`), each naming glob patterns and a reduced reviewer set. When that verify step's **On failure:** triggers a retry that re-runs this convergence step:

1. After the implement agent completes in the retry pass, run `git -C {worktree_path} status --porcelain`. Because the exit sequence committed everything at the last convergence completion, the uncommitted files are exactly the retry's changes — including new untracked files.
2. Check every changed file against each optimization field's patterns (shell glob: `*.test.*` matches `src/foo.test.ts`, `**/test/**` matches `src/test/helpers.ts`). If ALL changed files match a single field's pattern list, re-run the convergence step with only that field's reduced reviewer set. Evaluate fields in playbook order; the first fully-matching field wins.
3. If no field fully matches, or the retry produced no file changes, run the full reviewer set.
4. All other convergence fields (verdict logic, consecutive clean rounds, max rounds, on needs-work, upstream, output paths) remain unchanged. Only create output paths for the reviewers that actually run; the verdict is evaluated over those reviewers only.
