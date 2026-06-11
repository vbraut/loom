# Intake

Handle interactive intake, draft checkpoints, and background-research await steps. Playbooks that declare an `## Intake` section use all three mechanisms; read this module once before executing step 1 of such a playbook.

## Intake handling

After reading the playbook (but before executing step 1), check for a `## Intake` section. If absent, skip to step 1 as normal.

If present:

1. Read the `### Stance` line. Present the three-stance choice to the user: "(a) Facilitate — I ask structured questions, you provide the vision. (b) Collaborate — we trade ideas back and forth. (c) Autonomous — I infer from the ticket and existing context, ask only if blocked."

2. Based on stance:
   - **Facilitate:** Read `### Questions`. Ask them one at a time. Each question has a `context:` hint — use it to assess answer sufficiency. If the answer is thin (one word, no specifics), probe once: "Can you say more about [specific aspect from context hint]?" Then move on regardless. After all questions, present a summary: "Here's what I captured: [bullets]. Anything to add or correct?" Loop until the user confirms.
   - **Collaborate:** Same questions but conversational — offer observations between questions based on what is being learned. "Based on what you said about X, it sounds like Y might also be relevant — is that right?" Still one question at a time.
   - **Autonomous:** Map each question to the ticket description. A question is "answered" if the ticket contains a concrete response matching the context hint (named entities, specific constraints, measurable criteria — not vague aspirations). Two mandatory questions must always be answered by the ticket regardless of total count: the strategic/brand question (Q1) and the audience question (Q3 for all three playbooks). If either mandatory question is unanswered, or if fewer than 4 of the 7 questions are answered, halt: "Autonomous mode blocked — ticket is too sparse. Missing: [list unanswerable questions]. Switch to facilitate/collaborate, or enrich the ticket." If 4+ are answered (including both mandatory), infer the rest from codebase/config context and note inferences in the Orchestrator Notes section of the intake brief. After completing autonomous inference, spawn `research-external` in the background if the ticket contains competitor/landscape information — use the same spawn mechanics as Parallel fan-out (agent content, upstream format, WebSearch availability check) but trigger on ticket content rather than a user answer. If the ticket lacks competitive context, skip the fan-out and log "External research skipped (no competitive context in ticket)."

3. **Scope policing (two-pass):**
   - **After Q1 (or after mapping Q1 in autonomous mode):** Check the strategic/brand question for obvious multi-scope signals. If the question spans multiple distinct deliverables (multiple product lines, multiple markets, multiple brands, multiple audience segments requiring separate strategies, exhaustive global competitor analysis), flag immediately: "This sounds like N separate [strategy/brand/copy] tickets. Want to narrow scope before we continue?" This runs before the fan-out trigger. In autonomous mode, run this check after mapping Q1 but before mapping Q2-Q7 — halt inference if scope is flagged.
   - **After all questions (or after mapping all questions in autonomous mode):** Re-check for emergent scope creep across answers. If combined answers suggest scope that would require multiple distinct deliverables to address adequately, flag: "Based on everything you've described, this looks like N separate tickets. Want to narrow scope, or proceed with everything?"

4. **Parallel fan-out:** After the user answers the competitors/landscape question, spawn `research-external` in the background via Agent tool with `run_in_background: true`. The trigger question by playbook type:
   - market-strategy: Q2 (competitors and positioning)
   - brand-exploration: Q2 (competitive visual landscape)
   - copy-deck: Q2 (competitive voice/tone landscape)

   Pass a partial intake brief (playbook type + strategic question/brand goal + competitive context) as upstream. Read `{loom_plugin_dir}/agents/research-external/AGENT.md` for the agent content. If WebSearch tool is unavailable, skip — log "External research skipped (WebSearch unavailable)" and proceed without it.

5. Write the intake brief to `.loom/artifacts/{ticket_id}/intake-brief.md` with sections: `## Playbook Type`, `## Strategic Question / Brand Goal`, `## Audience`, `## Competitive Context`, `## Current State`, `## Constraints & Non-Negotiables`, `## Success Criteria`, `## References & Existing Research`, `## Anti-References` (brand-exploration and copy-deck), `## Orchestrator Notes`. No backlog call — the intake progress record is the ledger entry (the review phase resolves artifacts from the progress file, never from the ticket).

## Checkpoint handling

When a playbook step has a `**Checkpoint:**` field and the agent completes successfully:

1. Read the agent's output artifact.
2. Extract section headers and first sentence of each section as summary bullets.
3. Present to user: "Draft [type] ready. Key points: [bullets]. The assessment pipeline runs next — redirecting now is cheap, redirecting after is expensive. Approve, redirect, or abort?"
4. Responses:
   - **Approve:** proceed to next step.
   - **Redirect:** user provides notes on what's wrong. If redirect notes are fewer than 10 words, probe once: "Can you be more specific about what to change? Which sections need work?" Then spawn `apply-review-fixes` with the redirect notes and the draft artifact as upstream. Revise draft in place. Re-present checkpoint. Maximum 3 redirects per checkpoint. After 3: "We've iterated 3 times on this draft. To make progress: (a) provide specific section-level feedback (names sections and what's wrong with each), (b) approve and let the assessment pipeline challenge it, or (c) abort." If the user chooses (a) and provides section-level feedback, reset the counter to 2 (allowing one final redirect with the specific feedback), run apply-review-fixes, and re-present the checkpoint.
   - **Abort:** follow error handling (revert ticket status, release lock, stop).

## Await step handling

When a playbook step has no `**Agent:**` field but has an `**Output path:**`, it is a synchronization point for a background agent spawned during intake (or skipped entirely in autonomous mode). If no background agent was spawned for this path, treat as gracefully skipped. Otherwise, check if the background agent has completed. If not yet complete, wait for it. When complete: verify the output file exists and is non-empty. If the background agent failed, its output is missing, or no agent was spawned: log the outcome and remove the corresponding path from all downstream steps' `**Upstream:**` lists for the remainder of the playbook. The orchestrator's artifact-existence check (agent invocation rule 5b) does not apply to await-step artifacts that were gracefully skipped — the pipeline continues without them. The `(optional)` annotations on downstream steps are a safety net in case path removal is missed; the await step's path removal is the primary mechanism.
