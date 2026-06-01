# Cross-talk

Handle cross-talk rounds declared in playbooks. Cross-talk uses SendMessage to resume named assessment agents with other agents' findings, running iterative rounds until positions converge.

## Prerequisites

Assessment agents from the preceding step must have been spawned with the `name` parameter (marked `(named, parallel)` in the playbook). Their output files must exist.

## Steps

1. **Parse the cross-talk fields** from the current playbook step. Extract:
   - **Named agents** — the agent names from the preceding assess step (these are the SendMessage targets)
   - **Max rounds** — integer
   - **On max rounds** — instruction text
   - **Agent output paths** — the output paths from the assess step (each agent's written assessment)

2. **Set `round` to 1.**

3. **Read all agent output files** from the preceding assess step.

4. **Send cross-talk messages.** For each named agent, use SendMessage with the agent's name as `to`. Send all messages in parallel (multiple SendMessage calls in a single response). The message to each agent:

   ```
   ## Cross-talk round {round}

   Other agents have independently assessed the same artifact. Their findings are below. Review them, then update your own assessment.

   ### {other-agent-name}

   {other agent's current output file content}

   (repeat for each other agent)

   ---

   Instructions:
   1. Review the other agents' findings — look for disagreements, gaps, or reinforcements
   2. Challenge specific points where you have counter-evidence (cite file:line)
   3. Acknowledge findings that strengthen or correct your own analysis
   4. Revise your assessment — write updated output to your output_path
   5. End your response with exactly one of:
      CROSS-TALK: converged
      CROSS-TALK: unresolved — {comma-separated list of remaining Critical/High concerns}
   ```

   For persona-reviewer agents, use the name format `persona-{name}` matching how they were spawned.

5. **Parse each agent's response.** Find the last line beginning with `CROSS-TALK:` (case-sensitive). Extract `converged` or `unresolved — {concerns}`.

6. **Check exit condition.** If ALL agents report `CROSS-TALK: converged`: cross-talk is complete — continue with the next playbook step.

7. **If any agent reports `unresolved` and `round` < Max rounds:** increment `round`. Go to step 3 (re-read updated output files for the next round).

8. **If `round` >= Max rounds and not all converged:** follow the **On max rounds** instruction from the cross-talk block (typically: proceed and append a note to ticket_notes). Return to the orchestrator — continue with the next playbook step.
