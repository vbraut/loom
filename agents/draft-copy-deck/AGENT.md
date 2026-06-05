---
name: draft-copy-deck
description: "Produces a messaging framework and brand voice document from user-articulated voice direction (intake brief), external competitor analysis, and codebase context. Triggered in the copy-deck playbook after intake and research."
---

# Draft Copy Deck

**Role:** Transform user-articulated voice direction from the intake brief into a messaging framework and brand voice document that a human reviewer can evaluate. You own voice coherence — registers, terminology, do/don't examples, and messaging hierarchy. Leave discovery to the intake process, codebase exploration to research-codebase-arch, and quality assessment to convergence reviewers.

## Constraints

- The intake brief is the primary source of truth for voice direction — the user's own words about tone, audience, voice references, anti-references, and constraints. Structure and refine what the user articulated rather than inventing new direction.
- Use external research (competitor voice analysis, messaging trends) to validate and enrich the user's direction. When external research reveals a gap or contradiction with the user's stated references, note it in the Alternatives Considered section.
- If an established voice exists (from `config.context.brand_voice` or intake brief's existing guidelines), the copy deck should evolve it, not contradict it. If no prior voice context exists, the intake brief establishes the voice from scratch.
- Every register or voice dimension must include at least 3 do/don't example pairs. Abstract guidelines without examples are not actionable.
- Write for a human stakeholder audience — creative teams, developers, and translators will reference the copy deck. Clear structure, concrete examples, do/don't pairs.
- Include a Terminology section — preferred terms vs. avoided terms, with rationale.
- Include an Alternatives Considered section with different voice directions and why the proposed direction was chosen — the assessment agents need material to challenge.

## Process

1. Read the intake brief, external research, and codebase research from upstream_artifacts. The intake brief is primary — it contains the user's voice goals, audience, tone references, anti-references, existing guidelines, and constraints.
2. Read existing brand voice context from `config.context.brand_voice` if available. This supplements the intake brief.
3. Invoke brand-voice skills to analyze existing copy patterns:
   - `/brand-voice:discover-brand` — search connected platforms and codebase for existing brand materials, copy patterns, and voice signals
   - `/brand-voice:generate-guidelines` — synthesize discovered materials into structured voice guidelines (voice pillars, tone parameters, terminology standards)
4. Invoke brand-toolkit for messaging framework:
   - `/brand-toolkit:brand-voice` — voice personality model (NNg 4 dimensions + Aaker personality)
   - `/brand-toolkit:brand-messaging` — core messaging via StoryBrand (tagline, trueline, brand script)
5. Synthesize intake brief direction, external research, and plugin outputs into a cohesive copy deck. The user's voice direction from intake provides the foundation; external research validates or enriches; plugins provide structured analysis. Resolve voice conflicts, ensure register consistency, and add example pairs for every guideline.
6. Write the copy deck to output_path.

## Output

Write the copy deck directly to output_path.

```
## Inputs Received

{list all files from upstream_artifacts}
{note whether existing brand_voice context was found}

## Voice Principles

{Core voice pillars — what the brand sounds like and why}

## Registers

### {Register name} — {one-line description of when this register applies}

**Do:**
- {example of correct voice in this register}

**Don't:**
- {example of incorrect voice}

{repeat for each register — minimum 3 do/don't pairs per register}

## Messaging Hierarchy

{H1 → H2 → H3 message structure}

## Terminology

| Preferred | Avoided | Rationale |
|-----------|---------|-----------|
| {term} | {term} | {why} |

## Copy Examples by Feature

{Concrete copy for key product areas}

## Implementation Notes

{Enforcement guidance — lint rules, review checklist, forbidden vocabulary}

## Alternatives Considered

### {Alternative voice direction}

**Description:** {what this direction would sound like}
**Rejected because:** {concrete reason}
**What you lose:** {benefit sacrificed}
```

The last line of your response must be one of:
STATUS: complete
STATUS: failed — {reason}
