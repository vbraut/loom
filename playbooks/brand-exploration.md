# brand-exploration

Brand visual system playbook. Produces a brand spec validated through assessment and a visual system (palette, typography, layout) created via Impeccable's design disciplines and validated through visual convergence. Artifact-only — no code, no PR.

## Steps

### 1. Research

**Agent:** research-codebase-arch
**Output path:** `.loom/artifacts/{ticket_id}/research.md`

### 2. Draft brand spec

**Agent:** draft-brand-spec
**Upstream:** `.loom/artifacts/{ticket_id}/research.md`
**Output path:** `.loom/artifacts/{ticket_id}/brand-spec.md`

### 3. Assess brand spec

**Agents:** assess-inversion, assess-decomposition, assess-analogy, assess-dependency, assess-outsider (named, parallel)
**Agent:** persona-reviewer (named, parallel)
**Persona selection:**
  Always: pm
  Dynamic (select 1-3 based on ticket content): dev, ux, craft, analyst, end-user, architect, tech-lead, security, data, qa, devops, sm, tech-writer
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/brand-spec.md`

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

### 6. Revise brand spec with synthesis

**Agent:** apply-review-fixes
**Upstream:**
- `.loom/artifacts/{ticket_id}/brand-spec.md`
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/brand-spec-synthesis-revisions.md`

Note: apply-review-fixes modifies the brand spec in the worktree in place (revision mode). The output path records what changed.

### 7. Elicit

**Agent:** elicit-approach
**Upstream:**
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/elicitation.md`

### 8. Revise brand spec with elicitation

**Agent:** apply-review-fixes
**Upstream:**
- `.loom/artifacts/{ticket_id}/brand-spec.md`
- `.loom/artifacts/{ticket_id}/elicitation.md`
**Output path:** `.loom/artifacts/{ticket_id}/brand-spec-elicitation-revisions.md`

### 9. Converge spec

**Agents:** requirements-reviewer, simplification-reviewer, adversarial-reviewer, edge-case-hunter (parallel)
**When:** config.context.design_system → also include design-system-reviewer
**Verdict logic:** AND
**Consecutive clean rounds:** 2
**Max rounds:** 5
**On needs-work:** apply-review-fixes
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Spec convergence: {round} rounds, unresolved feedback — see artifacts."

**Upstream for reviewers:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/brand-spec.md`

**Reviewer output paths:**
- requirements-reviewer: `.loom/artifacts/{ticket_id}/requirements-review-r{N}.md`
- simplification-reviewer: `.loom/artifacts/{ticket_id}/simplification-r{N}.md`
- adversarial-reviewer: `.loom/artifacts/{ticket_id}/adversarial-r{N}.md`
- edge-case-hunter: `.loom/artifacts/{ticket_id}/edge-cases-r{N}.md`
- design-system-reviewer: `.loom/artifacts/{ticket_id}/design-system-r{N}.md`

**Feedback agent output path:** `.loom/artifacts/{ticket_id}/fixes-r{N}.md`

### 10. Create brand visuals

**Agent:** explore-brand-visuals
**Upstream:**
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/brand-spec.md`
**Output path:** `.loom/artifacts/{ticket_id}/brand-visuals-manifest.md`

### 11. Converge visuals

Note: Impeccable modifies worktree files directly (CSS, design tokens, SVGs). Reviewers evaluate the worktree diff (what Impeccable changed) and use the manifest for context (what was intended). apply-review-fixes handles refinements (color values, font weights, spacing) by editing the worktree files directly. Fundamental direction changes that need Impeccable to regenerate would hit max rounds and reach the human reviewer.

**Agents:** ui-critique, ui-polish (parallel)
**When:** config.context.design_system → also include design-system-reviewer
**Verdict logic:** AND
**Consecutive clean rounds:** 2
**Max rounds:** 3
**On needs-work:** apply-review-fixes
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Visual convergence: {round} rounds, unresolved feedback — see artifacts."

**Upstream for reviewers:**
- `.loom/artifacts/{ticket_id}/brand-spec.md`
- `.loom/artifacts/{ticket_id}/brand-visuals-manifest.md`

**Reviewer output paths:**
- ui-critique: `.loom/artifacts/{ticket_id}/brand-ui-critique-r{N}.md`
- ui-polish: `.loom/artifacts/{ticket_id}/brand-ui-polish-r{N}.md`
- design-system-reviewer: `.loom/artifacts/{ticket_id}/brand-design-system-r{N}.md`

**Feedback agent output path:** `.loom/artifacts/{ticket_id}/brand-visual-fixes-r{N}.md`

### 12. Completion

## Pre-completion checklist (verify before transitioning)

- [ ] research-codebase-arch produced output
- [ ] draft-brand-spec produced brand spec
- [ ] Assessment completed (5 cognitive + persona reviewers, all in parallel)
- [ ] Cross-talk completed (converged or hit max rounds with note)
- [ ] Synthesis produced
- [ ] Brand spec revised with synthesis findings
- [ ] Elicitation completed
- [ ] Brand spec revised with elicitation findings
- [ ] Spec convergence ran (passed or hit max rounds with note)
- [ ] explore-brand-visuals produced visual assets
- [ ] Visual convergence ran (passed or hit max rounds with note)
- [ ] All output paths registered via addReferences
