# implementation

Feature implementation playbook. Produces an implementation plan (assessed, cross-talked, elicited, and converged), then implements code and validates through convergence, testing, and visual verification. Requires `pr: true` for transition.

## Steps

### 1. Research

**Agent:** research-codebase-arch
**Output path:** `.loom/artifacts/{ticket_id}/research.md`

Explore the codebase architecture with a code focus — locate relevant files, trace dependency chains, identify patterns, and draft a proposed implementation approach.

### 2. Draft implementation plan

**Agent:** draft-implementation-plan
**Upstream:** `.loom/artifacts/{ticket_id}/research.md`
**Output path:** `.loom/artifacts/{ticket_id}/plan.md`

Create a technical implementation plan mapping requirements to file changes, ordered by dependency, with alternatives considered and test expectations.

### 3. Assess plan

**Agents:** assess-inversion, assess-decomposition, assess-analogy, assess-dependency, assess-outsider (named, parallel)
**Agent:** persona-reviewer (named, parallel)
**Persona selection:**
  Always: pm, dev
  Dynamic (select 1-3 based on ticket content): architect, security, data, qa, devops, tech-lead
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/plan.md`

**Agent output paths:**
- assess-inversion: `.loom/artifacts/{ticket_id}/perspective-inversion.md`
- assess-decomposition: `.loom/artifacts/{ticket_id}/perspective-decomposition.md`
- assess-analogy: `.loom/artifacts/{ticket_id}/perspective-analogy.md`
- assess-dependency: `.loom/artifacts/{ticket_id}/perspective-dependency.md`
- assess-outsider: `.loom/artifacts/{ticket_id}/perspective-outsider.md`
- persona-{name}: `.loom/artifacts/{ticket_id}/persona-{name}.md`

Five cognitive operations and domain experts evaluate the implementation plan independently in parallel. Cognitive operations use method diversity (DMAD); persona reviewers evaluate through their professional lens.

### 4. Cross-talk

**Named agents:** all agents from step 3
**Max rounds:** 3
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Cross-talk: {round} rounds, not fully converged — see artifacts."

Assessment agents review each other's findings via SendMessage. Each round, agents receive all other agents' current positions, challenge or reinforce specific points with evidence, and update their own assessment. Exits when all agents report converged (no remaining Critical/High concerns) or max rounds reached.

### 5. Synthesize assessments

**Agent:** assess-synthesizer
**Upstream:**
- `.loom/artifacts/{ticket_id}/perspective-inversion.md`
- `.loom/artifacts/{ticket_id}/perspective-decomposition.md`
- `.loom/artifacts/{ticket_id}/perspective-analogy.md`
- `.loom/artifacts/{ticket_id}/perspective-dependency.md`
- `.loom/artifacts/{ticket_id}/perspective-outsider.md`
- `.loom/artifacts/{ticket_id}/persona-*.md` (all persona outputs from step 3)
**Output path:** `.loom/artifacts/{ticket_id}/assessment-synthesis.md`

Compile the converged positions from cross-talk into a unified implementation approach. Agents have already debated and updated their positions — the synthesizer compiles consensus, notes any remaining tensions, and produces a self-contained approach.

### 6. Elicit

**Agent:** elicit-approach
**Upstream:**
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/elicitation.md`

Stress-test the synthesized approach through 10 structured reasoning methods selected from the method registry.

### 7. Revise plan

**Agent:** apply-review-fixes
**Upstream:**
- `.loom/artifacts/{ticket_id}/plan.md`
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
- `.loom/artifacts/{ticket_id}/elicitation.md`
**Output path:** `.loom/artifacts/{ticket_id}/plan-revisions.md`

Incorporate assessment and elicitation findings into the implementation plan.

### 8. Converge plan

**Agents:** requirements-reviewer, regression-analyst, simplification-reviewer, security-reviewer, edge-case-hunter, adversarial-reviewer (parallel)
**Verdict logic:** AND
**Consecutive clean rounds:** 2
**Max rounds:** 5
**On needs-work:** apply-review-fixes
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Plan convergence: {round} rounds, unresolved feedback — see artifacts."

Reviewers evaluate the implementation plan for completeness and risk. simplification-reviewer catches unnecessary complexity and scope bloat from assessment rounds.

