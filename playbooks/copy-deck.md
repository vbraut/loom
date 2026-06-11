# copy-deck

Messaging framework playbook. Produces a copy deck (tone of voice, registers, do/don't examples, terminology, messaging hierarchy) grounded in interactive discovery and web research, validated through assessment, cross-talk, elicitation, and convergence. Artifact-only — no code, no PR.

## Intake

### Stance

facilitate | collaborate | autonomous

### Questions

1. What should this brand sound like — what's the core tone and feeling?
   context: Voice territory, not features. "Confident but approachable", "technical without being intimidating". If the user gives product features, redirect to how those features should be communicated.

2. What's the competitive voice landscape — how do competitors sound, and where do you want to differentiate?
   context: If every competitor sounds formal and corporate, "we want to stand out" means specific differentiation in voice. Drives the web research agent's competitor voice analysis.

3. Who is the audience, and what communication style resonates with them?
   context: Audience expectations for voice. Developers expect different copy than enterprise buyers or consumers. Needs at least one concrete audience segment.

4. Name 2-3 brands whose voice or copy style you admire, and what specifically you like about each.
   context: Concrete references, not adjectives. "Stripe's clear technical writing" communicates more than "professional and modern". These become voice anchors.

5. What should this brand absolutely NOT sound like?
   context: Anti-references for voice. "Not stiff like a bank", "not quirky like a startup trying too hard". These prevent drift in copy development.

6. What existing voice guidelines, copy patterns, or brand constraints exist?
   context: Current style guides, existing copy, tone documentation, terminology standards. These are hard constraints, not suggestions.

7. What will this copy deck be used for — what channels and contexts?
   context: "Marketing site rewrite" vs "developer docs" vs "comprehensive brand voice" changes the registers and examples needed. Tight scope needs focused deliverables.

## Steps

### 1. Research

**Agent:** research-codebase-arch
**Upstream:** `.loom/artifacts/{ticket_id}/intake-brief.md`
**Output path:** `.loom/artifacts/{ticket_id}/research.md`

### 2. Await external research

**Output path:** `.loom/artifacts/{ticket_id}/external-research.md`

### 3. Draft copy deck

**Agent:** draft-copy-deck
**Upstream:**
- `.loom/artifacts/{ticket_id}/intake-brief.md`
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/external-research.md` (optional)
**Output path:** `.loom/artifacts/{ticket_id}/copy-deck.md`
**Checkpoint:** Approve draft direction before assessment pipeline

### 4. Assess copy deck

**Agents:** assess-inversion, assess-decomposition, assess-analogy, assess-dependency, assess-outsider (named, parallel)
**Agent:** persona-reviewer (named, parallel)
**Persona selection:**
  Always: pm
  Dynamic (select 1-3 based on ticket content): dev, ux, craft, tech-writer, end-user, analyst, architect, tech-lead, security, data, qa, devops, sm
**Upstream:**
- `.loom/artifacts/{ticket_id}/intake-brief.md`
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/external-research.md` (optional)
- `.loom/artifacts/{ticket_id}/copy-deck.md`

**Agent output paths:**
- assess-inversion: `.loom/artifacts/{ticket_id}/perspective-inversion-r{R}.md`
- assess-decomposition: `.loom/artifacts/{ticket_id}/perspective-decomposition-r{R}.md`
- assess-analogy: `.loom/artifacts/{ticket_id}/perspective-analogy-r{R}.md`
- assess-dependency: `.loom/artifacts/{ticket_id}/perspective-dependency-r{R}.md`
- assess-outsider: `.loom/artifacts/{ticket_id}/perspective-outsider-r{R}.md`
- persona-{name}: `.loom/artifacts/{ticket_id}/persona-{name}-r{R}.md`

### 5. Cross-talk

**Named agents:** all agents from step 4
**Max rounds:** 3
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Cross-talk: {round} rounds, not fully converged — see artifacts."

### 6. Synthesize assessments

**Agent:** assess-synthesizer
**Upstream:** latest round's output files:
- `.loom/artifacts/{ticket_id}/perspective-inversion-r{R}.md`
- `.loom/artifacts/{ticket_id}/perspective-decomposition-r{R}.md`
- `.loom/artifacts/{ticket_id}/perspective-analogy-r{R}.md`
- `.loom/artifacts/{ticket_id}/perspective-dependency-r{R}.md`
- `.loom/artifacts/{ticket_id}/perspective-outsider-r{R}.md`
- `.loom/artifacts/{ticket_id}/persona-*-r{R}.md` (all persona outputs)
**Output path:** `.loom/artifacts/{ticket_id}/assessment-synthesis.md`

### 7. Revise copy deck with synthesis

**Agent:** apply-review-fixes
**Upstream:**
- `.loom/artifacts/{ticket_id}/copy-deck.md`
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/copy-synthesis-revisions.md`

Note: apply-review-fixes modifies the copy deck in the worktree in place (revision mode). The output path records what changed.

### 8. Elicit

**Agent:** elicit-approach
**Upstream:**
- `.loom/artifacts/{ticket_id}/copy-deck.md`
- `.loom/artifacts/{ticket_id}/assessment-synthesis.md`
**Output path:** `.loom/artifacts/{ticket_id}/elicitation.md`

Note: Reads the post-synthesis `copy-deck.md` (modified in place by step 7) — elicitation stress-tests the revised copy deck, with the synthesis as context for what assessment already covered.

### 9. Revise copy deck with elicitation

**Agent:** apply-review-fixes
**Upstream:**
- `.loom/artifacts/{ticket_id}/copy-deck.md`
- `.loom/artifacts/{ticket_id}/elicitation.md`
**Output path:** `.loom/artifacts/{ticket_id}/copy-elicitation-revisions.md`

### 10. Converge

**Agents:** requirements-reviewer, simplification-reviewer, adversarial-reviewer, edge-case-hunter (parallel)
**Verdict logic:** AND
**Consecutive clean rounds:** 1
**Max rounds:** 5
**On needs-work:** apply-review-fixes
**On max rounds:** Proceed to next step. Append to ticket_notes:
  "Convergence: {round} rounds, unresolved feedback — see artifacts."

**Upstream for reviewers:**
- `.loom/artifacts/{ticket_id}/intake-brief.md`
- `.loom/artifacts/{ticket_id}/research.md`
- `.loom/artifacts/{ticket_id}/external-research.md` (optional)
- `.loom/artifacts/{ticket_id}/copy-deck.md`

**Reviewer output paths:**
- requirements-reviewer: `.loom/artifacts/{ticket_id}/requirements-review-r{N}.md`
- simplification-reviewer: `.loom/artifacts/{ticket_id}/simplification-r{N}.md`
- adversarial-reviewer: `.loom/artifacts/{ticket_id}/adversarial-r{N}.md`
- edge-case-hunter: `.loom/artifacts/{ticket_id}/edge-cases-r{N}.md`

**Feedback agent output path:** `.loom/artifacts/{ticket_id}/fixes-r{N}.md`

### 11. Completion

## Pre-completion checklist (verify before transitioning)

- [ ] Intake brief produced (or autonomous inference completed)
- [ ] External research completed (or skipped gracefully if web unavailable)
- [ ] Draft checkpoint approved
- [ ] research-codebase-arch produced output
- [ ] draft-copy-deck produced copy deck
- [ ] Assessment completed (5 cognitive + persona reviewers, all in parallel)
- [ ] Cross-talk completed (converged, hit max rounds with note, or skipped — no Critical/High concerns)
- [ ] Synthesis produced
- [ ] Copy deck revised with synthesis findings
- [ ] Elicitation completed
- [ ] Copy deck revised with elicitation findings
- [ ] Convergence ran (passed or hit max rounds with note)
- [ ] All output paths registered via addReferences
