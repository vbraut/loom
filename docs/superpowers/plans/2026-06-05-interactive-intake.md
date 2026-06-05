# Interactive Intake Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add interactive discovery intake, web research agent, and draft checkpoint gates to market-strategy and brand-exploration playbooks.

**Architecture:** Playbooks declare `## Intake` sections with stance selection and structured questions. The orchestrator (work SKILL.md) interprets these directives pre-step-1. A new `research-external` agent runs web searches in parallel with intake. A `**Checkpoint:**` field on draft steps pauses for human approval before the expensive assessment pipeline.

**Tech Stack:** Markdown framework (agents, playbooks, orchestrator skills). No runtime code — all changes are declarative markdown consumed by the Claude Code orchestrator.

**Spec:** `docs/superpowers/specs/2026-06-05-interactive-intake-design.md`

---

### Task 1: Create `research-external` agent

**Files:**
- Create: `agents/research-external/AGENT.md`

- [ ] **Step 1: Create the agent directory**

```bash
mkdir -p agents/research-external
```

- [ ] **Step 2: Write the AGENT.md**

Create `agents/research-external/AGENT.md` with:

Frontmatter: `name: research-external`, `description: "Gathers external context via web research — competitor analysis, market data, design trends. Produces a cited research brief. Triggered during playbook intake, runs in parallel with codebase research."`, `tools: [WebSearch, WebFetch, Read, Bash]`

Role line: Gather external context via web research — competitor analysis, market data, industry trends, visual identity analysis. Produce a cited research brief where every claim links to a source URL. Leave codebase exploration to research-codebase-arch and strategic/creative synthesis to the drafting agents.

Constraints (ordered by criticality):
1. Every finding must cite a source URL and access date — uncited claims are worthless to downstream reviewers.
2. Focus on what the intake brief asks about — named competitors, specific market questions, referenced brands. No open-ended market exploration.
3. Soft limit of 5 web searches. If more seems needed, note it in Research Gaps rather than exceeding.
4. If WebSearch/WebFetch tools are unavailable, produce what can be inferred from the intake brief context alone. Note what couldn't be verified in Research Gaps. Don't fail — produce a thinner brief.
5. Write to output_path only.

Process:
1. Read the intake brief from upstream_artifacts. Identify the playbook type (market-strategy or brand-exploration) and research focus areas: named competitors, market questions, visual references, audience segments.
2. For each named competitor: search for their website, positioning, pricing, key messaging. Fetch and extract relevant content.
3. For market context: search for industry trends, market sizing, analyst perspectives relevant to the strategic question or brand space.
4. For brand-exploration tickets: search for competitor visual identities, design trend reports, and any reference brands the user mentioned in intake.
5. Compile findings into the output format. Note gaps — what couldn't be found or verified.

Output format with these sections:
- `## Inputs Received` — intake brief summary, research focus areas
- `## Competitor Analysis` — per-competitor subsections with Source (URL + access date), Positioning, Strengths, Gaps
- `## Market Context` — sourced trends, dynamics, sizing
- `## Visual Landscape` — include when intake brief contains brand/visual references. Per-brand subsections with Source, Visual identity description, Differentiation opportunity
- `## Research Gaps` — what couldn't be found or verified

STATUS line: `STATUS: complete` or `STATUS: failed — {reason}`

- [ ] **Step 3: Run validate.sh**

```bash
bash scripts/validate.sh
```

Expected: agent passes frontmatter validation, cross-check passes (not yet referenced by any playbook, which is fine — the cross-check only flags missing agents that ARE referenced).

- [ ] **Step 4: Commit**

```bash
git add agents/research-external/AGENT.md
git commit -m "Add research-external agent for web-based market and brand research"
```

---

### Task 2: Add intake and revised flow to market-strategy playbook

**Files:**
- Modify: `playbooks/market-strategy.md`

- [ ] **Step 1: Read the current playbook**

