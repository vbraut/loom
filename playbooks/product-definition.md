# product-definition

Product definition playbook. Produces a PRD validated through assessment, cross-talk, elicitation, convergence, and optional mocking with elevated quality review.

## Steps

### 1. Research

**Agent:** research-codebase-arch
**Output path:** `.loom/artifacts/{ticket_id}/research.md`

### 2. Draft PRD

**Agent:** draft-prd
**Upstream:** `.loom/artifacts/{ticket_id}/research.md`
**Output path:** `.loom/artifacts/{ticket_id}/prd.md`

### 3. Assess PRD

**Agents:** assess-inversion, assess-decomposition, assess-analogy, assess-dependency, assess-outsider (named, parallel)
**Agent:** persona-reviewer (named, parallel)
**Persona selection:**
  Always: pm, dev
  Dynamic (select 1-3 based on ticket content): ux, security, data, qa, craft, devops, tech-lead, architect, analyst, end-user, sm, tech-writer
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

### 4. Cross-talk

**Named agents:** all agents from step 3
**Max rounds:** 3
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Cross-talk: {round} rounds, not fully converged — see artifacts."

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

### 6. Revise PRD with synthesis

**Agent:** apply-review-fixes
**Upstream:**
- `.loom/artifacts/{ticket_id}/prd.md`
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/prd-synthesis-revisions.md`

Note: apply-review-fixes modifies `prd.md` in the worktree in place (revision mode). The output path records what changed. All subsequent steps that reference `prd.md` get the post-synthesis version.

### 7. Elicit

**Agent:** elicit-approach
**Upstream:**
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/elicitation.md`

### 8. Revise PRD with elicitation

**Agent:** apply-review-fixes
**Upstream:**
- `.loom/artifacts/{ticket_id}/prd.md`
- `.loom/artifacts/{ticket_id}/elicitation.md`
**Output path:** `.loom/artifacts/{ticket_id}/prd-elicitation-revisions.md`

Note: Reads the post-synthesis `prd.md` (modified in place by step 6). Changes are cumulative.

### 9. Converge PRD

**Agents:** requirements-reviewer, regression-analyst, simplification-reviewer, security-reviewer, edge-case-hunter, adversarial-reviewer (parallel)
**When:** config.context.design_system → also include design-system-reviewer
**Verdict logic:** AND
**Consecutive clean rounds:** 2
**Max rounds:** 5
**On needs-work:** apply-review-fixes
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "PRD convergence: {round} rounds, unresolved feedback — see artifacts."

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

### 10. Capture screenshots

**When:** ticket touches existing UI routes (orchestrator checks whether the converged PRD references routes that exist in the codebase)
**Agent:** capture-screenshots
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/prd.md`
**Output path:** `.loom/artifacts/{ticket_id}/screenshots-manifest.md`

### 11. Create mocks

**Skip when:** no UI changes (PRD contains no user-facing interface requirements)
**Agent:** create-mocks
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/prd.md`
- `.loom/artifacts/{ticket_id}/screenshots-manifest.md` (when step 10 ran)
**Output path:** `.loom/artifacts/{ticket_id}/mock-manifest.md`

### 12. Converge mocks

**Skip when:** create-mocks output contains "no UI changes" or step 11 was skipped
**Agents:** mock-alignment-reviewer, critique, optimize, harden, polish (parallel)
**When:** config.context.design_system → also include design-system-reviewer
**Verdict logic:** AND
**Consecutive clean rounds:** 2
**Max rounds:** 5
**On needs-work:** apply-review-fixes
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Mock convergence: {round} rounds, unresolved feedback — see artifacts."

**Upstream for reviewers:**
- `.loom/artifacts/{ticket_id}/prd.md`
- `.loom/artifacts/{ticket_id}/mock-manifest.md`

**Reviewer output paths:**
- mock-alignment-reviewer: `.loom/artifacts/{ticket_id}/mock-alignment-r{N}.md`
- design-system-reviewer: `.loom/artifacts/{ticket_id}/mock-design-system-r{N}.md`
- critique: `.loom/artifacts/{ticket_id}/mock-critique-r{N}.md`
- optimize: `.loom/artifacts/{ticket_id}/mock-optimize-r{N}.md`
- harden: `.loom/artifacts/{ticket_id}/mock-harden-r{N}.md`
- polish: `.loom/artifacts/{ticket_id}/mock-polish-r{N}.md`

**Feedback agent output path:** `.loom/artifacts/{ticket_id}/mock-fixes-r{N}.md`

### 13. Completion

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
- [ ] Screenshots captured (or skipped if no existing UI routes)
- [ ] Mocking completed (or skipped if no UI changes)
- [ ] Mock convergence ran with all 6 reviewers (or skipped if no mocks)
- [ ] All output paths registered via addReferences
