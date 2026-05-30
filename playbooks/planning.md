# planning

Technical planning playbook. Produces an implementation plan from a PRD or spec.

## Steps

### 1. Research

**Agent:** research-codebase-arch
**Output path:** `.loom/artifacts/{ticket_id}/research.md`

Explore the codebase architecture, locate relevant files and patterns for the planned work.

### 2. Debate approach

**Agents:** debate-inversion, debate-decomposition, debate-analogy, debate-dependency, debate-outsider (parallel)
**Upstream:** `.loom/artifacts/{ticket_id}/research.md`

**Agent output paths:**
- debate-inversion: `.loom/artifacts/{ticket_id}/perspective-inversion.md`
- debate-decomposition: `.loom/artifacts/{ticket_id}/perspective-decomposition.md`
- debate-analogy: `.loom/artifacts/{ticket_id}/perspective-analogy.md`
- debate-dependency: `.loom/artifacts/{ticket_id}/perspective-dependency.md`
- debate-outsider: `.loom/artifacts/{ticket_id}/perspective-outsider.md`

Five cognitive operations evaluate the proposed approach independently using method diversity (DMAD): inversion (assume it failed — what caused it?), decomposition (break into atomic claims — which are load-bearing?), analogy (what existing pattern solves this better?), dependency mapping (what blocks what — are prerequisites met?), outsider (what insider knowledge does this assume?). Each agent includes a confidence score for weighted synthesis.

### 3. Synthesize debate

**Agent:** debate-synthesizer
**Upstream:**
- `.loom/artifacts/{ticket_id}/perspective-inversion.md`
- `.loom/artifacts/{ticket_id}/perspective-decomposition.md`
- `.loom/artifacts/{ticket_id}/perspective-analogy.md`
- `.loom/artifacts/{ticket_id}/perspective-dependency.md`
- `.loom/artifacts/{ticket_id}/perspective-outsider.md`
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
- [ ] Debate completed (5 methods + synthesis)
- [ ] draft-plan produced output
- [ ] Convergence ran (passed or hit max rounds with note)
- [ ] All output paths registered via addReferences