```bash
cat playbooks/market-strategy.md
```

Understand the current 10-step structure. The changes: add `## Intake` section before steps, insert two new steps (research-external await + checkpoint), renumber everything, update upstream paths.

- [ ] **Step 2: Add the `## Intake` section**

Insert after the opening description paragraph and before `## Steps`. The section contains:

`### Stance` — `facilitate | collaborate | autonomous`

`### Questions` — seven numbered questions, each with a `context:` hint on the next line (indented). Questions in order:
1. What strategic question needs answering? (context: core decision, must be specific)
2. Who are your top 3-5 competitors, and what do you see as their positioning? (context: named competitors, signal for web research intensity)
3. Who is the target audience, and what do they care about most? (context: specific segments, not "everyone")
4. What's your current positioning — how do customers describe you today? (context: gap between current and desired)
5. What constraints or non-negotiables should the strategy respect? (context: budget, timeline, team size, regulatory)
6. What does success look like in 6-12 months? (context: measurable outcomes, not aspirations)
7. What existing research or context do you already have? (context: links to docs, prior strategies)

- [ ] **Step 3: Rewrite the Steps section**

New step structure (11 steps total):

**Step 1 — Research codebase:** Same agent (`research-codebase-arch`), same output path. Add `intake-brief.md` to its upstream: `**Upstream:** .loom/artifacts/{ticket_id}/intake-brief.md`

**Step 2 — Await external research (NEW):** No agent — this is a synchronization point. The orchestrator waits for the background `research-external` agent spawned during intake. Output path: `.loom/artifacts/{ticket_id}/external-research.md`

**Step 3 — Draft strategy:** Same agent (`draft-strategy`). Updated upstream to include all three inputs:
- `.loom/artifacts/{ticket_id}/intake-brief.md`
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/external-research.md`

Add: `**Checkpoint:** Approve draft direction before assessment pipeline`

**Steps 4-11:** Renumber from the current steps 3-10 (assess, cross-talk, synthesize, revise, elicit, revise, converge, completion). Each step that previously listed `research.md` as upstream also gets `intake-brief.md` and `external-research.md` added. Specifically, the upstream for reviewers in the assess step (now step 4) and convergence step (now step 11) gains these two additional paths.

- [ ] **Step 4: Update the pre-completion checklist**

Update to reflect new steps:
- intake brief produced (or autonomous inference completed)
- research-external completed (or skipped if web unavailable)
- Add the checkpoint approval item
- Renumber existing items

- [ ] **Step 5: Update the description line**

Change step count from "10 steps" to "11 steps" in the opening paragraph. Update the description to mention interactive intake: "Produces positioning, competitive analysis, and go-to-market documents grounded in interactive discovery and web research, validated through assessment, cross-talk, elicitation, and convergence."

- [ ] **Step 6: Run validate.sh**

```bash
bash scripts/validate.sh
```

Expected: passes. The `research-external` agent exists from Task 1, so the cross-check will find it. The `**Await external research**` step has no `**Agent:**` line, so it won't trigger cross-check.

- [ ] **Step 7: Commit**

```bash
git add playbooks/market-strategy.md
git commit -m "Add interactive intake, external research, and checkpoint to market-strategy playbook"
```

---

### Task 3: Add intake and revised flow to brand-exploration playbook

**Files:**
- Modify: `playbooks/brand-exploration.md`

- [ ] **Step 1: Read the current playbook**

```bash
cat playbooks/brand-exploration.md
```

Same structural changes as Task 2 but with brand-specific questions and 13 steps total.

- [ ] **Step 2: Add the `## Intake` section**

Insert after the opening description and before `## Steps`. Same structure as market-strategy but with brand-specific questions:

