# market-strategy

Market and product strategy playbook. Produces positioning, competitive analysis, and go-to-market documents grounded in interactive discovery and web research, validated through assessment, cross-talk, elicitation, and convergence. For technical architecture decisions, use `type:implementation` instead. Artifact-only — no code, no PR.

## Intake

### Stance

facilitate | collaborate | autonomous

### Questions

1. What strategic question needs answering?
   context: The core decision — "should we enter market X", "how to position against Y", "pricing strategy for Z". Must be specific enough to produce actionable recommendations.

2. Who are your top 3-5 competitors, and what do you see as their positioning?
   context: Named competitors with brief descriptions. If the user can't name any, that's a signal for heavier web research.

3. Who is the target audience, and what do they care about most?
   context: Specific segments, not "everyone". Needs at least one concrete persona or segment description.

4. What's your current positioning — how do customers describe you today?
   context: The gap between current and desired positioning drives the strategy. "We don't have positioning yet" is a valid answer that changes the output shape.

5. What constraints or non-negotiables should the strategy respect?
   context: Budget, timeline, team size, technical limitations, partnerships, regulatory. These bound the recommendation space.

6. What does success look like in 6-12 months?
   context: Measurable outcomes, not aspirations. Revenue targets, market share, user counts, partnerships closed.

7. What existing research or context do you already have?
   context: Links to docs, prior strategies, market research, user interviews. Anything the user already has that should feed into the analysis.

## Steps

### 1. Research

**Agent:** research-codebase-arch
**Upstream:** `.loom/artifacts/{ticket_id}/intake-brief.md`
**Output path:** `.loom/artifacts/{ticket_id}/research.md`

### 2. Await external research

**Output path:** `.loom/artifacts/{ticket_id}/external-research.md`

### 3. Draft strategy

**Agent:** draft-strategy
**Upstream:**
- `.loom/artifacts/{ticket_id}/intake-brief.md`
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/external-research.md` (optional)
**Output path:** `.loom/artifacts/{ticket_id}/strategy.md`
**Checkpoint:** Approve draft direction before assessment pipeline

### 4. Assess strategy

**Agents:** assess-inversion, assess-decomposition, assess-analogy, assess-dependency, assess-outsider (named, parallel)
**Agent:** persona-reviewer (named, parallel)
**Persona selection:**
  Always: pm
  Dynamic (select 1-3 based on ticket content): dev, analyst, architect, data, end-user, tech-lead, security, sm, qa, devops, ux, craft, tech-writer
**Upstream:**
- `.loom/artifacts/{ticket_id}/intake-brief.md`
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/external-research.md` (optional)
- `.loom/artifacts/{ticket_id}/strategy.md`

**Agent output paths:**
- assess-inversion: `.loom/artifacts/{ticket_id}/perspective-inversion-r{R}.md`
- assess-decomposition: `.loom/artifacts/{ticket_id}/perspective-decomposition-r{R}.md`
- assess-analogy: `.loom/artifacts/{ticket_id}/perspective-analogy-r{R}.md`
- assess-dependency: `.loom/artifacts/{ticket_id}/perspective-dependency-r{R}.md`
- assess-outsider: `.loom/artifacts/{ticket_id}/perspective-outsider-r{R}.md`
- persona-{name}: `.loom/artifacts/{ticket_id}/persona-{name}-r{R}.md`

### 5. Cross-talk

**Named agents:** all agents from step 4
**Max rounds:** 3
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Cross-talk: {round} rounds, not fully converged — see artifacts."

### 6. Synthesize assessments

**Agent:** assess-synthesizer
**Upstream:** latest round's output files:
- `.loom/artifacts/{ticket_id}/perspective-inversion-r{R}.md`
- `.loom/artifacts/{ticket_id}/perspective-decomposition-r{R}.md`
- `.loom/artifacts/{ticket_id}/perspective-analogy-r{R}.md`
- `.loom/artifacts/{ticket_id}/perspective-dependency-r{R}.md`
- `.loom/artifacts/{ticket_id}/perspective-outsider-r{R}.md`
- `.loom/artifacts/{ticket_id}/persona-*-r{R}.md` (all persona outputs)
**Output path:** `.loom/artifacts/{ticket_id}/assessment-synthesis.md`

### 7. Revise strategy with synthesis

**Agent:** apply-review-fixes
**Upstream:**
- `.loom/artifacts/{ticket_id}/strategy.md`
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/strategy-synthesis-revisions.md`

Note: apply-review-fixes modifies the strategy document in the worktree in place (revision mode). The output path records what changed.

### 8. Elicit

**Agent:** elicit-approach
**Upstream:**
- `.loom/artifacts/{ticket_id}/strategy.md`
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/elicitation.md`

Note: Reads the post-synthesis `strategy.md` (modified in place by step 7) — elicitation stress-tests the revised strategy, with the synthesis as context for what assessment already covered.

### 9. Revise strategy with elicitation

**Agent:** apply-review-fixes
**Upstream:**
- `.loom/artifacts/{ticket_id}/strategy.md`
- `.loom/artifacts/{ticket_id}/elicitation.md`
**Output path:** `.loom/artifacts/{ticket_id}/strategy-elicitation-revisions.md`

### 10. Converge

**Agents:** requirements-reviewer, simplification-reviewer, adversarial-reviewer, edge-case-hunter (parallel)
**Verdict logic:** AND
**Consecutive clean rounds:** 1
**Max rounds:** 5
**On needs-work:** apply-review-fixes
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Convergence: {round} rounds, unresolved feedback — see artifacts."

**Upstream for reviewers:**
- `.loom/artifacts/{ticket_id}/intake-brief.md`
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/external-research.md` (optional)
- `.loom/artifacts/{ticket_id}/strategy.md`

**Reviewer output paths:**
- requirements-reviewer: `.loom/artifacts/{ticket_id}/requirements-review-r{N}.md`
- simplification-reviewer: `.loom/artifacts/{ticket_id}/simplification-r{N}.md`
- adversarial-reviewer: `.loom/artifacts/{ticket_id}/adversarial-r{N}.md`
- edge-case-hunter: `.loom/artifacts/{ticket_id}/edge-cases-r{N}.md`

**Feedback agent output path:** `.loom/artifacts/{ticket_id}/fixes-r{N}.md`

### 11. Completion

## Pre-completion checklist (verify before transitioning)

- [ ] Intake brief produced (or autonomous inference completed)
- [ ] External research completed (or skipped gracefully if web unavailable)
- [ ] Draft checkpoint approved
- [ ] research-codebase-arch produced output
- [ ] draft-strategy produced strategy document
- [ ] Assessment completed (5 cognitive + persona reviewers, all in parallel)
- [ ] Cross-talk completed (converged, hit max rounds with note, or skipped — no Critical/High concerns)
- [ ] Synthesis produced
- [ ] Strategy revised with synthesis findings
- [ ] Elicitation completed
- [ ] Strategy revised with elicitation findings
- [ ] Convergence ran (passed or hit max rounds with note)
- [ ] All output paths recorded in progress.md (the artifact ledger the review phase resolves from)
