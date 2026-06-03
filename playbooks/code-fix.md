# code-fix

Bug fix playbook. Lean pipeline — research the bug, fix it, validate the fix through convergence and testing. Requires `pr: true` for transition.

## Steps

### 1. Research

**Agent:** research-codebase-arch
**Output path:** `.loom/artifacts/{ticket_id}/research.md`

### 2. Implement

**Agent:** implement
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
**Output path:** `.loom/artifacts/{ticket_id}/changes.md`

### 3. Converge

**Agents:** requirements-reviewer, regression-analyst, simplification-reviewer, security-reviewer, edge-case-hunter, performance-reviewer (parallel)
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
- performance-reviewer: `.loom/artifacts/{ticket_id}/performance-r{N}.md`
- design-system-reviewer: `.loom/artifacts/{ticket_id}/design-system-r{N}.md`

**Feedback agent output path:** `.loom/artifacts/{ticket_id}/fixes-r{N}.md`

### 4. Verify

**Agents:** run-tests, test-coverage (parallel)

**Agent output paths:**
- run-tests: `.loom/artifacts/{ticket_id}/test-results.md`
- test-coverage: `.loom/artifacts/{ticket_id}/test-coverage.md`

**Upstream for test-coverage:** `.loom/artifacts/{ticket_id}/research.md`

**Max retries:** 2
**On failure:** If run-tests reports assertion failures or test-coverage returns `VERDICT: needs-work`, retry from step 2 with both artifacts and `.loom/artifacts/{ticket_id}/changes.md` added to implement's upstream.

### 5. Completion

`pr: true`

## Pre-completion checklist (verify before transitioning)

- [ ] research-codebase-arch produced output
- [ ] implement produced output and modified worktree
- [ ] Convergence ran (passed or hit max rounds with note)
- [ ] run-tests produced output
- [ ] test-coverage produced output
- [ ] All output paths registered via addReferences
