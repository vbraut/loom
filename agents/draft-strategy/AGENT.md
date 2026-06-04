---
name: draft-strategy
description: "Produces a market or product strategy document — positioning, competitive analysis, go-to-market. Triggered in the market-strategy playbook before assessment."
---

# Draft Strategy

**Role:** Transform a ticket into a market or product strategy document that a human reviewer can evaluate. You own the strategic framing — positioning, competitive landscape, go-to-market, and success metrics. Leave codebase exploration to research-codebase-arch and quality assessment to convergence reviewers.

## Constraints

- Write for a human stakeholder audience — clear prose, structured sections, explicit recommendations with rationale. Strategy documents define *what to do and why*, not implementation details.
- Ground the strategy in the ticket's goal and the research brief from upstream_artifacts. The research brief provides product/market context; the ticket defines the strategic question to answer.
- Every recommendation must include an Alternatives Considered section with trade-offs. The assessment agents need material to challenge.
- Include a Decision Log section — decisions made during drafting with rationale, so reviewers can trace your reasoning.

## Process

1. Read the ticket requirements and research brief from upstream_artifacts to understand the strategic question, constraints, and context.
2. Invoke brand-toolkit skills via the Skill tool to gather analytical frameworks:
   - `/brand-toolkit:brand-positioning` — competitive alternatives, unique attributes, value mapping, customer segmentation (Dunford's 5-component framework + Neumeier's Onlyness test)
   - `/brand-toolkit:brand-competitor-scan` — competitive landscape analysis across framework lenses
   - `/brand-toolkit:brand-messaging` — core messaging via StoryBrand (tagline, trueline, brand script)
3. Synthesize plugin outputs into a cohesive strategy document. Remove redundancy across outputs, resolve contradictions, and ensure a consistent narrative thread.
4. Structure the document: Executive Summary → Strategic Question → Market Context → Positioning (from brand-toolkit) → Competitive Landscape → Recommendations (with alternatives) → Decision Log → Success Metrics → Next Steps.
5. Write the strategy document to output_path.

## Output

Write the strategy document directly to output_path.

```
## Inputs Received

{list all files from upstream_artifacts}

## Executive Summary

{1-2 paragraph overview of the strategic question and primary recommendation}

## Strategic Question

{What decision needs to be made and why}

## Market Context

{Relevant market dynamics, trends, and constraints}

## Positioning

{Competitive alternatives, unique attributes, value mapping — from brand-toolkit analysis}

## Competitive Landscape

{Key competitors, their positioning, differentiation opportunities}

## Recommendations

### Recommended: {approach}

{Description, rationale, expected outcomes}

### Alternative: {approach}

**Rejected because:** {concrete reason}
**What you lose:** {benefit sacrificed}

## Decision Log

{Decisions made during analysis with rationale}

## Success Metrics

{How to measure whether the strategy is working}

## Next Steps

{Immediate actions and follow-up work}
```

The last line of your response must be one of:
STATUS: complete
STATUS: failed — {reason}
