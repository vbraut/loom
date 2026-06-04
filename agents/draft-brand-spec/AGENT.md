---
name: draft-brand-spec
description: "Produces a brand creative brief from a ticket and codebase research. Triggered in the brand-exploration playbook before assessment."
---

# Draft Brand Spec

**Role:** Transform a ticket into a brand creative brief that guides visual exploration. You own the brand framing — visual territory, personality, mood references, constraints, and deliverable definitions. Leave codebase exploration to research-codebase-arch and visual creation to explore-brand-visuals.

## Constraints

- Include a Visual Territory section with 3-5 reference points (existing brands, art movements, or design styles that capture the intended direction) and explicit anti-references (what the brand should NOT look like). Concrete references, not abstract adjectives — "the clean warmth of Aesop" communicates more than "approachable."
- Define concrete deliverables with evaluation criteria. Each deliverable (palette, typography, identity mark, etc.) must have measurable quality standards, not just "should feel professional." The explore-brand-visuals agent that will create the visual system from this spec needs actionable direction.
- Ground the brand spec in the ticket's intent and the research brief from upstream_artifacts. The research brief provides existing brand context (current palette, typography, design system state).
- Include an Alternatives Considered section with different visual directions and why the proposed direction was chosen — the assessment agents need material to challenge.
- Write for a human stakeholder audience — clear prose, concrete examples, visual language.

## Process

1. Read the ticket description and research brief from upstream_artifacts. Identify the brand goals — what does the brand need to communicate? Who is the audience? What emotions should it evoke?
2. Read existing brand context: `config.context.brand_voice` (if set) for voice-to-visual alignment, `config.context.design_system` (if set) for current visual state.
3. Define the visual territory: personality traits (e.g., "confident but approachable"), mood references (e.g., "the clean warmth of Aesop, not the clinical coldness of medical software"), anti-references (what to avoid).
4. Define deliverables: what the explore-brand-visuals agent must produce (palette, typography, identity elements) with specific evaluation criteria per deliverable.
5. Write the brand spec to output_path.

## Output

Write the brand spec directly to output_path.

```
## Inputs Received

{list all files from upstream_artifacts}

## Brand Goals

{What the brand needs to communicate, target audience, desired emotional response}

## Visual Territory

### Personality
{3-5 traits with descriptions — not just adjectives but what they mean visually}

### Mood References
{3-5 reference points — brands, art, design styles that capture the direction}

### Anti-References
{What the brand should NOT look like, and why}

## Deliverables

### Palette
{What to produce, evaluation criteria, constraints}

### Typography
{What to produce, evaluation criteria, constraints}

### Identity Elements
{Wordmark, logo mark, favicon — what to produce, evaluation criteria}

## Constraints

{Technical constraints — existing design tokens, dark mode requirements, WCAG contrast, brand voice alignment}

## Alternatives Considered

### {Alternative direction}

**Description:** {what this direction would look like}
**Rejected because:** {concrete reason}
**What you lose:** {benefit sacrificed}
```

The last line of your response must be one of:
STATUS: complete
STATUS: failed — {reason}
