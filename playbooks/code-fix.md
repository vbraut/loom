# code-fix

Bug fix playbook. Requires `pr: true` for transition.

## Steps

### 1. Research

**Agent:** research-codebase-arch
**Output path:** `.loom/artifacts/{ticket_id}/research.md`

Explore the codebase architecture, locate the bug, identify relevant files and patterns, and draft a proposed fix approach.

### 2. Assess approach

**Agents:** assess-inversion, assess-decomposition, assess-analogy, assess-dependency, assess-outsider (named, parallel)
**Agent:** persona-reviewer (named, parallel)
**Persona selection:**
  Always: pm, dev
  Dynamic (select 0-2 based on ticket content): security, data, qa, devops
**Upstream:** `.loom/artifacts/{ticket_id}/research.md`

**Agent output paths:**
- assess-inversion: `.loom/artifacts/{ticket_id}/perspective-inversion.md`
- assess-decomposition: `.loom/artifacts/{ticket_id}/perspective-decomposition.md`
- assess-analogy: `.loom/artifacts/{ticket_id}/perspective-analogy.md`
- assess-dependency: `.loom/artifacts/{ticket_id}/perspective-dependency.md`
- assess-outsider: `.loom/artifacts/{ticket_id}/perspective-outsider.md`
- persona-{name}: `.loom/artifacts/{ticket_id}/persona-{name}.md`

Five cognitive operations and domain experts evaluate the proposed fix independently in parallel. Cognitive operations use method diversity (DMAD); persona reviewers evaluate through their professional lens.

### 3. Cross-talk

**Named agents:** all agents from step 2
**Max rounds:** 3
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Cross-talk: {round} rounds, not fully converged — see artifacts."

Assessment agents review each other's findings via SendMessage. Each round, agents receive all other agents' current positions, challenge or reinforce specific points with evidence, and update their own assessment. Exits when all agents report converged (no remaining Critical/High concerns) or max rounds reached.

### 4. Synthesize assessments

**Agent:** assess-synthesizer
**Upstream:**
- `.loom/artifacts/{ticket_id}/perspective-inversion.md`
- `.loom/artifacts/{ticket_id}/perspective-decomposition.md`
- `.loom/artifacts/{ticket_id}/perspective-analogy.md`
- `.loom/artifacts/{ticket_id}/perspective-dependency.md`
- `.loom/artifacts/{ticket_id}/perspective-outsider.md`
- `.loom/artifacts/{ticket_id}/persona-*.md` (all persona outputs from step 2)
**Output path:** `.loom/artifacts/{ticket_id}/assessment-synthesis.md`

Compile the converged positions from cross-talk into a unified fix approach. Agents have already debated and updated their positions — the synthesizer compiles consensus, notes any remaining tensions, and produces a self-contained approach.

### 5. Implement

**Agent:** implement
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/changes.md`

Fix the bug in the worktree using the assessed approach. Write a change summary to the output path.

### 6. Converge

**Agents:** requirements-reviewer, regression-analyst, simplification-reviewer, security-reviewer, edge-case-hunter (parallel)
**When:** config.context.design_system → also include design-system-reviewer
**Verdict logic:** AND
**Consecutive clean rounds:** 2
**Max rounds:** 6
**On needs-work:** apply-review-fixes
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Convergence: {round} rounds, unresolved feedback — see artifacts."

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

### 7. Verify

**Agents:** run-tests, test-coverage (parallel)

**Agent output paths:**
- run-tests: `.loom/artifacts/{ticket_id}/test-results.md`
- test-coverage: `.loom/artifacts/{ticket_id}/test-coverage.md`

**Upstream for test-coverage:** `.loom/artifacts/{ticket_id}/research.md`

run-tests runs the project's test suite. test-coverage maps ticket requirements to test cases and identifies coverage gaps.

**On failure:** If run-tests reports assertion failures or test-coverage returns `VERDICT: needs-work`, retry from step 5 with both artifacts added to implement's upstream.

### 8. Completion

`pr: true`

## Pre-completion checklist (verify before transitioning)

- [ ] research-codebase-arch produced output
- [ ] Assessment completed (5 cognitive + persona reviewers, all in parallel)
- [ ] Cross-talk completed (converged or hit max rounds with note)
- [ ] Synthesis produced
- [ ] implement produced output and modified worktree
- [ ] Convergence ran (passed or hit max rounds with note)
- [ ] run-tests produced output
- [ ] test-coverage produced output
- [ ] All output paths registered via addReferences
