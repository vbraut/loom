---
name: draft-strategy
description: "Produces a market or product strategy document by synthesizing user intent from the intake brief, external research, and codebase context. Triggered in the market-strategy playbook after intake and research."
---

# Draft Strategy

**Role:** Synthesize user intent from the intake brief, real market data from external research, and product context from codebase research into a strategy document that a human reviewer can evaluate. Leave discovery to the intake process and codebase exploration to research-codebase-arch.

## Constraints

1. Ground the strategy in the intake brief first — the user's own words about their strategic question, competitors, audience, and constraints are the primary source of truth. Strategy documents define *what to do and why*, not implementation details.
2. Treat external research (competitor analysis, market data) as evidence that supports or challenges the user's framing. Cite sources from external-research.md when referencing market claims.
3. Brand-toolkit skills are optional enrichment — invoke via the Skill tool only when the intake brief suggests brand-adjacent strategic questions (positioning, messaging). Don't use them as the backbone of the analysis.
4. Every recommendation must include an Alternatives Considered section with trade-offs (the assessment agents need material to challenge).
5. Include a Decision Log section — decisions made during drafting with rationale, so reviewers can trace reasoning.

## Process

1. Read the intake brief, external research, and codebase research from upstream_artifacts. The intake brief is primary — it contains the user's strategic question, named competitors, audience definition, constraints, and success criteria.
2. Map the user's strategic question (from intake) to the evidence gathered (from external research). Where the user's assumptions about competitors or market differ from web research findings, note the discrepancy explicitly in the strategy document.
3. If the intake brief suggests brand-adjacent questions AND brand-toolkit plugins are available, invoke relevant brand-toolkit skills via the Skill tool as supplementary analysis. Otherwise skip.
4. Synthesize into a cohesive strategy document: the user's intent provides direction, external research provides evidence, codebase research provides product context.
5. Structure the document: Executive Summary → Strategic Question → Market Context → Positioning → Competitive Landscape → Recommendations (with alternatives) → Decision Log → Success Metrics → Next Steps.
6. Write the strategy document to output_path.

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
