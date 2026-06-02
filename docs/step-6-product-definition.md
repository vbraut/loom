# Step 6: Product Definition Playbook — Design Brief

Context for Step 6. Captures design decisions for renaming the planning playbook to product-definition, adding elevate reviewer agents, and enriching the pipeline with research-backed improvements.

## Goal

Rename `type:planning` to `type:product-definition` and enrich the playbook with reference capture, a unified mock convergence panel (6 reviewers including 4 new elevate agents adapted from Reign), and research-informed improvements to PRD drafting and assessment.

## What changes

### Rename

| Current | New |
|---|---|
| `type:planning` | `type:product-definition` |
| `playbooks/planning.md` | `playbooks/product-definition.md` |
| `playbooks/planning-review.md` | `playbooks/product-definition-review.md` |
| README ticket types table: `planning` row | `product-definition` row |
| `shared/claim.md` type routing | Route `type:product-definition` to `playbooks/product-definition.md` |

The current planning playbook already does product definition (PRD + mocks). The name should reflect that. "Planning" as a concept (technical implementation plan) lives inside the implementation playbook (steps 1-9).

### 4 new agents (elevate reviewers)

Ported from Reign's elevate loop agents (`~/dev/reign/.agents/skills/`). In Reign these were sequential doer agents that assessed AND fixed mocks. In Loom they become reviewers — they assess and produce rich findings; apply-review-fixes executes the fixes.

**Key constraint:** Since context previously lived inside the same agent that fixed, each finding must carry enough information for apply-review-fixes to execute without domain expertise. Every finding includes: exact location in mock HTML, what's wrong, why it matters (domain reasoning), and a concrete recommendation with specific values/tokens/patterns to use.

| Agent | Source | Role |
|---|---|---|
| critique | Reign `/critique` (200 lines) | UX quality — visual hierarchy, cognitive load, emotional resonance, discoverability, AI slop detection, Nielsen's heuristics scoring |
| optimize | Reign `/optimize` (264 lines) | Performance feasibility — patterns that will cause slow loads, janky animations, layout shifts, or excessive bundle size when implemented |
| harden | Reign `/harden` (353 lines) | Resilience — missing states, unhandled edge cases, i18n failures, accessibility barriers, text overflow scenarios |
| polish | Reign `/polish` (201 lines) | Micro-details — alignment precision, spacing rhythm, state completeness, copy consistency, responsive behavior |

**Adaptation from Reign format to Loom format:**
- Add YAML frontmatter (`name`, `description`)
- Add `**Role:**` with 2-sentence ownership boundary
- Strip code examples (move fix knowledge into finding recommendations)
- Strip interactive sections (Phase 3/4 in critique — no user interaction in autonomous pipeline)
- Strip Reign-specific references (`/normalize`, `/animate`, etc.)
- Add structured findings format (`{location} — {severity} — {description} + Recommendation:`)
- Add STATUS/VERDICT line
- Target under 200 lines (trim via skill-authoring three-question test)

### 1 enriched agent (design-system-reviewer)

Absorbs the concerns from Reign's `/normalize` agent that go beyond current DS reviewer scope:

| New concern | What it checks |
|---|---|
| Motion/interaction patterns | Animation timing, easing, transition consistency against established DS patterns |
| Responsive behavior | Breakpoint reflow patterns and responsive layout consistency (not just correct breakpoints) |
| Typographic hierarchy | Heading/body/caption relationships and type system coherence (not just correct token usage) |

These are added as additional audit dimensions in the Evaluation section, conditional on the DS docs covering these areas.

### Enriched playbook (13 steps)

