# planning

Technical planning playbook. Produces a PRD from a spec or ticket description, validated through assessment, elicitation, and convergence review.

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

Five cognitive operations evaluate the PRD independently using method diversity (DMAD): inversion (assume it failed — what caused it?), decomposition (break into atomic claims — which are load-bearing?), analogy (what existing pattern solves this better?), dependency mapping (what blocks what — are prerequisites met?), outsider (what insider knowledge does this assume?). Each agent includes a confidence score for weighted synthesis.

### 4. Synthesize assessments

**Agent:** assess-synthesizer
**Upstream:**
- `.loom/artifacts/{ticket_id}/perspective-inversion.md`
- `.loom/artifacts/{ticket_id}/perspective-decomposition.md`
- `.loom/artifacts/{ticket_id}/perspective-analogy.md`
- `.loom/artifacts/{ticket_id}/perspective-dependency.md`
- `.loom/artifacts/{ticket_id}/perspective-outsider.md`
**Output path:** `.loom/artifacts/{ticket_id}/assessment-synthesis.md`

Cross-examine all perspectives, resolve disagreements, and produce a synthesized approach with consensus, tensions, and a risk register.

### 5. Elicit

**Agent:** elicit-approach
**Upstream:**
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/elicitation.md`

Stress-test the synthesized approach through structured reasoning methods — pre-mortem, Socratic questioning, constraint relaxation, steel-man alternatives, dependency inversion, second-order effects, assumption surfacing, counterfactual, stakeholder lens, and minimum viable test.

### 6. Revise PRD

**Agent:** apply-review-fixes
**Upstream:**
- `.loom/artifacts/{ticket_id}/prd.md`
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
- `.loom/artifacts/{ticket_id}/elicitation.md`
**Output path:** `.loom/artifacts/{ticket_id}/prd-revisions.md`

Incorporate assessment and elicitation findings into the PRD. The agent reads the synthesis and elicitation outputs and updates the PRD document accordingly.

### 7. Converge

**Agents:** requirements-reviewer, regression-analyst, security-reviewer, edge-case-hunter, adversarial-reviewer (parallel)
**Verdict logic:** AND
**Consecutive clean rounds:** 2
**Max rounds:** 5
**On needs-work:** apply-review-fixes
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "PRD convergence: {round} rounds, unresolved feedback — see artifacts."

Reviewers evaluate the PRD for completeness and risk. requirements-reviewer traces spec requirements to PRD sections. regression-analyst reads the PRD's proposed changes and traces consumer impact in the codebase. security-reviewer evaluates the PRD's security posture. edge-case-hunter identifies boundary conditions the PRD doesn't account for. adversarial-reviewer stress-tests logical consistency and identifies gaps.

**Upstream for reviewers:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/prd.md`

**Reviewer output paths:**
- requirements-reviewer: `.loom/artifacts/{ticket_id}/requirements-review-r{N}.md`
- regression-analyst: `.loom/artifacts/{ticket_id}/regression-r{N}.md`
- security-reviewer: `.loom/artifacts/{ticket_id}/security-r{N}.md`
- edge-case-hunter: `.loom/artifacts/{ticket_id}/edge-cases-r{N}.md`
- adversarial-reviewer: `.loom/artifacts/{ticket_id}/adversarial-r{N}.md`

**Feedback agent output path:** `.loom/artifacts/{ticket_id}/fixes-r{N}.md`

### 8. Completion

## Pre-completion checklist (verify before transitioning)

- [ ] research-codebase-arch produced output
- [ ] draft-prd produced PRD
- [ ] Assessment completed (5 methods + synthesis)
- [ ] Elicitation completed
- [ ] PRD revised with assessment and elicitation findings
- [ ] Convergence ran (passed or hit max rounds with note)
- [ ] All output paths registered via addReferences
