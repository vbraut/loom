# planning

Technical planning playbook. Produces a PRD validated through assessment, cross-talk, elicitation, convergence, and optional mocking.

## Steps

### 1. Research

**Agent:** research-codebase-arch
**Output path:** `.loom/artifacts/{ticket_id}/research.md`

Explore the codebase architecture with a product focus — understand what exists today, how users interact with it, and what the planned work would touch.

### 2. Draft PRD

**Agent:** draft-prd
**Upstream:** `.loom/artifacts/{ticket_id}/research.md`
**Output path:** `.loom/artifacts/{ticket_id}/prd.md`

Create a human-readable PRD covering problem statement, requirements, user experience, constraints, alternatives considered, and acceptance criteria.

### 3. Assess PRD

**Agents:** assess-inversion, assess-decomposition, assess-analogy, assess-dependency, assess-outsider (named, parallel)
**Agent:** persona-reviewer (named, parallel)
**Persona selection:**
  Always: pm, dev
  Dynamic (select 1-3 based on ticket content): ux, security, data, qa, craft, devops, tech-lead, architect
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/prd.md`

**Agent output paths:**
- assess-inversion: `.loom/artifacts/{ticket_id}/perspective-inversion-r{R}.md`
- assess-decomposition: `.loom/artifacts/{ticket_id}/perspective-decomposition-r{R}.md`
- assess-analogy: `.loom/artifacts/{ticket_id}/perspective-analogy-r{R}.md`
- assess-dependency: `.loom/artifacts/{ticket_id}/perspective-dependency-r{R}.md`
- assess-outsider: `.loom/artifacts/{ticket_id}/perspective-outsider-r{R}.md`
- persona-{name}: `.loom/artifacts/{ticket_id}/persona-{name}-r{R}.md`

Initial assessment: `{R}=1`. Five cognitive operations and domain experts evaluate the PRD independently in parallel. Cognitive operations use method diversity (DMAD); persona reviewers evaluate through their professional lens.

### 4. Cross-talk

**Named agents:** all agents from step 3
**Max rounds:** 3
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Cross-talk: {round} rounds, not fully converged — see artifacts."

Assessment agents review each other's findings via SendMessage. Each round increments `{R}` (round 2 = first cross-talk round). Agents receive all other agents' current positions, challenge or reinforce specific points with evidence, and write updated output to their round-numbered path. Exits when all agents report converged or max rounds reached.

### 5. Synthesize assessments

**Agent:** assess-synthesizer
**Upstream:** latest round's output files:
- `.loom/artifacts/{ticket_id}/perspective-inversion-r{R}.md`
- `.loom/artifacts/{ticket_id}/perspective-decomposition-r{R}.md`
- `.loom/artifacts/{ticket_id}/perspective-analogy-r{R}.md`
- `.loom/artifacts/{ticket_id}/perspective-dependency-r{R}.md`
- `.loom/artifacts/{ticket_id}/perspective-outsider-r{R}.md`
- `.loom/artifacts/{ticket_id}/persona-*-r{R}.md` (all persona outputs)
**Output path:** `.loom/artifacts/{ticket_id}/assessment-synthesis.md`

Compile the converged positions from cross-talk into a unified approach. Agents have already debated and updated their positions — the synthesizer compiles consensus, notes any remaining tensions, and produces a self-contained approach.

### 6. Revise PRD

**Agent:** apply-review-fixes
**Upstream:**
- `.loom/artifacts/{ticket_id}/prd.md`
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/prd-synthesis-revisions.md`

Apply assessment and synthesis findings to the PRD before elicitation.

### 7. Elicit