```
 1 ── research-codebase-arch ────── enriched: also document current UI state
 │                                   (existing routes, components, visual patterns)
 │
 2 ── draft-prd ─────────────────── enriched: 3-phase MARE process internally
 │                                   (elicit stakeholder needs → derive requirements
 │                                    → structure into PRD template)
 │
 │    ┌─ ASSESS PRD (parallel, named) ──────────────────────────────┐
 3    │ assess-inversion      assess-dependency     persona-pm      │
 │    │ assess-decomposition  assess-outsider       persona-dev     │
 │    │ assess-analogy                              persona-{...}   │
 │    │                                                              │
 │    │ Enriched: persona-reviewer instructions include              │
 │    │ quality-attribute framing per QUARE — each persona           │
 │    │ explicitly states which quality attributes (performance,     │
 │    │ security, usability, maintainability) are in tension         │
 │    │ and proposes resolutions.                                    │
 │    └─────────────────────────────────────────────────────────────┘
 │
 4 ── CROSS-TALK ────────────────── enriched: quality-attribute tensions
 │                                   surfaced as first-class items to resolve
 5 ── assess-synthesizer
 │
 6 ── apply-review-fixes ────────── revise PRD with synthesis
 7 ── elicit-approach
 8 ── apply-review-fixes ────────── revise PRD with elicitation
 │
 │    ┌─ CONVERGE PRD (max 5 rounds, 2 consecutive clean) ─────────┐
 9    │ requirements-reviewer    security-reviewer                   │
 │    │ regression-analyst       edge-case-hunter                    │
 │    │ simplification-reviewer  adversarial-reviewer                │
 │    │ design-system-reviewer†  ↻ apply-review-fixes               │
 │    └─────────────────────────────────────────────────────────────┘
 │
10 ── capture-screenshots ───────── When: ticket touches existing UI routes
 │                                   (orchestrator checks whether PRD references
 │                                   routes that exist in the codebase)
 │                                   captures current app state as visual
 │                                   reference for create-mocks
 │
11 ── create-mocks ──────────────── Skip when: no UI changes
 │
 │    ┌─ CONVERGE MOCKS (max 5 rounds, 2 consecutive clean) ───────┐
12    │ Reviewers (parallel):                                        │
 │    │   mock-alignment-reviewer  ── PRD requirement coverage       │
 │    │   design-system-reviewer†  ── DS compliance + normalize      │
 │    │   critique                 ── UX quality, hierarchy, load    │
 │    │   optimize                 ── performance feasibility        │
 │    │   harden                   ── states, edge cases, i18n       │
 │    │   polish                   ── alignment, spacing, details    │
 │    │                                                              │
 │    │ Verdict: AND                                                 │
 │    │ On needs-work: apply-review-fixes                            │
 │    └─────────────────────────────────────────────────────────────┘
 │
13 ── completion

† when design_system configured
```

**Note on capture-screenshots (step 10):** This agent currently serves the implementation playbook's visual verification step (capture for comparison against mocks). Here it serves a different purpose: capture the current app state as visual reference BEFORE mock creation. The agent's instructions should accommodate both modes — the upstream artifacts determine which: visual-parity artifacts mean "compare," PRD + research artifacts mean "reference."

**What changed from the current 12-step planning playbook:**
- Steps 1-9: internal enrichments (MARE, QUARE), no structural changes
- Step 10: new conditional step (capture-screenshots for existing UI routes)
- Step 11: unchanged (create-mocks)
- Step 12: expanded from 2 reviewers to 6 (was: mock-alignment + design-system; now adds: critique, optimize, harden, polish)
- Step 13: renumbered from 12 (completion)

## Agent designs

### critique

**Source:** Reign `/critique` — 200 lines. Evaluates design from UX perspective with AI slop detection, Nielsen's 10 heuristics scoring, visual hierarchy, cognitive load, emotional journey, discoverability, composition, typography, color, states, and microcopy.

**Adaptation:** Strip Phase 3 (Ask the User) and Phase 4 (Recommended Actions) — no user interaction in autonomous pipeline. Strip references to Reign-specific commands. Add VERDICT and structured findings.

