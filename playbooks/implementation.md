# implementation

Feature implementation playbook. Produces an implementation plan (assessed, cross-talked, elicited, and converged), then implements code and validates through convergence, testing, and visual verification. Requires `pr: true` for transition.

## Steps

### 1. Research

**Agent:** research-codebase-arch
**Output path:** `.loom/artifacts/{ticket_id}/research.md`

### 2. Draft implementation plan

**Agent:** draft-implementation-plan
**Upstream:** `.loom/artifacts/{ticket_id}/research.md`
**Output path:** `.loom/artifacts/{ticket_id}/plan.md`

### 3. Assess plan

**Agents:** assess-inversion, assess-decomposition, assess-analogy, assess-dependency, assess-outsider (named, parallel)
**Agent:** persona-reviewer (named, parallel)
**Persona selection:**
  Always: pm, dev
  Dynamic (select 1-3 based on ticket content): architect, security, data, qa, devops, tech-lead, ux, craft, analyst, end-user, sm, tech-writer
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/plan.md`

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

### 6. Revise plan

**Agent:** apply-review-fixes
**Upstream:**
- `.loom/artifacts/{ticket_id}/plan.md`
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/plan-synthesis-revisions.md`

### 7. Elicit

**Agent:** elicit-approach
**Upstream:**
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/elicitation.md`

### 8. Revise plan

**Agent:** apply-review-fixes
**Upstream:**
- `.loom/artifacts/{ticket_id}/plan.md`
- `.loom/artifacts/{ticket_id}/elicitation.md`
**Output path:** `.loom/artifacts/{ticket_id}/plan-elicitation-revisions.md`

### 9. Converge plan

**Agents:** requirements-reviewer, regression-analyst, simplification-reviewer, security-reviewer, edge-case-hunter, adversarial-reviewer, performance-reviewer (parallel)
**When:** config.context.design_system → also include design-system-reviewer
**When:** config.context.architecture_rules → also include architecture-reviewer
**Verdict logic:** AND
**Consecutive clean rounds:** 1
**Max rounds:** 5
**On needs-work:** apply-review-fixes
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Plan convergence: {round} rounds, unresolved feedback — see artifacts."

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
- performance-reviewer: `.loom/artifacts/{ticket_id}/plan-performance-r{N}.md`
- design-system-reviewer: `.loom/artifacts/{ticket_id}/plan-design-system-r{N}.md`
- architecture-reviewer: `.loom/artifacts/{ticket_id}/plan-architecture-r{N}.md`

**Feedback agent output path:** `.loom/artifacts/{ticket_id}/plan-fixes-r{N}.md`

### 10. Implement

**Agent:** implement
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/plan.md`
**Output path:** `.loom/artifacts/{ticket_id}/changes.md`

### 11. Converge code

**Agents:** requirements-reviewer, regression-analyst, simplification-reviewer, security-reviewer, edge-case-hunter, performance-reviewer (parallel)
**When:** config.context.design_system → also include design-system-reviewer
**When:** config.context.architecture_rules → also include architecture-reviewer
**Verdict logic:** AND
**Consecutive clean rounds:** 1
**Max rounds:** 6
**On needs-work:** apply-review-fixes
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Code convergence: {round} rounds, unresolved feedback — see artifacts."

**Upstream for reviewers:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/plan.md`
- `.loom/artifacts/{ticket_id}/changes.md`

**Reviewer output paths:**
- requirements-reviewer: `.loom/artifacts/{ticket_id}/requirements-review-r{N}.md`
- regression-analyst: `.loom/artifacts/{ticket_id}/regression-r{N}.md`
- simplification-reviewer: `.loom/artifacts/{ticket_id}/simplification-r{N}.md`
- security-reviewer: `.loom/artifacts/{ticket_id}/security-r{N}.md`
- edge-case-hunter: `.loom/artifacts/{ticket_id}/edge-cases-r{N}.md`
- performance-reviewer: `.loom/artifacts/{ticket_id}/performance-r{N}.md`
- design-system-reviewer: `.loom/artifacts/{ticket_id}/design-system-r{N}.md`
- architecture-reviewer: `.loom/artifacts/{ticket_id}/architecture-r{N}.md`

**Feedback agent output path:** `.loom/artifacts/{ticket_id}/fixes-r{N}.md`

### 12. Verify

**Agents:** run-tests, test-coverage (parallel)

**Agent output paths:**
- run-tests: `.loom/artifacts/{ticket_id}/test-results.md`
- test-coverage: `.loom/artifacts/{ticket_id}/test-coverage.md`

**Upstream for run-tests:** `.loom/artifacts/{ticket_id}/changes.md`
**Upstream for test-coverage:** `.loom/artifacts/{ticket_id}/research.md`

**Max retries:** 2
**On failure:** If run-tests reports assertion failures or test-coverage returns `VERDICT: needs-work`, retry from step 10 with both artifacts and `.loom/artifacts/{ticket_id}/changes.md` added to implement's upstream.
**Test-only optimization:** After the implement agent completes in a retry pass, run `git -C {worktree_path} diff --name-only {last_convergence_commit}` (where `{last_convergence_commit}` is HEAD at the point step 11 last completed). If ALL changed files match test patterns (`*.test.*`, `*.spec.*`, `**/test/**`, `**/tests/**`, `**/__tests__/**`, `**/fixtures/**`, `**/test-helpers/**`, `**/test-utils/**`), use reduced convergence in step 11: replace the full reviewer set with edge-case-hunter, requirements-reviewer, simplification-reviewer only. All other convergence fields (verdict logic, consecutive clean rounds, max rounds, on needs-work, upstream, output paths) remain unchanged. If ANY changed file does not match test patterns, run full convergence as normal.

### 13. Capture

**Skip when:** the changes are backend-only (no UI files modified — no components, pages, routes, layouts, styles, or templates changed in the worktree diff)
**Agent:** capture-screenshots
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/changes.md`
**Output path:** `.loom/artifacts/{ticket_id}/screenshots.md`

### 14. Visual verify

**Skip when:** step 13 was skipped
**Agent:** visual-parity-reviewer
**Upstream:** `.loom/artifacts/{ticket_id}/screenshots.md`
**Output path:** `.loom/artifacts/{ticket_id}/visual-parity.md`

**Max retries:** 2
**On failure:** If visual-parity-reviewer returns `VERDICT: needs-work`, retry from step 10 with the visual parity artifact and `.loom/artifacts/{ticket_id}/changes.md` added to implement's upstream.

### 15. Completion

`pr: true`

## Pre-completion checklist (verify before transitioning)

- [ ] research-codebase-arch produced output
- [ ] draft-implementation-plan produced implementation plan
- [ ] Assessment completed (5 cognitive + persona reviewers, all in parallel)
- [ ] Cross-talk completed (converged or hit max rounds with note)
- [ ] Synthesis produced
- [ ] Plan revised with synthesis findings
- [ ] Elicitation completed
- [ ] Plan revised with elicitation findings
- [ ] Plan convergence ran (passed or hit max rounds with note)
- [ ] implement produced output and modified worktree
- [ ] Code convergence ran (passed or hit max rounds with note)
- [ ] run-tests produced output
- [ ] test-coverage produced output
- [ ] capture-screenshots produced output (or skipped — backend-only)
- [ ] visual-parity-reviewer produced output (or skipped — backend-only)
- [ ] All output paths registered via addReferences
