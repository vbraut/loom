# implementation

Feature implementation playbook. Implements code from an approved plan. Requires `pr: true` for transition.

## Steps

### 1. Research

**Agent:** research-codebase-arch
**Output path:** `.loom/artifacts/{ticket_id}/research.md`

Explore the codebase architecture, locate relevant files and patterns for implementation.

### 2. Debate approach

**Agents:** debate-inversion, debate-decomposition, debate-analogy, debate-dependency, debate-outsider (parallel)
**Upstream:** `.loom/artifacts/{ticket_id}/research.md`

**Agent output paths:**
- debate-inversion: `.loom/artifacts/{ticket_id}/perspective-inversion.md`
- debate-decomposition: `.loom/artifacts/{ticket_id}/perspective-decomposition.md`
- debate-analogy: `.loom/artifacts/{ticket_id}/perspective-analogy.md`
- debate-dependency: `.loom/artifacts/{ticket_id}/perspective-dependency.md`
- debate-outsider: `.loom/artifacts/{ticket_id}/perspective-outsider.md`

Five cognitive operations evaluate the proposed implementation approach independently using method diversity (DMAD): inversion (assume it failed — what caused it?), decomposition (break into atomic claims — which are load-bearing?), analogy (what existing pattern solves this better?), dependency mapping (what blocks what — is the build sequence correct?), outsider (what insider knowledge does this assume?). If the ticket references an implementation plan, agents should read it from the worktree. Each agent includes a confidence score for weighted synthesis.

### 3. Synthesize debate

**Agent:** debate-synthesizer
**Upstream:**
- `.loom/artifacts/{ticket_id}/perspective-inversion.md`
- `.loom/artifacts/{ticket_id}/perspective-decomposition.md`
- `.loom/artifacts/{ticket_id}/perspective-analogy.md`
- `.loom/artifacts/{ticket_id}/perspective-dependency.md`
- `.loom/artifacts/{ticket_id}/perspective-outsider.md`
**Output path:** `.loom/artifacts/{ticket_id}/debate-synthesis.md`

Cross-examine all perspectives, resolve disagreements, and produce a synthesized implementation approach.

### 4. Implement

**Agent:** implement
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/debate-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/changes.md`

Implement the changes described in the ticket using the debated approach. If the ticket references an implementation plan (created by a planning ticket and merged to main), the plan file is in the worktree — read it for the detailed breakdown of changes. Write a change summary to the output path.

### 5. Converge

**Agents:** requirements-reviewer, regression-analyst, simplification-reviewer, security-reviewer, edge-case-hunter (parallel)
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

**Feedback agent output path:** `.loom/artifacts/{ticket_id}/fixes-r{N}.md`

### 6. Verify

**Agents:** run-tests, test-coverage (parallel)

**Agent output paths:**
- run-tests: `.loom/artifacts/{ticket_id}/test-results.md`
- test-coverage: `.loom/artifacts/{ticket_id}/test-coverage.md`

**Upstream for test-coverage:** `.loom/artifacts/{ticket_id}/research.md`

run-tests runs the project's test suite. test-coverage maps ticket requirements to test cases and identifies coverage gaps.

**On failure:** If run-tests reports assertion failures or test-coverage returns `VERDICT: needs-work`, retry from step 4 with both artifacts added to implement's upstream.

### 7. Capture

**Agent:** capture-screenshots
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/changes.md`
**Output path:** `.loom/artifacts/{ticket_id}/screenshots.md`

Capture the running application at mobile and desktop viewports.

### 8. Visual verify

**Agent:** visual-parity-reviewer
**Upstream:** `.loom/artifacts/{ticket_id}/screenshots.md`
**Output path:** `.loom/artifacts/{ticket_id}/visual-parity.md`

Compare captured screenshots against mock or reference images.

**On failure:** If visual-parity-reviewer returns `VERDICT: needs-work`, retry from step 4 with the visual parity artifact added to implement's upstream.

### 9. Completion

`pr: true`

## Pre-completion checklist (verify before transitioning)

- [ ] research-codebase-arch produced output
- [ ] Debate completed (5 methods + synthesis)
- [ ] implement produced output and modified worktree
- [ ] Convergence ran (passed or hit max rounds with note)
- [ ] run-tests produced output
- [ ] test-coverage produced output
- [ ] capture-screenshots produced output
- [ ] visual-parity-reviewer produced output
- [ ] All output paths registered via addReferences