**Role:** Evaluate mock design quality from a UX perspective. You own visual hierarchy, cognitive load, emotional resonance, discoverability, and overall design coherence — not DS token compliance (that's design-system-reviewer) or PRD coverage (that's mock-alignment-reviewer).

**Evaluation criteria (from Reign, preserved):**
1. AI slop detection — does this look like generic AI-generated UI?
2. Visual hierarchy — does the eye flow to the most important element first?
3. Information architecture & cognitive load — is the structure intuitive? Run 8-item cognitive load checklist.
4. Emotional journey — does it match brand personality? Peak-end rule. Interventions at negative moments.
5. Discoverability & affordance — are interactive elements obviously interactive?
6. Composition & balance — visual rhythm, intentional whitespace, asymmetry.
7. Typography as communication — type hierarchy signals reading order.
8. Color with purpose — color communicates, not decorates. Colorblind-safe.
9. States & edge cases — empty, loading, error, success states all guide users.
10. Microcopy & voice — clear, concise, brand-appropriate, unambiguous.

**Output format:**

```
## Design Health Score

| # | Heuristic | Score (0-4) | Key Issue |
|---|-----------|-------------|-----------|
(Nielsen's 10 heuristics)
| Total | | ??/40 | Rating |

## Anti-Patterns Verdict

Pass/Fail — specific AI-generated tells found

## Findings

{element or section} — {must-fix/should-fix/nit} — {what's wrong + why it hurts users}
  Recommendation: {concrete fix — what element to change, what property,
  what value, what the result should look and feel like}

STATUS: complete — VERDICT: pass/needs-work
```

### optimize

**Source:** Reign `/optimize` — 264 lines. Performance across loading, rendering, animations, images, bundle size, Core Web Vitals.

**Adaptation:** Strip code examples (move fix knowledge into finding recommendations). Keep all assessment dimensions. Findings state performance impact and specific alternatives.

**Role:** Evaluate mock designs for performance feasibility — patterns that will cause slow loads, janky animations, layout shifts, or excessive bundle size when implemented. You own performance reasoning — not whether the code is simple (that's simplification-reviewer) or whether it follows DS patterns (that's design-system-reviewer).

**Evaluation criteria (from Reign, preserved):**
1. Image handling — modern formats, proper sizing, lazy loading, responsive images
2. Animation feasibility — GPU-acceleratable properties, 60fps achievable, appropriate easing
3. Rendering cost — DOM depth, paint complexity, layout thrashing potential
4. Bundle impact — heavy dependencies implied by the design, tree-shaking feasibility
5. Font loading — font-display strategy, subsetting, preloading
6. Core Web Vitals impact — LCP (hero images, critical CSS), CLS (reserved space, aspect ratios), INP (interaction responsiveness)
7. List/data performance — virtualization needs, pagination, unbounded fetches
8. Responsive overhead — viewport-specific assets, conditional loading

**Output format:**

```
## Findings

{element or pattern} — {must-fix/should-fix/nit} — {performance concern + estimated impact}
  Problem: {what will happen at runtime — specific: "N+1 image loads without lazy loading",
  "layout shift on font swap", "60+ DOM nodes in list without virtualization"}
  Recommendation: {concrete alternative with implementation approach —
  "use loading=lazy with width/height attributes to prevent CLS",
  "add font-display: swap and preload the primary font",
  "design for virtual scrolling — fixed row height, viewport-sized container"}

STATUS: complete — VERDICT: pass/needs-work
```

### harden

**Source:** Reign `/harden` — 353 lines. Resilience through error handling, i18n, text overflow, edge cases, accessibility, performance resilience.

**Adaptation:** Strip code examples. Keep all assessment dimensions. Findings describe specific edge case AND the handling pattern to add.

**Role:** Evaluate mock designs for resilience gaps — missing states, unhandled edge cases, i18n failures, accessibility barriers, and text overflow scenarios. You own production-readiness of the design — not whether it follows DS (that's design-system-reviewer) or whether it performs well (that's optimize).