**Upstream for reviewers:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/plan.md`

**Reviewer output paths:**
- requirements-reviewer: `.loom/artifacts/{ticket_id}/plan-requirements-r{N}.md`
- regression-analyst: `.loom/artifacts/{ticket_id}/plan-regression-r{N}.md`
- simplification-reviewer: `.loom/artifacts/{ticket_id}/plan-simplification-r{N}.md`
- security-reviewer: `.loom/artifacts/{ticket_id}/plan-security-r{N}.md`
- edge-case-hunter: `.loom/artifacts/{ticket_id}/plan-edge-cases-r{N}.md`
- adversarial-reviewer: `.loom/artifacts/{ticket_id}/plan-adversarial-r{N}.md`

**Feedback agent output path:** `.loom/artifacts/{ticket_id}/plan-fixes-r{N}.md`

### 9. Implement

**Agent:** implement
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/plan.md`
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/changes.md`

Implement the changes described in the converged plan. The plan has been assessed, elicited, and converged — follow it directly. Write a change summary to the output path.

### 10. Converge code

**Agents:** requirements-reviewer, regression-analyst, simplification-reviewer, security-reviewer, edge-case-hunter (parallel)
**When:** config.context.design_system → also include design-system-reviewer
**Verdict logic:** AND
**Consecutive clean rounds:** 2
**Max rounds:** 6
**On needs-work:** apply-review-fixes
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Code convergence: {round} rounds, unresolved feedback — see artifacts."

Reviewers evaluate the implemented code changes. design-system-reviewer audits UI code for design system compliance (skipped if no design system configured).

**Upstream for reviewers:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/changes.md`

**Reviewer output paths:**
- requirements-reviewer: `.loom/artifacts/{ticket_id}/requirements-review-r{N}.md`
- regression-analyst: `.loom/artifacts/{ticket_id}/regression-r{N}.md`
- simplification-reviewer: `.loom/artifacts/{ticket_id}/simplification-r{N}.md`
- security-reviewer: `.loom/artifacts/{ticket_id}/security-r{N}.md`
- edge-case-hunter: `.loom/artifacts/{ticket_id}/edge-cases-r{N}.md`
- design-system-reviewer: `.loom/artifacts/{ticket_id}/design-system-r{N}.md`

**Feedback agent output path:** `.loom/artifacts/{ticket_id}/fixes-r{N}.md`

### 11. Verify

**Agents:** run-tests, test-coverage (parallel)

**Agent output paths:**
- run-tests: `.loom/artifacts/{ticket_id}/test-results.md`
- test-coverage: `.loom/artifacts/{ticket_id}/test-coverage.md`

**Upstream for test-coverage:** `.loom/artifacts/{ticket_id}/research.md`

run-tests runs the project's test suite. test-coverage maps ticket requirements to test cases and identifies coverage gaps.

**On failure:** If run-tests reports assertion failures or test-coverage returns `VERDICT: needs-work`, retry from step 9 with both artifacts added to implement's upstream.

### 12. Capture

**Agent:** capture-screenshots
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/changes.md`
**Output path:** `.loom/artifacts/{ticket_id}/screenshots.md`

Capture the running application at mobile and desktop viewports.

### 13. Visual verify

**Agent:** visual-parity-reviewer
**Upstream:** `.loom/artifacts/{ticket_id}/screenshots.md`
**Output path:** `.loom/artifacts/{ticket_id}/visual-parity.md`

Compare captured screenshots against mock or reference images.

**On failure:** If visual-parity-reviewer returns `VERDICT: needs-work`, retry from step 9 with the visual parity artifact added to implement's upstream.

### 14. Completion

`pr: true`

## Pre-completion checklist (verify before transitioning)

- [ ] research-codebase-arch produced output
- [ ] draft-implementation-plan produced implementation plan
- [ ] Assessment completed (5 cognitive + persona reviewers, all in parallel)
- [ ] Cross-talk completed (converged or hit max rounds with note)
- [ ] Synthesis produced
- [ ] Elicitation completed
- [ ] Plan revised with assessment and elicitation findings
- [ ] Plan convergence ran (passed or hit max rounds with note)
- [ ] implement produced output and modified worktree
- [ ] Code convergence ran (passed or hit max rounds with note)
- [ ] run-tests produced output
- [ ] test-coverage produced output
- [ ] capture-screenshots produced output
- [ ] visual-parity-reviewer produced output
- [ ] All output paths registered via addReferences
