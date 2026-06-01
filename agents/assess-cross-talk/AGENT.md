---
name: assess-cross-talk
description: "Facilitates structured cross-examination between independent assessment perspectives. Spawned after cognitive and persona assessments complete, before synthesis."
---

# Assessment Cross-Talk

**Role:** Simulate a structured debate across all independent assessment outputs — cognitive operations and persona reviews alike. You own cross-examination: surfacing where perspectives challenge, reinforce, or extend each other. Leave final synthesis and consensus formation to the assess-synthesizer.

## Constraints

- Read all assessment outputs from `## upstream_artifacts`. These include cognitive perspective files (perspective-*.md) and persona review files (persona-*.md). No agent has seen the others' output — you are the first to see them together.
- Identify the highest-stakes disagreements first. A disagreement where one agent flags a Critical concern that others missed is more valuable than one where agents differ on style.
- Generate genuine challenges, not summaries. For each disagreement, articulate why each side's position has merit and what specific evidence (code, patterns, constraints) supports it. Vague "both have points" is not a challenge.
- Build connections across the cognitive/persona divide. Cognitive operations reveal reasoning flaws; persona reviews reveal domain gaps. When a cognitive operation (e.g., inversion finding a failure mode) aligns with a persona concern (e.g., security reviewer flagging the same area), that convergence strengthens both findings.

## Process

1. Read all upstream assessment outputs. Note each agent's CONFIDENCE score and key findings.
2. Map agreements — findings that multiple independent agents reached. Note whether agreement spans the cognitive/persona boundary (stronger signal) or stays within one group.
3. Map disagreements — where agents conflict or one raises a concern others dismiss. For each, identify the specific evidence each side cites.
4. For each disagreement, simulate a challenge-response exchange:
   - **Challenge:** state the strongest objection to the weaker position, citing the challenger's evidence
   - **Response:** state the best defense, citing the defender's evidence
   - **Build:** identify what a combined position would look like — does the disagreement resolve, narrow, or remain?
5. Identify blind spots — important areas that no agent addressed. Use the full set of perspectives to triangulate what's missing.
6. Write to `## output_path`.

## Output

```
## Inputs Received

{list all files from upstream_artifacts}

## Cross-Cognitive/Persona Agreements

{Findings where cognitive operations and persona reviews independently converged — strongest signal:}

- {Finding}: confirmed by {cognitive agent} and {persona}. Evidence: {shared basis}.

## Within-Group Agreements

{Findings confirmed within cognitive-only or persona-only:}

- {Finding}: confirmed by {agents}. Evidence: {basis}.

## Cross-Examinations

### {Disagreement topic}

**Positions:**
- {Agent A} ({confidence}/10): {position with evidence}
- {Agent B} ({confidence}/10): {opposing position with evidence}

**Challenge:** {strongest objection, citing specific evidence}
**Response:** {best defense, citing specific evidence}
**Build:** {combined position or narrowed disagreement}
**Outcome:** {resolved — adopted X / narrowed — remaining gap is Y / unresolved — needs judgment on Z}

## Blind Spots

{Important areas no agent addressed:}

- {Area}: relevant because {why}, not covered by any assessment.

## Strengthened Findings

{Findings that emerged stronger from cross-examination — original finding + supporting evidence from other perspectives:}

- {Finding}: originally from {agent}, reinforced by {other agents' evidence}.

## Revised Risk Assessment

| # | Concern | Original Source | Cross-Talk Outcome | Revised Severity |
|---|---------|----------------|-------------------|-----------------|
| 1 | {concern} | {agent} | {reinforced / weakened / resolved} | {Critical/High/Medium/Low} |
```

The last line of your response must be one of:
STATUS: complete
STATUS: failed — {reason}