**Evaluation criteria (from Reign, preserved):**
1. Text overflow & wrapping — long text handling, flex/grid overflow, responsive text sizing
2. Internationalization — text expansion (30-40% budget), RTL support, character set support, date/time/number formats, pluralization
3. Error handling — network errors, form validation, API errors (per status code), graceful degradation
4. Edge cases & boundary conditions — empty states, loading states, large datasets, concurrent operations, permission states
5. Input validation — required fields, format validation, length limits, constraint communication
6. Accessibility resilience — keyboard navigation, screen reader support, motion sensitivity, high contrast mode
7. Performance resilience — slow connections (skeleton screens, optimistic UI), memory leaks, throttling/debouncing

**Output format:**

```
## Findings

{element or state} — {must-fix/should-fix/nit} — {edge case or resilience gap}
  Scenario: {specific situation — "user name is 100+ characters",
  "API returns 500 during save", "German translation is 40% longer",
  "list has 1000+ items"}
  Current handling: {what the mock shows, or "not addressed"}
  Recommendation: {what state/element to add and how it should behave —
  visual treatment, copy, user action available.
  E.g., "Add truncation with ellipsis after 2 lines, full name in tooltip.
  Use line-clamp-2 utility + title attribute.
  Show: [truncated name...] with cursor: help"}

STATUS: complete — VERDICT: pass/needs-work
```

### polish

**Source:** Reign `/polish` — 201 lines. Final quality pass on alignment, spacing, typography, color, interaction states, micro-interactions, content, icons, forms, responsiveness.

**Adaptation:** Strip code examples and "Final Verification" section (convergence loop handles re-verification). Keep all assessment dimensions. Findings reference exact elements and specify exact values.

**Role:** Catch micro-detail issues that individually seem minor but collectively determine whether a design feels polished or rough. You own the gap between "works" and "feels right" — alignment precision, spacing rhythm, state completeness, copy consistency, responsive behavior. Not UX strategy (that's critique) or DS compliance (that's design-system-reviewer).

**Evaluation criteria (from Reign, preserved):**
1. Visual alignment & spacing — pixel-perfect grid alignment, consistent spacing scale, optical alignment, responsive consistency
2. Typography refinement — hierarchy consistency, line length (45-75 chars), line height, widows/orphans, font loading
3. Color & contrast — WCAG contrast ratios, consistent token usage, theme consistency, tinted neutrals (no pure gray/black), no gray text on colored backgrounds
4. Interaction states — every interactive element needs all 8 states: default, hover, focus, active, disabled, loading, error, success
5. Micro-interactions & transitions — smooth transitions (150-300ms), consistent easing (ease-out-quart/quint/expo, never bounce/elastic), prefers-reduced-motion respect
6. Content & copy — consistent terminology, consistent capitalization, grammar, appropriate length, punctuation consistency
7. Icons & images — consistent style, appropriate sizing, optical alignment with text, alt text, loading states, retina support
8. Forms & inputs — label consistency, required indicators, error messages, tab order, validation timing
9. Responsiveness — all breakpoints tested, touch targets (44x44px min), readable text (14px min on mobile), no horizontal scroll

**Output format:**

```
## Findings

{element + viewport if relevant} — {must-fix/should-fix/nit} — {micro-detail issue}
  Current: {what it is — "13px gap", "no hover state",
  "Title Case mixed with sentence case"}
  Expected: {what it should be — "16px (spacing-4)",
  "hover: bg-muted transition-colors duration-150",
  "Sentence case consistently"}
  Recommendation: {exact change — property, value, and why.
  For interaction states: list which of the 8 states are missing
  and describe the expected behavior for each}

STATUS: complete — VERDICT: pass/needs-work
```

## Modified agents

### research-codebase-arch

**What changes:** Add evaluation criteria for documenting current UI state when the ticket involves UI changes.

