# code-fix

Bug fix playbook. Requires `pr: true` for transition.

## Steps

### 1. Research

**Agent:** research-codebase-arch
**Output path:** `.loom/artifacts/{ticket_id}/research.md`

Explore the codebase architecture, locate the bug, identify relevant files and patterns.

### 2. Implement

**Agent:** implement
**Upstream:** `.loom/artifacts/{ticket_id}/research.md`
**Output path:** `.loom/artifacts/{ticket_id}/changes.md`

Fix the bug in the worktree. Write a change summary to the output path.

### 3. Review

## Convergence

**Agents:** requirements-reviewer, regression-analyst, simplification-reviewer (parallel)
**Verdict logic:** AND
**Max rounds:** 3
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

**Feedback agent output path:** `.loom/artifacts/{ticket_id}/fixes-r{N}.md`

### 4. Test

**Agent:** run-tests
**Output path:** `.loom/artifacts/{ticket_id}/test-results.md`

Run the project's test suite and scan for secrets.

### 5. Completion

`pr: true`

## Pre-completion checklist

The orchestrator verifies all items before proceeding to Phase 3:

- [ ] research-codebase-arch produced output
- [ ] implement produced output and modified worktree
- [ ] Convergence ran (passed or hit max rounds with note)
- [ ] run-tests produced output (with test results and secrets scan)
- [ ] All output paths registered via addReferences
