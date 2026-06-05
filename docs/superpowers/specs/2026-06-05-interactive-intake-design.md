# Interactive Intake, External Research & Draft Checkpoint

Design spec for making market-strategy and brand-exploration playbooks interactive and externally grounded.

## Problem

Both playbooks start with `research-codebase-arch` — a code explorer — as their primary context source. For strategy and brand work, the most valuable inputs live in the user's head (vision, competitors, audience, constraints) and on the internet (competitor positioning, market data, design trends), not in the codebase. The current flow produces plausible-sounding output grounded in LLM inference rather than real context.

## Approach: Playbook-Declared Intake (Approach A)

Playbooks gain three new declarative directives. The orchestrator (work SKILL.md) interprets them. No new orchestrator phases — intake is a pre-step-1 directive, checkpoint is a per-step annotation, and external research is a background agent spawned during intake.

### Patterns borrowed

| Pattern | Source | How we use it |
|---------|--------|---------------|
| Three stances (Facilitate/Collaborate/Autonomous) | BMAD brainstorming | Stance selection before intake questions |
| One question at a time | GPT-Pilot spec-writer | Orchestrator asks sequentially, never batches |
| Broad→narrow question ordering | BMAD discovery interview | Questions ordered from vision to constraints |
| Parallel fan-out during intake | BMAD PRFAQ Ignition | `research-external` spawned in background while user answers |
| Scope policing | GPT-Pilot spec-writer | Orchestrator flags over-scoped answers |
| Diff-based approval gate | GPT-Pilot spec changes | Checkpoint shows draft summary before expensive pipeline |
| Headless/blocked mode | BMAD headless skills | Autonomous stance halts with `blocked` if ticket too sparse |
| Cited research docs | BMAD market-research | `research-external` cites every claim with source URL |
| Refinement loop | GPT-Pilot spec-writer | Intake summary loops until user confirms |
| Context hints per question | BMAD discovery interview | `context:` field tells orchestrator what a sufficient answer looks like |

## Scope

**In scope:** market-strategy and brand-exploration playbooks. Two playbooks redesigned.

**Out of scope:** copy-deck, product-definition, code-fix, implementation, bug-triage playbooks. These keep their current flow. copy-deck is a natural follow-up candidate.

## Design

### 1. Orchestrator changes (work SKILL.md)

Three additions to Phase 2: EXECUTE PLAYBOOK, all additive — no existing logic changes.

#### 1a. Intake handling

Placed before "Playbook execution" in the orchestrator.

1. After reading the playbook, check for a `## Intake` section. If absent, skip to step 1 as normal.
2. If present, read the `### Stance` line and present the three-stance choice to the user.
3. Based on stance:
   - **Facilitate:** Read `### Questions`. Ask them one at a time, neutrally. Each question has a `context:` hint the orchestrator uses to assess answer sufficiency — if the answer is thin (one word, no specifics), probe once: "Can you say more about [specific aspect from context hint]?" Then move on regardless. After all questions, present a summary: "Here's what I captured: [bullets]. Anything to add or correct?" Loop until user confirms.
   - **Collaborate:** Same questions but conversational — the orchestrator offers observations between questions based on what it's learning. "Based on what you said about X, it sounds like Y might also be relevant — is that right?" Still one question at a time.
   - **Autonomous:** Read `### Questions` and their `context:` hints. Map each question to the ticket description — a question is "answered" if the ticket contains a concrete response matching the context hint (named entities, specific constraints, measurable criteria — not vague aspirations). If fewer than 3 of the 7 questions are answered by the ticket, halt and report: "Autonomous mode blocked — ticket is too sparse. Missing: [list unanswerable questions]. Switch to facilitate/collaborate, or enrich the ticket." If 3+ are answered, infer the rest from codebase/config context and note inferences in the Orchestrator Notes section of the intake brief.
4. **Scope policing:** During intake, if answers suggest scope exceeds one playbook run (multiple product lines, multiple markets, multiple brands), flag: "This sounds like N separate [strategy/brand] tickets. Want to narrow scope, or proceed with everything?" (GPT-Pilot pattern.)
5. **Parallel fan-out:** After the user answers the competitors/landscape question (question 2 for market-strategy, question 6 for brand-exploration), spawn `research-external` in the background with a partial intake brief containing at minimum: playbook type, strategic question/brand goal, and competitive context. The remaining questions continue while research runs. If WebSearch tool is unavailable, skip gracefully — log a note, proceed without external research.
6. Write intake brief to `.loom/artifacts/{ticket_id}/intake-brief.md`. Register via addReferences.

#### 1b. Checkpoint handling

Placed within the agent invocation logic, after step completion.

When a playbook step has a `**Checkpoint:**` field and the agent completes successfully:

1. Read the agent's output artifact.
2. Extract section headers and first sentence of each section as summary bullets.
3. Present to user: "Draft [strategy/brand spec] ready. Key points: [bullets]. The assessment pipeline (5 cognitive reviewers + personas + cross-talk + elicitation + convergence) runs next — redirecting now is cheap, redirecting after is expensive."
4. Three responses:
   - **Approve** — proceed to next step.
   - **Redirect** — user provides notes. Spawn `apply-review-fixes` with redirect notes as upstream. Revise draft in place. Re-present checkpoint. Loop until approved.
   - **Abort** — follow error handling (revert ticket status, release lock, stop).

