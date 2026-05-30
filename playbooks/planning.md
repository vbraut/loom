# planning

Technical planning playbook. Produces an implementation plan from a PRD or spec.

## Steps

### 1. Research

**Agent:** research-codebase-arch
**Output path:** `.loom/artifacts/{ticket_id}/research.md`

Explore the codebase architecture, locate relevant files and patterns for the planned work.

### 2. Debate approach

**Agents:** debate-architect, debate-implementer, debate-critic, debate-user (parallel)
**Upstream:** `.loom/artifacts/{ticket_id}/research.md`

**Agent output paths:**
- debate-architect: `.loom/artifacts/{ticket_id}/perspective-architect.md`
- debate-implementer: `.loom/artifacts/{ticket_id}/perspective-implementer.md`
- debate-critic: `.loom/artifacts/{ticket_id}/perspective-critic.md`
- debate-user: `.loom/artifacts/{ticket_id}/perspective-user.md`

Four perspectives evaluate the proposed approach independently (no agent sees another's output). Each reads the codebase and forms a position on the approach's strengths, concerns, and recommended adjustments.

### 3. Synthesize debate

**Agent:** debate-synthesizer
**Upstream:**
- `.loom/artifacts/{ticket_id}/perspective-architect.md`
- `.loom/artifacts/{ticket_id}/perspective-implementer.md`
- `.loom/artifacts/{ticket_id}/perspective-critic.md`
- `.loom/artifacts/{ticket_id}/perspective-user.md`
**Output path:** `.loom/artifacts/{ticket_id}/debate-synthesis.md`

Cross-examine all perspectives, resolve disagreements, and produce a synthesized approach with consensus, tensions, and a risk register.

### 4. Plan

**Agent:** draft-plan
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/debate-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/plan.md`

Create a technical implementation plan grounded in the debated and synthesized approach.

### 5. Converge

**Agents:** requirements-reviewer, regression-analyst, security-reviewer, edge-case-hunter (parallel)
**Verdict logic:** AND
**Consecutive clean rounds:** 2
**Max rounds:** 5
**On needs-work:** apply-review-fixes
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Plan convergence: {round} rounds, unresolved feedback — see artifacts."

Reviewers evaluate the plan content for completeness and risk — the diff is just the plan document being added, not code changes. requirements-reviewer traces spec requirements to plan items. regression-analyst reads the plan's proposed file changes and traces consumer impact in the codebase. security-reviewer evaluates the plan's security posture. edge-case-hunter identifies boundary conditions the plan doesn't account for.

**Upstream for reviewers:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/plan.md`

**Reviewer output paths:**
- requirements-reviewer: `.loom/artifacts/{ticket_id}/requirements-review-r{N}.md`
- regression-analyst: `.loom/artifacts/{ticket_id}/regression-r{N}.md`
- security-reviewer: `.loom/artifacts/{ticket_id}/security-r{N}.md`
- edge-case-hunter: `.loom/artifacts/{ticket_id}/edge-cases-r{N}.md`

**Feedback agent output path:** `.loom/artifacts/{ticket_id}/fixes-r{N}.md`

### 6. Completion

## Pre-completion checklist (verify before transitioning)

- [ ] research-codebase-arch produced output
- [ ] Debate completed (4 perspectives + synthesis)
- [ ] draft-plan produced output
- [ ] Convergence ran (passed or hit max rounds with note)
- [ ] All output paths registered via addReferences
