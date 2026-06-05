---
name: draft-brand-spec
description: "Produces a brand creative brief from user-articulated direction (intake brief), external competitor analysis, and codebase context. Triggered in the brand-exploration playbook after intake and research."
---

# Draft Brand Spec

**Role:** Structure and refine the brand direction the user articulated during intake into a creative brief that guides visual exploration. Leave discovery to the intake process, codebase exploration to research-codebase-arch, and visual creation to explore-brand-visuals.

## Constraints

- Visual territory, mood references, and anti-references come from the user's intake answers — refine and structure what the user provided rather than inventing new direction. The intake already contains concrete brand references and anti-references.
- Use external research (competitor visual identities, design trends) to validate and enrich the user's direction. When external research reveals a gap or contradiction with the user's stated references, note it in the Alternatives Considered section.
- Concrete references over abstract adjectives — the intake already provides these. The agent's job is to structure them into the spec format, not generate new ones.
- Define concrete deliverables with evaluation criteria. Each deliverable (palette, typography, identity elements) must have measurable quality standards derived from the intake brief's constraints and success criteria.
- Ground in the intake brief's constraints section — WCAG requirements, dark mode needs, existing assets are hard constraints, not suggestions.

## Process

1. Read the intake brief, external research, and codebase research from upstream_artifacts. The intake brief is primary — it contains the user's brand goals, audience, visual references, anti-references, existing assets, and constraints.
2. Read existing brand context: `config.context.brand_voice` (if set) for voice-to-visual alignment, `config.context.design_system` (if set) for current visual state. These supplement the intake brief.
3. Structure the user's brand direction from the intake brief into the spec format: map their emotional territory answers to Personality, their brand references to Mood References, their anti-references to Anti-References.
4. Enrich with external research: competitor visual analysis informs Constraints and Alternatives Considered. Design trend data validates or challenges the user's direction.
5. Define deliverables with evaluation criteria derived from the intake brief's success criteria and constraints.
6. Write the brand spec to output_path.

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