#### 1c. Parallel background agents

When the orchestrator spawns `research-external` during intake, it runs in the background. The playbook declares an "Await external research" step (no agent, just an output path). When the orchestrator reaches this step, it checks if the background agent completed. If not, it waits. If the agent failed, log the failure and continue without external research (graceful degradation).

### 2. Playbook intake blocks

#### market-strategy `## Intake`

```markdown
## Intake

### Stance
facilitate | collaborate | autonomous

### Questions

1. What strategic question needs answering?
   context: The core decision — "should we enter market X", "how to position against Y",
   "pricing strategy for Z". Must be specific enough to produce actionable recommendations.

2. Who are your top 3-5 competitors, and what do you see as their positioning?
   context: Named competitors with brief descriptions. If the user can't name any,
   that's a signal for heavier web research.

3. Who is the target audience, and what do they care about most?
   context: Specific segments, not "everyone". Needs at least one concrete persona
   or segment description.

4. What's your current positioning — how do customers describe you today?
   context: The gap between current and desired positioning drives the strategy.
   "We don't have positioning yet" is a valid answer that changes the output shape.

5. What constraints or non-negotiables should the strategy respect?
   context: Budget, timeline, team size, technical limitations, partnerships, regulatory.
   These bound the recommendation space.

6. What does success look like in 6-12 months?
   context: Measurable outcomes, not aspirations. Revenue targets, market share,
   user counts, partnerships closed.

7. What existing research or context do you already have?
   context: Links to docs, prior strategies, market research, user interviews.
   Anything the user already has that should feed into the analysis.
```

#### brand-exploration `## Intake`

```markdown
## Intake

### Stance
facilitate | collaborate | autonomous

### Questions

1. What should this brand communicate — what's the core message or feeling?
   context: Emotional territory, not features. "Trustworthy but not boring",
   "innovative without being intimidating". If the user gives features, redirect to feelings.

2. Who is the audience, and what visual language do they respond to?
   context: Audience demographics AND their design sensibilities. A developer audience
   expects different visuals than a consumer audience.

3. Name 2-4 brands whose visual feel you admire, and what specifically you like about each.
   context: Concrete references, not adjectives. "Stripe's clean confidence" communicates
   more than "modern and professional". These become mood board anchors.

4. What should this brand absolutely NOT look like?
   context: Anti-references are as important as references. "Not clinical like medical software",
   "not playful like a kids' app". These prevent drift in visual exploration.

5. What existing brand assets or design constraints exist?
   context: Current logo, colors, typography, design system, WCAG requirements, dark mode needs.
   These are hard constraints, not suggestions.

6. What's the competitive visual landscape — how do competitors look, and where do you want to differentiate?
   context: If competitors all use blue and white, "we want to stand out" means specific
   differentiation. Drives the web research agent's visual competitor analysis.

7. Is there a timeline or deliverable trigger — what will these brand visuals be used for?
   context: "Website redesign next quarter" vs "exploring identity from scratch" changes
   the specificity needed. Tight timelines need tighter deliverable definitions.
```

### 3. `research-external` agent

New agent at `agents/research-external/AGENT.md`. One agent serves both playbooks — the intake brief tells it what domain to research.

**Role:** Gather external context via web research — competitor analysis, market data, industry trends, visual identity analysis. Produce a cited research brief where every claim links to a source URL. Leave codebase exploration to research-codebase-arch and strategic/creative synthesis to the drafting agents.

**Constraints:**
- Every finding must cite a source URL and access date.
- Soft limit of 5 web searches to prevent runaway research. If more seems needed, note it in Research Gaps.
- If WebSearch/WebFetch tools are unavailable, produce what can be inferred from the intake brief alone and note what couldn't be verified. Don't fail — produce a thinner brief.
- Write to output_path only.
- Focus on what the intake brief asks about — don't do open-ended market exploration.

**Process:**
1. Read the intake brief from upstream_artifacts. Identify research focus: named competitors, market questions, visual references, audience segments.
2. For each named competitor: search for their website, positioning, pricing, key messaging. Fetch and extract relevant content.
3. For market context: search for industry trends, market sizing, analyst perspectives relevant to the strategic question or brand space.
4. For brand-exploration tickets: search for competitor visual identities, design trend reports, and any reference brands the user mentioned.
5. Compile findings into the output format. Note gaps — what couldn't be found or verified.

**Output format:**

```
## Inputs Received
{intake brief summary, research focus areas}

## Competitor Analysis
### {Competitor Name}
**Source:** {URL}, accessed {date}
**Positioning:** {how they describe themselves}
**Strengths:** {what they do well}
**Gaps:** {where they're weak or absent}

## Market Context
**Source:** {URL}, accessed {date}
{trends, dynamics, sizing if available}

## Visual Landscape
(include when intake brief contains brand/visual references)
### {Competitor/Reference Brand}
**Source:** {URL}, accessed {date}
**Visual identity:** {colors, typography, style description}
**Differentiation opportunity:** {what's underserved visually}

## Research Gaps
{what couldn't be found or verified — signals for the human to fill}
```