1. What should this brand communicate — what's the core message or feeling? (context: emotional territory, redirect features to feelings)
2. Who is the audience, and what visual language do they respond to? (context: demographics AND design sensibilities)
3. Name 2-4 brands whose visual feel you admire, and what specifically you like about each. (context: concrete references, not adjectives — mood board anchors)
4. What should this brand absolutely NOT look like? (context: anti-references, prevent drift)
5. What existing brand assets or design constraints exist? (context: current logo, colors, WCAG, dark mode — hard constraints)
6. What's the competitive visual landscape — how do competitors look, and where do you want to differentiate? (context: drives visual competitor analysis)
7. Is there a timeline or deliverable trigger — what will these brand visuals be used for? (context: changes specificity needed)

- [ ] **Step 3: Rewrite the Steps section**

New step structure (13 steps total):

**Step 1 — Research codebase:** Same agent, add `intake-brief.md` to upstream.

**Step 2 — Await external research (NEW):** Synchronization point. Output: `.loom/artifacts/{ticket_id}/external-research.md`

**Step 3 — Draft brand spec:** Same agent (`draft-brand-spec`). Updated upstream:
- `.loom/artifacts/{ticket_id}/intake-brief.md`
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/external-research.md`

Add: `**Checkpoint:** Approve draft direction before assessment pipeline`

**Steps 4-13:** Renumber from current steps 3-12. Add `intake-brief.md` and `external-research.md` to upstream for assess step (now 4) and both convergence steps (now 10 and 12). Visual creation and visual convergence (now 11-12) stay unchanged except for renumbering.

- [ ] **Step 4: Update pre-completion checklist and description**

Same pattern as Task 2 — add intake/research/checkpoint items, renumber, update step count to 13, update description to mention interactive intake.

- [ ] **Step 5: Run validate.sh**

```bash
bash scripts/validate.sh
```

- [ ] **Step 6: Commit**

```bash
git add playbooks/brand-exploration.md
git commit -m "Add interactive intake, external research, and checkpoint to brand-exploration playbook"
```

---

### Task 4: Update `draft-strategy` agent

**Files:**
- Modify: `agents/draft-strategy/AGENT.md`

- [ ] **Step 1: Read the current agent**

```bash
cat agents/draft-strategy/AGENT.md
```

- [ ] **Step 2: Rewrite the agent to be intake-brief-first**

Key changes to the agent:

**Description:** Update to reflect the new flow — "Produces a market or product strategy document by synthesizing user intent from the intake brief, external research, and codebase context."

**Role line:** Update — synthesize user intent from the intake brief + real market data from external research + product context from codebase research into a strategy document. Leave discovery to the intake process and codebase exploration to research-codebase-arch.

**Constraints:** Update:
1. Ground the strategy in the intake brief first — the user's own words about their strategic question, competitors, audience, and constraints are the primary source of truth.
2. Treat external research (competitor analysis, market data) as evidence that supports or challenges the user's framing. Cite sources from external-research.md when referencing market claims.
3. Brand-toolkit skills become optional enrichment — invoke only when the intake brief suggests brand-adjacent strategic questions (positioning, messaging). Don't use them as the backbone of the analysis.
4. Every recommendation must include Alternatives Considered with trade-offs (keep from current).
5. Include a Decision Log section (keep from current).

**Process:** Rewrite to:
1. Read the intake brief, external research, and codebase research from upstream_artifacts.
2. Map the user's strategic question (from intake) to the evidence gathered (from external research). Where the user's assumptions about competitors or market differ from web research findings, note the discrepancy explicitly.
3. If the intake brief suggests brand-adjacent questions AND brand-toolkit plugins are available, invoke relevant brand-toolkit skills via the Skill tool as supplementary analysis. Otherwise skip.
4. Synthesize into a cohesive strategy document: the user's intent provides direction, external research provides evidence, codebase research provides product context.
5. Structure the document using the existing output template (Executive Summary → Strategic Question → Market Context → Positioning → Competitive Landscape → Recommendations → Decision Log → Success Metrics → Next Steps).
6. Write to output_path.

**Output format:** Keep the existing template unchanged — it's already good.

- [ ] **Step 3: Run validate.sh**

```bash
bash scripts/validate.sh
```

- [ ] **Step 4: Commit**

```bash
git add agents/draft-strategy/AGENT.md
git commit -m "Shift draft-strategy from brand-toolkit-first to intake-brief-first synthesis"
```

---

### Task 5: Update `draft-brand-spec` agent

**Files:**
- Modify: `agents/draft-brand-spec/AGENT.md`

- [ ] **Step 1: Read the current agent**

```bash
cat agents/draft-brand-spec/AGENT.md
```

- [ ] **Step 2: Rewrite the agent to be intake-brief-first**

Key changes:

**Description:** Update — "Produces a brand creative brief from user-articulated direction (intake brief), external competitor analysis, and codebase context."

**Role line:** Update — structure and refine the brand direction the user articulated during intake into a creative brief that guides visual exploration. Leave discovery to the intake process, codebase exploration to research-codebase-arch, and visual creation to explore-brand-visuals.

**Constraints:** Update:
1. Visual territory, mood references, and anti-references come from the user's intake answers — don't invent new ones. Refine and structure what the user provided.
2. Use external research (competitor visual identities, design trends) to validate and enrich the user's direction. When external research reveals a gap or contradiction with the user's stated references, note it in the Alternatives Considered section.
3. Concrete references over abstract adjectives (keep from current) — but now the intake already provides these. The agent's job is to structure them, not generate them.
4. Define concrete deliverables with evaluation criteria (keep from current).
5. Ground in the intake brief's constraints section — WCAG, dark mode, existing assets are hard constraints.

**Process:** Rewrite to:
1. Read the intake brief, external research, and codebase research from upstream_artifacts.
2. Read existing brand context: `config.context.brand_voice` (if set) for voice-to-visual alignment, `config.context.design_system` (if set) for current visual state. These supplement the intake brief.
3. Structure the user's brand direction from the intake brief into the spec format: map their emotional territory answers to Personality, their brand references to Mood References, their anti-references to Anti-References.
4. Enrich with external research: competitor visual analysis informs Constraints and Alternatives Considered. Design trend data validates or challenges the user's direction.
5. Define deliverables with evaluation criteria derived from the intake brief's success criteria and constraints.
6. Write to output_path.

**Output format:** Keep the existing template unchanged.

- [ ] **Step 3: Run validate.sh**

```bash
bash scripts/validate.sh
```

- [ ] **Step 4: Commit**

```bash
git add agents/draft-brand-spec/AGENT.md
git commit -m "Shift draft-brand-spec from inference to user-articulated direction via intake brief"
```

---

### Task 6: Add intake handling to orchestrator

**Files:**
- Modify: `skills/work/SKILL.md`

- [ ] **Step 1: Read the current orchestrator**

```bash
cat skills/work/SKILL.md
```

Identify the insertion point — the new subsections go in Phase 2: EXECUTE PLAYBOOK, before the "Playbook execution" subsection.

- [ ] **Step 2: Add the "Intake handling" subsection**

Insert a new `### Intake handling` subsection before `### Playbook execution`. Content:

