# Cross-talk

Handle cross-talk rounds declared in playbooks. Cross-talk uses SendMessage to resume named assessment agents with other agents' findings, running iterative rounds until positions converge.

## Prerequisites

Assessment agents from the preceding step must have been spawned with the `name` parameter (marked `(named, parallel)` in the playbook). The orchestrator must have captured each agent's ID (returned by the Agent tool) alongside its name. Their round 1 output files (the initial assessment) must exist.

## Steps

1. **Parse the cross-talk fields** from the current playbook step. Extract:
   - **Named agents** — the agent names from the preceding assess step (these are the SendMessage targets)
   - **Max rounds** — integer
   - **On max rounds** — instruction text
   - **Agent output path templates** — from the preceding assess step, with `{R}` placeholder for round number. The initial assessment was written to the `{R}=1` path.

2. **Skip gate.** Read every agent's round 1 output and the STATUS lines from the assess step. If no output contains a finding rated `Critical` or `High` AND every persona reviewer returned `VERDICT: pass`, skip cross-talk entirely — log "Cross-talk skipped — no Critical/High concerns to debate." The `{R}=1` outputs are final; continue with the next playbook step. (A debate with nothing contested only restates positions at full token cost.)

3. **Set `round` to 2** (round 1 was the initial independent assessment). Mark every agent `unresolved`.

4. **Read the latest output of each agent** — the highest-round file that exists for that agent (agents that converged in an earlier round keep their last output as final).

5. **Send cross-talk messages — only to agents still marked `unresolved`.** Use SendMessage with the agent's **ID** (not name) as `to`. Agents complete after round 1 and are no longer addressable by name — only the ID can resume them with full context. Send all messages in parallel (multiple SendMessage calls in a single response).

   Include in each message only the peer outputs that changed since that agent last received them (for round 2: all other agents' round 1 outputs; for later rounds: only outputs written in the prior round). Re-sending unchanged positions adds tokens without new signal. If an unresolved agent would receive no new peer content, do not message it — the debate is exhausted; follow the **On max rounds** instruction.

   The message to each agent:

   ```
   ## Cross-talk round {round}

   Other agents have independently assessed the same artifact. Their updated findings are below (positions unchanged since your last round are not repeated). Review them, then update your own assessment.

   ### {other-agent-name}

   {other agent's latest output file content}

   (repeat for each changed peer output)

   ---

   Instructions:
   1. Review the other agents' findings — look for disagreements, gaps, or reinforcements
   2. Challenge specific points where you have counter-evidence (cite file:line)
   3. When other agents surface quality-attribute tensions (e.g., "security requires X but usability requires Y"), respond to those tensions specifically — not just to findings. State whether you agree with the trade-off framing, and if not, why. The goal is to surface and resolve trade-offs, not accumulate concerns.
   4. Acknowledge findings that strengthen or correct your own analysis
   5. Revise your assessment — write updated output to the path in ## output_path below
   6. End your response with exactly one of:
      CROSS-TALK: converged
      CROSS-TALK: unresolved — {comma-separated list of remaining Critical/High concerns}

   ## output_path
   {agent's output_path with {R}=round}
   ```

   For persona-reviewer agents, use the name format `persona-{name}` matching how they were spawned.

6. **Wait for all responses, then parse.** All SendMessage calls from step 5 are parallel — wait for every messaged agent to respond before evaluating any results. Then, for each agent, find the last line beginning with `CROSS-TALK:` (case-sensitive). Agents reporting `converged` are marked converged — they are not resumed in later rounds and their latest output stands as final.

   **If SendMessage fails for any agent** (agent not responding, crashed, or errored): `ERROR: Cross-talk agent '{name}' did not respond. Aborting cross-talk.` — stop and follow the orchestrator's error handling.

   **If any agent's response is missing the `CROSS-TALK:` line:** `ERROR: Cross-talk agent '{name}' did not produce a CROSS-TALK: signal. Aborting cross-talk.` — stop and follow the orchestrator's error handling.

7. **Check exit condition.** If ALL agents are marked converged: cross-talk is complete — go to step 9.

8. **If any agent remains `unresolved` and `round` < Max rounds:** increment `round`. Go to step 4.

   **If `round` >= Max rounds (or the debate is exhausted per step 5) and not all converged:** follow the **On max rounds** instruction from the cross-talk block (typically: proceed and append a note to ticket_notes). Go to step 9.

9. **Finalize.** Each agent's final output is its highest-round file (agents may exit at different rounds). Record only these final paths in the step's progress record (see the work skill's Progress tracking) — no backlog call; the progress record is the artifact ledger the review phase resolves upstream from. Intermediate rounds stay on disk but are not recorded, which keeps them out of downstream consumption. Downstream steps consume the final paths. Return to the orchestrator — continue with the next playbook step.
