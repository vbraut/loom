# planning

Technical planning playbook. Produces a PRD validated through cognitive assessment, domain expert review, elicitation, convergence, and optional mocking.

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

### 3. Assess PRD (cognitive)

**Agents:** assess-inversion, assess-decomposition, assess-analogy, assess-dependency, assess-outsider (parallel)
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/prd.md`

**Agent output paths:**
- assess-inversion: `.loom/artifacts/{ticket_id}/perspective-inversion.md`
- assess-decomposition: `.loom/artifacts/{ticket_id}/perspective-decomposition.md`
- assess-analogy: `.loom/artifacts/{ticket_id}/perspective-analogy.md`
- assess-dependency: `.loom/artifacts/{ticket_id}/perspective-dependency.md`
- assess-outsider: `.loom/artifacts/{ticket_id}/perspective-outsider.md`

Five cognitive operations evaluate the PRD independently using method diversity (DMAD): inversion, decomposition, analogy, dependency mapping, and naive questioning. Each agent includes a confidence score for weighted synthesis.

### 4. Assess PRD (domain expertise)

**Agent:** persona-reviewer (parallel)
**Persona selection:**
  Always: pm, dev
  Dynamic (select 1-3 based on ticket content): ux, security, data, qa, craft, devops, tech-lead, architect
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/prd.md`

**Agent output paths:** `.loom/artifacts/{ticket_id}/persona-{name}.md`

Domain experts evaluate the PRD through their professional lens — decision rules, boundaries, and evaluation criteria specific to their discipline. Each includes a confidence score for weighted synthesis.

### 5. Synthesize assessments

**Agent:** assess-synthesizer
**Upstream:**
- `.loom/artifacts/{ticket_id}/perspective-inversion.md`
- `.loom/artifacts/{ticket_id}/perspective-decomposition.md`
- `.loom/artifacts/{ticket_id}/perspective-analogy.md`
- `.loom/artifacts/{ticket_id}/perspective-dependency.md`
- `.loom/artifacts/{ticket_id}/perspective-outsider.md`
- `.loom/artifacts/{ticket_id}/persona-*.md` (all persona outputs from step 4)
**Output path:** `.loom/artifacts/{ticket_id}/assessment-synthesis.md`

Cross-examine all perspectives — both cognitive operations and domain expertise — resolve disagreements, and produce a synthesized approach with consensus, tensions, and a risk register.

### 6. Elicit

**Agent:** elicit-approach
**Upstream:**
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/elicitation.md`

Stress-test the synthesized approach through 10 structured reasoning methods selected from the method registry based on context analysis.

### 7. Revise PRD

**Agent:** apply-review-fixes
**Upstream:**
- `.loom/artifacts/{ticket_id}/prd.md`
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
- `.loom/artifacts/{ticket_id}/elicitation.md`
**Output path:** `.loom/artifacts/{ticket_id}/prd-revisions.md`

Incorporate assessment and elicitation findings into the PRD.

### 8. Converge PRD

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

### 9. Create mocks

**When:** step 2 PRD describes UI changes (create-mocks self-determines; if no UI changes, it completes with "no UI changes" and step 10 is skipped)
**Agent:** create-mocks
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/prd.md`
**Output path:** `.loom/artifacts/{ticket_id}/mock-manifest.md`

Create HTML mockups for all screens and states described in the PRD using the project's design system.

### 10. Converge mocks

**When:** step 9 produced mocks (skip if create-mocks reported "no UI changes")
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

### 11. Completion

## Pre-completion checklist (verify before transitioning)

- [ ] research-codebase-arch produced output
- [ ] draft-prd produced PRD
- [ ] Cognitive assessment completed (5 methods)
- [ ] Domain assessment completed (persona reviewers)
- [ ] Synthesis produced
- [ ] Elicitation completed
- [ ] PRD revised with assessment and elicitation findings
- [ ] PRD convergence ran (passed or hit max rounds with note)
- [ ] Mocking completed (or skipped if no UI changes)
- [ ] All output paths registered via addReferences