**Agent:** elicit-approach
**Upstream:**
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/elicitation.md`

Stress-test the synthesized approach through 10 structured reasoning methods selected from the method registry based on context analysis.

### 8. Revise PRD

**Agent:** apply-review-fixes
**Upstream:**
- `.loom/artifacts/{ticket_id}/prd.md`
- `.loom/artifacts/{ticket_id}/elicitation.md`
**Output path:** `.loom/artifacts/{ticket_id}/prd-elicitation-revisions.md`

Incorporate elicitation findings into the PRD.

### 9. Converge PRD

**Agents:** requirements-reviewer, regression-analyst, simplification-reviewer, security-reviewer, edge-case-hunter, adversarial-reviewer (parallel)
**When:** config.context.design_system → also include design-system-reviewer
**Verdict logic:** AND
**Consecutive clean rounds:** 2
**Max rounds:** 5
**On needs-work:** apply-review-fixes
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "PRD convergence: {round} rounds, unresolved feedback — see artifacts."

Reviewers evaluate the PRD for completeness and risk. simplification-reviewer prevents scope bloat introduced by assessment and elicitation rounds. design-system-reviewer audits UI specifications against the project's design system (skipped if no design system configured).

**Upstream for reviewers:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/prd.md`

**Reviewer output paths:**
- requirements-reviewer: `.loom/artifacts/{ticket_id}/requirements-review-r{N}.md`
- regression-analyst: `.loom/artifacts/{ticket_id}/regression-r{N}.md`
- simplification-reviewer: `.loom/artifacts/{ticket_id}/simplification-r{N}.md`
- security-reviewer: `.loom/artifacts/{ticket_id}/security-r{N}.md`
- edge-case-hunter: `.loom/artifacts/{ticket_id}/edge-cases-r{N}.md`
- adversarial-reviewer: `.loom/artifacts/{ticket_id}/adversarial-r{N}.md`
- design-system-reviewer: `.loom/artifacts/{ticket_id}/design-system-r{N}.md`

**Feedback agent output path:** `.loom/artifacts/{ticket_id}/fixes-r{N}.md`

### 10. Create mocks

**When:** step 2 PRD describes UI changes (create-mocks self-determines; if no UI changes, it completes with "no UI changes" and step 11 is skipped)
**Agent:** create-mocks
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/prd.md`
**Output path:** `.loom/artifacts/{ticket_id}/mock-manifest.md`

Create HTML mockups for all screens and states described in the PRD using the project's design system.

### 11. Converge mocks

**When:** step 10 produced mocks (skip if create-mocks reported "no UI changes")
**Agents:** mock-alignment-reviewer (parallel)
**When:** config.context.design_system → also include design-system-reviewer
**Verdict logic:** AND
**Consecutive clean rounds:** 2
**Max rounds:** 3
**On needs-work:** apply-review-fixes
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Mock convergence: {round} rounds, unresolved feedback — see artifacts."

mock-alignment-reviewer verifies every PRD requirement has a visual representation. design-system-reviewer audits mock HTML for design system compliance (skipped if no design system configured).

**Upstream for reviewers:**
- `.loom/artifacts/{ticket_id}/prd.md`
- `.loom/artifacts/{ticket_id}/mock-manifest.md`

**Reviewer output paths:**
- mock-alignment-reviewer: `.loom/artifacts/{ticket_id}/mock-alignment-r{N}.md`
- design-system-reviewer: `.loom/artifacts/{ticket_id}/mock-design-system-r{N}.md`

**Feedback agent output path:** `.loom/artifacts/{ticket_id}/mock-fixes-r{N}.md`

### 12. Completion

## Pre-completion checklist (verify before transitioning)

- [ ] research-codebase-arch produced output
- [ ] draft-prd produced PRD
- [ ] Assessment completed (5 cognitive + persona reviewers, all in parallel)
- [ ] Cross-talk completed (converged or hit max rounds with note)
- [ ] Synthesis produced
- [ ] PRD revised with synthesis findings
- [ ] Elicitation completed
- [ ] PRD revised with elicitation findings
- [ ] PRD convergence ran (passed or hit max rounds with note)
- [ ] Mocking completed (or skipped if no UI changes)
- [ ] All output paths registered via addReferences