After reading the playbook (but before executing step 1), check for a `## Intake` section. If absent, skip to step 1 as normal.

If present:

1. Read the `### Stance` line. Present the three-stance choice to the user: "(a) Facilitate — I ask structured questions, you provide the vision. (b) Collaborate — we trade ideas back and forth. (c) Autonomous — I infer from the ticket and existing context, ask only if blocked."

2. Based on stance:
   - **Facilitate:** Read `### Questions`. Ask them one at a time. Each question has a `context:` hint — use it to assess answer sufficiency. If the answer is thin (one word, no specifics), probe once: "Can you say more about [specific aspect from context hint]?" Then move on. After all questions, present a summary: "Here's what I captured: [bullets]. Anything to add or correct?" Loop until the user confirms.
   - **Collaborate:** Same questions but conversational — offer observations between questions based on what is being learned. Still one question at a time.
   - **Autonomous:** Map each question to the ticket description. A question is "answered" if the ticket contains a concrete response matching the context hint (named entities, specific constraints, measurable criteria). If fewer than 3 of 7 questions are answered by the ticket, halt: "Autonomous mode blocked — ticket is too sparse. Missing: [list]. Switch to facilitate/collaborate, or enrich the ticket." If 3+ are answered, infer the rest and note inferences in the Orchestrator Notes section of the intake brief.