Output path: `.loom/artifacts/{ticket_id}/external-research.md`

Tools: `WebSearch`, `WebFetch`, `Read`, `Bash`

### 4. Revised playbook flows

#### market-strategy

```
Intake: stance → questions → intake-brief.md (research-external spawned in background)

1. Research codebase
   Agent: research-codebase-arch
   Upstream: intake-brief.md (new)

2. Await external research
   Output: external-research.md

3. Draft strategy
   Agent: draft-strategy
   Upstream: intake-brief.md + research.md + external-research.md
   Checkpoint: Approve draft direction before assessment pipeline

4. Assess strategy (unchanged)
5. Cross-talk (unchanged)
6. Synthesize (unchanged)
7. Revise with synthesis (unchanged)
8. Elicit (unchanged)
9. Revise with elicitation (unchanged)
10. Converge (unchanged)
11. Completion
```

#### brand-exploration

```
Intake: stance → questions → intake-brief.md (research-external spawned in background)

1. Research codebase
   Agent: research-codebase-arch
   Upstream: intake-brief.md (new)

2. Await external research
   Output: external-research.md

3. Draft brand spec
   Agent: draft-brand-spec
   Upstream: intake-brief.md + research.md + external-research.md
   Checkpoint: Approve draft direction before assessment pipeline

4. Assess brand spec (unchanged)
5. Cross-talk (unchanged)
6. Synthesize (unchanged)
7. Revise with synthesis (unchanged)
8. Elicit (unchanged)
9. Revise with elicitation (unchanged)
10. Converge spec (unchanged)
11. Create brand visuals (unchanged)
12. Converge visuals (unchanged)
13. Completion
```

### 5. Drafting agent changes

#### draft-strategy

- Drops brand-toolkit skill invocations as primary research method. Brand-toolkit skills become optional enrichment called only when the intake brief suggests brand-adjacent strategic questions.
- Primary inputs: intake brief (user's own words), external research (cited web data), codebase research (product context).
- Process shifts from "invoke frameworks to generate strategy" to "synthesize user intent + real market data into strategy."

#### draft-brand-spec

- Primary input becomes the intake brief. Visual territory, anti-references, and mood references come from user's actual answers.
- Agent's job shifts from "imagine a brand direction" to "structure and refine the direction the user articulated."
- Still reads config.context.brand_voice and config.context.design_system for constraint context.

### 6. Intake brief format

```
## Playbook Type
{market-strategy | brand-exploration — lets downstream agents adapt behavior}

## Strategic Question / Brand Goal
{the core question or brand direction}

## Audience
{target segments, demographics, design sensibilities}

## Competitive Context
{named competitors, perceived positioning, visual landscape}

## Current State
{current positioning or existing brand assets/design constraints}

## Constraints & Non-Negotiables
{budget, timeline, technical, regulatory, WCAG, dark mode}

## Success Criteria
{measurable outcomes, timeline}

## References & Existing Research
{links to docs, visual references, prior strategies, user interviews}

## Anti-References
{brand-exploration: what the brand must NOT look like. market-strategy: omit section}

## Orchestrator Notes
{scope observations, gaps flagged, stance used, inferences made in autonomous mode}
```

### 7. What doesn't change

- The entire assessment → convergence pipeline stays identical. Better inputs, same rigorous evaluation.
- Agent architecture, convergence protocol, cross-talk protocol, elicitation — all untouched.
- Persona selection, reviewer panels, output paths — same structure.
- Copy-deck, product-definition, and all code playbooks — untouched.
- Plugin dependencies — no new external plugin requirements from this change.
- Existing config context slots — still read by agents that use them.

### 8. Migration

- Existing tickets already in-progress on these playbook types: unaffected (intake is pre-step-1, so it only applies to new runs).
- No config changes required. Intake is playbook-declared, not config-dependent.
- `research-external` gracefully degrades without web access — no hard dependency.

### 9. Files to create/modify

**Create:**
- `agents/research-external/AGENT.md` — new web research agent

**Modify:**
- `skills/work/SKILL.md` — add intake handling, checkpoint handling, parallel background agent subsections
- `playbooks/market-strategy.md` — add `## Intake`, add `research-external` step, add checkpoint to draft step, update upstream paths
- `playbooks/brand-exploration.md` — add `## Intake`, add `research-external` step, add checkpoint to draft step, update upstream paths
- `agents/draft-strategy/AGENT.md` — shift from brand-toolkit-first to intake-brief-first synthesis
- `agents/draft-brand-spec/AGENT.md` — shift from inference to user-articulated direction
- `README.md` — update pipeline diagrams and step counts for the two playbooks
- `scripts/validate.sh` — if it checks agent count or playbook structure, update for new patterns