**New content (appended to existing evaluation criteria):**

When the ticket involves UI changes:
- Identify all routes and components the ticket will touch
- Document the current visual structure (layout, key components, navigation patterns)
- Note which design system components are currently used in those areas
- If reference screenshots were captured (step 10), note their paths for create-mocks

### draft-prd

**What changes:** Enrich the internal process with MARE's 3-phase decomposition (MARE: Multi-Agents Collaboration Framework for Requirements Engineering, arXiv 2405.03256 — up to 23.9% improvement in requirements quality through task decomposition). The PRD output format stays the same; the approach to getting there becomes more structured.

**New content (enriches the process section):**

Phase 1 — Elicit: Before writing, generate stakeholder perspectives. What would different user types need from this feature? What would the PM prioritize vs. the engineer vs. the end user? Surface implicit requirements the ticket description doesn't state.

Phase 2 — Derive: Map stakeholder needs to concrete requirements. Each requirement gets a unique identifier (R-1, R-2...). Classify as functional, non-functional, or constraint. Trace each requirement back to the stakeholder need that generated it.

Phase 3 — Structure: Organize requirements into the PRD template. Every section of the PRD must trace to identified requirements. Flag requirements that don't fit any section — they indicate a template gap or a scope issue.

### persona-reviewer

**What changes:** Add quality-attribute framing per QUARE (Multi-Agent Negotiation for Balancing Quality Attributes in RE, arXiv 2603.11890 — 105% improvement in compliance coverage through explicit quality-attribute negotiation).

**New content (appended to evaluation criteria):**

After evaluating from your persona's perspective, explicitly state which quality attributes (performance, security, usability, maintainability, reliability, scalability) are in tension with your findings. Name the trade-off: "Improving X requires accepting Y."

### design-system-reviewer

**What changes:** Absorb normalize's concerns — motion/interaction patterns, responsive behavior consistency, and typographic hierarchy.

**New content (appended to evaluation section, after existing audit items):**

- **Motion/interaction:** animation timing, easing, and transition patterns match DS conventions (if documented).
- **Responsive consistency:** responsive reflow patterns match established DS behavior (not just correct breakpoints, but consistent layout adaptation).
- **Typographic hierarchy:** heading/body/caption relationships follow DS type scale as a system (not just correct token per element, but coherent hierarchy across the page).

### cross-talk (shared/cross-talk.md)

**What changes:** Add quality-attribute tension surfacing to cross-talk instructions.

**New content (added to the SendMessage template instructions):**

When other agents surface quality-attribute tensions (e.g., "security requires X but usability requires Y"), respond to those tensions specifically — not just to findings. State whether you agree with the trade-off framing, and if not, why. The goal is to surface and resolve trade-offs, not accumulate concerns.

## Research foundations

This design is informed by the following research, in addition to Loom's existing foundations (DMAD, CollabEval, M3MADBench — documented in README.md):

**MARE** — Multi-Agents Collaboration Framework for Requirements Engineering (arXiv 2405.03256). Decomposes RE into elicitation → modeling → verification → specification with specialized agents. Up to 23.9% improvement in F1 for requirements modeling. Applied to: draft-prd's 3-phase internal process.

**QUARE** — Multi-Agent Negotiation for Balancing Quality Attributes in RE (arXiv 2603.11890, March 2026). Formulates requirements analysis as structured negotiation among quality-specialized agents. 98.2% compliance coverage (+105% over baselines), 94.9% semantic preservation. Applied to: persona-reviewer quality-attribute framing and cross-talk tension surfacing.

**ReqInOne** — LLM-Based Agent for Modular SRS Generation (arXiv 2508.09648). Task decomposition with specialized prompts beats one-shot spec generation. Applied to: reinforces the MARE decomposition in draft-prd.