3. **Scope policing:** If answers suggest scope exceeds one playbook run (multiple product lines, multiple markets, multiple brands), flag: "This sounds like N separate [strategy/brand] tickets. Want to narrow scope, or proceed with everything?"

4. **Parallel fan-out:** After the user answers the competitors/landscape question, spawn `research-external` in the background via Agent tool with `run_in_background: true`. Pass a partial intake brief (playbook type + strategic question/brand goal + competitive context) as upstream. If WebSearch tool is unavailable (check tool availability), skip — log "External research skipped (WebSearch unavailable)" and proceed.

5. Write the intake brief to `.loom/artifacts/{ticket_id}/intake-brief.md`. Format: `## Playbook Type`, `## Strategic Question / Brand Goal`, `## Audience`, `## Competitive Context`, `## Current State`, `## Constraints & Non-Negotiables`, `## Success Criteria`, `## References & Existing Research`, `## Anti-References` (brand-exploration only), `## Orchestrator Notes`. Register via addReferences.

- [ ] **Step 3: Add the "Checkpoint handling" subsection**

Insert after "Intake handling", before "Playbook execution". Content:

When a playbook step has a `**Checkpoint:**` field and the agent completes successfully:

1. Read the agent's output artifact.
2. Extract section headers and first sentence of each section as summary bullets.
3. Present to user: "Draft [type] ready. Key points: [bullets]. The assessment pipeline runs next — redirecting now is cheap, redirecting after is expensive. Approve, redirect, or abort?"
4. Responses:
   - **Approve:** proceed to next step.
   - **Redirect:** user provides notes. Spawn apply-review-fixes with redirect notes as upstream. Revise draft in place. Re-present checkpoint.
   - **Abort:** follow error handling (revert ticket status, release lock, stop).

- [ ] **Step 4: Add the "Await step handling" subsection**

Insert after "Checkpoint handling". Content:

When a playbook step has no `**Agent:**` field but has an `**Output path:**`, it is a synchronization point for a background agent. The orchestrator checks if the background agent (spawned during intake) has completed. If not, wait. When complete: verify the output file exists and is non-empty. If the agent failed or output is missing, log the failure and continue without external research — do not block the pipeline.

- [ ] **Step 5: Run validate.sh**

```bash
bash scripts/validate.sh
```

Expected: passes — no structural changes to SKILL.md frontmatter.

- [ ] **Step 6: Commit**

```bash
git add skills/work/SKILL.md
git commit -m "Add intake handling, checkpoint gates, and await-step logic to orchestrator"
```

---

### Task 7: Update README pipeline diagrams

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Read the current pipeline sections**

Read the market-strategy and brand-exploration pipeline diagram sections in README.md.

- [ ] **Step 2: Update market-strategy pipeline diagram**

Replace the current market-strategy section. New version:

Update description: "Market and product strategy — positioning, competitive analysis, go-to-market. Grounded in interactive discovery and web research. For technical architecture decisions, use `type:implementation`. Artifact-only — no code, no PR. 11 steps."

