# code-fix

Bug fix playbook. Requires `pr: true` for transition.

## Steps

### 1. Research

**Agent:** research-codebase-arch
**Output path:** `.loom/artifacts/{ticket_id}/research.md`

Explore the codebase architecture, locate the bug, identify relevant files and patterns, and draft a proposed fix approach.

### 2. Assess approach (cognitive)

**Agents:** assess-inversion, assess-decomposition, assess-analogy, assess-dependency, assess-outsider (parallel)
**Upstream:** `.loom/artifacts/{ticket_id}/research.md`

**Agent output paths:**
- assess-inversion: `.loom/artifacts/{ticket_id}/perspective-inversion.md`
- assess-decomposition: `.loom/artifacts/{ticket_id}/perspective-decomposition.md`
- assess-analogy: `.loom/artifacts/{ticket_id}/perspective-analogy.md`
- assess-dependency: `.loom/artifacts/{ticket_id}/perspective-dependency.md`
- assess-outsider: `.loom/artifacts/{ticket_id}/perspective-outsider.md`

Five cognitive operations evaluate the proposed fix independently using method diversity (DMAD).

### 3. Assess approach (domain expertise)

**Agent:** persona-reviewer (parallel)
**Persona selection:**
  Always: pm, dev
  Dynamic (select 0-2 based on ticket content): security, data, qa, devops
**Upstream:** `.loom/artifacts/{ticket_id}/research.md`

**Agent output paths:** `.loom/artifacts/{ticket_id}/persona-{name}.md`

Domain experts evaluate the proposed fix through their professional lens.

### 4. Cross-examine assessments

**Agent:** assess-cross-talk
**Upstream:**
- `.loom/artifacts/{ticket_id}/perspective-inversion.md`
- `.loom/artifacts/{ticket_id}/perspective-decomposition.md`
- `.loom/artifacts/{ticket_id}/perspective-analogy.md`
- `.loom/artifacts/{ticket_id}/perspective-dependency.md`
- `.loom/artifacts/{ticket_id}/perspective-outsider.md`
- `.loom/artifacts/{ticket_id}/persona-*.md` (all persona outputs from step 3)
**Output path:** `.loom/artifacts/{ticket_id}/cross-talk.md`

Structured cross-examination across all independent perspectives. Identifies where cognitive operations and persona reviews converge, challenges positions with evidence, and surfaces blind spots.

### 5. Synthesize assessments

**Agent:** assess-synthesizer
**Upstream:**
- `.loom/artifacts/{ticket_id}/perspective-inversion.md`
- `.loom/artifacts/{ticket_id}/perspective-decomposition.md`
- `.loom/artifacts/{ticket_id}/perspective-analogy.md`
- `.loom/artifacts/{ticket_id}/perspective-dependency.md`
- `.loom/artifacts/{ticket_id}/perspective-outsider.md`
- `.loom/artifacts/{ticket_id}/persona-*.md` (all persona outputs from step 3)
- `.loom/artifacts/{ticket_id}/cross-talk.md`
**Output path:** `.loom/artifacts/{ticket_id}/assessment-synthesis.md`

Cross-examine all perspectives, informed by the cross-talk findings, resolve disagreements, and produce a synthesized fix approach.

### 6. Implement

**Agent:** implement
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/changes.md`

Fix the bug in the worktree using the assessed approach. Write a change summary to the output path.

### 7. Converge

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

### 8. Verify

**Agents:** run-tests, test-coverage (parallel)

**Agent output paths:**
- run-tests: `.loom/artifacts/{ticket_id}/test-results.md`
- test-coverage: `.loom/artifacts/{ticket_id}/test-coverage.md`

**Upstream for test-coverage:** `.loom/artifacts/{ticket_id}/research.md`

run-tests runs the project's test suite. test-coverage maps ticket requirements to test cases and identifies coverage gaps.

**On failure:** If run-tests reports assertion failures or test-coverage returns `VERDICT: needs-work`, retry from step 6 with both artifacts added to implement's upstream.

### 9. Completion

`pr: true`

## Pre-completion checklist (verify before transitioning)

- [ ] research-codebase-arch produced output
- [ ] Cognitive assessment completed (5 methods)
- [ ] Domain assessment completed (persona reviewers)
- [ ] Cross-examination completed
- [ ] Synthesis produced
- [ ] implement produced output and modified worktree
- [ ] Convergence ran (passed or hit max rounds with note)
- [ ] run-tests produced output
- [ ] test-coverage produced output
- [ ] All output paths registered via addReferences
