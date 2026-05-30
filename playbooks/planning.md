# planning

Technical planning playbook. Produces an implementation plan from a PRD or spec.

## Steps

### 1. Research

**Agent:** research-codebase-arch
**Output path:** `.loom/artifacts/{ticket_id}/research.md`

Explore the codebase architecture, locate relevant files and patterns for the planned work.

### 2. Plan

**Agent:** draft-plan
**Upstream:** `.loom/artifacts/{ticket_id}/research.md`
**Output path:** `.loom/artifacts/{ticket_id}/plan.md`

Create a technical implementation plan from the spec and research brief.

### 3. Converge

**Agents:** requirements-reviewer, regression-analyst (parallel)
**Verdict logic:** AND
**Max rounds:** 3
**On needs-work:** apply-review-fixes
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Plan convergence: {round} rounds, unresolved feedback — see artifacts."

Reviewers evaluate the plan content for completeness and risk — the diff is just the plan document being added, not code changes. requirements-reviewer traces spec requirements to plan items. regression-analyst reads the plan's proposed file changes and traces consumer impact in the codebase.

**Upstream for reviewers:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/plan.md`

**Reviewer output paths:**
- requirements-reviewer: `.loom/artifacts/{ticket_id}/requirements-review-r{N}.md`
- regression-analyst: `.loom/artifacts/{ticket_id}/regression-r{N}.md`

**Feedback agent output path:** `.loom/artifacts/{ticket_id}/fixes-r{N}.md`

### 4. Completion

## Pre-completion checklist (verify before transitioning)

- [ ] research-codebase-arch produced output
- [ ] draft-plan produced output
- [ ] Convergence ran (passed or hit max rounds with note)
- [ ] All output paths registered via addReferences