New diagram showing:
```
 I ── INTAKE ─────────────────── stance → questions → intake-brief.md
 │                                 ↳ research-external spawned in background
 │
 1 ── research-codebase-arch ────── explore product/market context
 2 ── await external research ───── web competitor + market data
 3 ── draft-strategy ────────────── synthesize intake + research into strategy
 │    CHECKPOINT ────────────────── human approves direction
 │
 │    ┌─ ASSESS (parallel, named) ──────────────────────────────────┐
 4    │ assess-inversion      assess-dependency     persona-pm      │
 │    │ assess-decomposition  assess-outsider       persona-{...}   │
 │    │ assess-analogy                                              │
 │    └────────────────── outputs: *-r1.md (initial round) ────────┘
 │
 5 ── CROSS-TALK ────────────────── SendMessage rounds (max 3)
 6 ── assess-synthesizer ────────── compile converged positions
 │
 7 ── apply-review-fixes ────────── revise strategy with synthesis
 8 ── elicit-approach ───────────── 10 methods from registry
 9 ── apply-review-fixes ────────── revise strategy with elicitation
 │
 │    ┌─ CONVERGE (max 5 rounds, 2 consecutive clean) ─────────────┐
10    │ requirements-reviewer    adversarial-reviewer                │
 │    │ simplification-reviewer  edge-case-hunter                    │
 │    │ ↻ apply-review-fixes                                        │
 │    └─────────────────────────────────────────────────────────────┘
 │
11 ── completion
```

- [ ] **Step 3: Update brand-exploration pipeline diagram**

Replace the current brand-exploration section. New version:

Update description: "Brand visual system — palette, typography, identity. Grounded in interactive discovery and web research. Dual-artifact flow: assessed spec + Impeccable-created visuals. 13 steps."

New diagram showing the same intake/research/checkpoint prefix, then the existing assess through visual convergence steps renumbered to 4-13.

- [ ] **Step 4: Update the agent catalog**

In the Doer agents table:
- Add row: `research-external` | Gather external context via web research — competitor analysis, market data, visual identity | market-strategy, brand-exploration
- Update `draft-strategy` description: "Synthesize user intent + external research + codebase context into strategy document" (remove "delegates to installed strategy plugins")
- Update `draft-brand-spec` description: "Structure user-articulated brand direction into creative brief" (remove inference language)

Update agent count: "39 agents" → "40 agents"

- [ ] **Step 5: Run validate.sh**

```bash
bash scripts/validate.sh
```

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "Update README pipelines and agent catalog for interactive intake"
```

---

### Task 8: Final validation and integration test

**Files:**
- All modified files from Tasks 1-7

- [ ] **Step 1: Run full validate.sh**

```bash
bash scripts/validate.sh
```

Verify zero errors. Pay attention to:
- `research-external` agent passes frontmatter check
- Both playbooks' agent references resolve (cross-check)
- No empty files, no missing trailing newlines
- Agent count matches README

- [ ] **Step 2: Verify playbook-agent cross-references**

Manually check that every `**Agent:**` line in both updated playbooks points to an existing agent directory:
```bash
grep -E '\*\*Agent:\*\*' playbooks/market-strategy.md playbooks/brand-exploration.md
```

Each agent name must have a matching `agents/{name}/AGENT.md`.

- [ ] **Step 3: Verify upstream path consistency**

Check that every upstream path referenced in the playbooks is produced by a prior step:
- `intake-brief.md` — produced by orchestrator intake handling (pre-step-1)
- `research.md` — produced by step 1 (research-codebase-arch)
- `external-research.md` — produced by step 2 (await research-external)
- `strategy.md` / `brand-spec.md` — produced by step 3 (draft agent)

- [ ] **Step 4: Review the full diff**

```bash
git diff main...HEAD --stat
git diff main...HEAD
```

Scan for: inconsistent step numbering, orphaned references to old step numbers, missing upstream paths, broken cross-references between orchestrator and playbook directives.

- [ ] **Step 5: Commit any fixes**

If any issues found in steps 1-4, fix them and commit:

```bash
git add -A
git commit -m "Fix integration issues from interactive intake implementation"
```