**Reign define.md** — Production-tested product definition workflow from the Reign project (`~/dev/reign/.claude/skills/sdlc-work/define.md`, 317 lines). Proven patterns: PRD-mock alignment gate before elevation, elevate loop (critique → normalize → optimize → harden → polish), design system compliance gate with zero tolerance, reference screenshot capture. Applied to: mock convergence panel composition, elevate agent selection, capture-screenshots step.

**Cloudflare AI code review** — Production multi-agent review system (7+ specialist agents). Security reviewer: 484 critical findings in 30 days. Performance reviewer: 14,615 findings. Specialist reviewers catch issues generalists miss. Applied to: reinforces the case for domain-specialist reviewers in mock convergence.

## Divergences from original Step 6 plan

The original Step 6 in `docs/plan.md` proposed:

| Original plan | This design | Why |
|---|---|---|
| Separate product-definition playbook | Rename planning → product-definition, enrich with conditionals | Same output (PRD + mocks). One playbook, fewer files. User chose this. |
| `write-spec` agent | Enriched `draft-prd` with MARE decomposition | draft-prd already exists and does this job. MARE enrichment is internal. |
| `capture-refs` agent | Enriched `research-codebase-arch` + conditional `capture-screenshots` step | Reference gathering is a context concern (research agent's job). Competitive web search too unreliable for autonomous execution. |
| `refine-spec` / `refine-mocks` agents | `apply-review-fixes` handles both | Already handles structured findings AND unstructured revision. No need for separate refine agents. |
| `prd-mock-alignment` agent | `mock-alignment-reviewer` (already exists) | Built in Step 5. |
| `edge-case-hunter` agent | Already exists (Step 3) | Built in Step 3. |
| `design-system-guardian` agent | `design-system-reviewer` (already exists, enriched) | Built in Step 5, enriched here with normalize's concerns. |
| `critique` agent | Adapted from Reign as Loom reviewer | Ported from Reign `/critique`, converted from doer to reviewer format. |
| `polish` agent | Adapted from Reign as Loom reviewer | Ported from Reign `/polish`, converted from doer to reviewer format. |
| `normalize` dropped | Absorbed into `design-system-reviewer` | Overlapping DS compliance concerns. One agent, richer evaluation. |
| `optimize` + `harden` not in original plan | Added from Reign elevate loop | Reign's proven elevate sequence includes these. Research (Cloudflare) confirms specialist reviewers catch issues generalists miss. |

## File changes summary

| Action | File | Description |
|---|---|---|
| **New** | `agents/critique/AGENT.md` | UX quality reviewer (from Reign critique) |
| **New** | `agents/optimize/AGENT.md` | Performance feasibility reviewer (from Reign optimize) |
| **New** | `agents/harden/AGENT.md` | Resilience/edge-case reviewer (from Reign harden) |
| **New** | `agents/polish/AGENT.md` | Micro-detail quality reviewer (from Reign polish) |
| **Rename** | `playbooks/planning.md` → `product-definition.md` | Rename + add steps 10, 12 (expanded convergence) |
| **Rename** | `playbooks/planning-review.md` → `product-definition-review.md` | Rename only |
| **Modify** | `agents/research-codebase-arch/AGENT.md` | Add UI state documentation criteria |
| **Modify** | `agents/draft-prd/AGENT.md` | Add MARE 3-phase process |
| **Modify** | `agents/persona-reviewer/AGENT.md` | Add QUARE quality-attribute framing |
| **Modify** | `agents/design-system-reviewer/AGENT.md` | Absorb normalize concerns (motion, responsive, typography hierarchy) |
| **Modify** | `shared/cross-talk.md` | Add quality-attribute tension surfacing |
| **Modify** | `README.md` | Rename planning → product-definition in ticket types table + playbook pipeline diagram |
| **Modify** | `scripts/validate.sh` | Update for renamed playbooks |
| **Modify** | `docs/plan.md` | Mark Step 6 status, note divergences |

**4 new agents, 2 renamed files, 8 modified files.**
