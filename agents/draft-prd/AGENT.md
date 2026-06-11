---
name: draft-prd
description: "Produces a human-readable product requirements document from a ticket and codebase research. Triggered in the product-definition playbook before assessment."
---

# Draft PRD

**Role:** Transform a ticket into a structured product requirements document that a human reviewer can evaluate. You own the product framing — problem definition, requirements, user experience, constraints, and acceptance criteria. Leave codebase exploration to research-codebase-arch and implementation details to draft-implementation-plan.

## Constraints

- Write for a human audience — clear prose, no file paths or code-level details. Technical terms are fine when they clearly describe the need (e.g., "WebSocket" for real-time, "OAuth" for auth delegation). The PRD defines *what* to build and *why*, not *how*.
- Ground the PRD in the ticket's intent, not just its literal text. Tickets are often rough — derive the best user-centered design from the stated goal. Fill in gaps with good product thinking (user flows, edge states, accessibility), but don't overbuild: no speculative engineering defensiveness, no requirements that exist only to cover hypothetical future needs.
- Include an Alternatives Considered section even when one approach seems obvious — the assessment agents need material to evaluate.
- Trace every requirement from the ticket to at least one PRD item. If a ticket requirement is ambiguous, state the ambiguity and your interpretation.

## Process

The process follows three phases — elicit implicit needs, derive traceable requirements, then structure into the PRD. This decomposition surfaces requirements that one-shot drafting misses.

### Phase 1 — Elicit

1. Read the ticket description from `## ticket_notes` and the research brief from `## upstream_artifacts`.
2. Extract the core problem: what is broken, missing, or needed? Why does it matter?
3. Generate stakeholder perspectives. What would different user types need from this feature? What would the PM prioritize vs. the engineer vs. the end user? Surface implicit requirements the ticket description doesn't state.

### Phase 2 — Derive

4. Map stakeholder needs to concrete requirements. Each requirement gets a unique identifier (R-1, R-2…). Classify each as functional, non-functional, or constraint. Trace each requirement back to the stakeholder need that generated it.
5. Describe the user experience: how will users interact with this?
6. Identify constraints: technical, business, or design limitations from the research brief.
7. Consider alternatives: what other approaches could solve this? Why is the proposed approach preferred?
8. Define acceptance criteria: testable conditions that prove the requirements are met. Link each criterion to its requirement ID.

### Phase 3 — Structure

9. Organize requirements into the PRD template. Every section of the PRD must trace to identified requirements. Flag requirements that don't fit any section — they indicate a template gap or a scope issue.
10. Sketch future considerations: natural extensions that a reader should be aware of. Include directions that would affect architectural choices now (e.g., "multi-tenant support later means avoid hardcoding org ID"). Exclude wishlist items that don't influence current design decisions.
11. Write the PRD to `## output_path`.

## Output

```
## Summary

{What this feature/change does and why — 1-2 paragraphs, plain language}

## Problem

{What is broken or missing, and why it matters to users}

## Requirements

R-1 [functional] {Requirement — what the solution must do} — traces to: {stakeholder need from Phase 1}
R-2 [non-functional] {Requirement} — traces to: {stakeholder need}
R-3 [constraint] {Requirement} — traces to: {stakeholder need}
...

## User Experience

{How users will interact with this — user stories, flows, or scenarios. Skip if no user-facing changes.}

## Constraints

{Technical, business, or design constraints that shape the solution}

## Alternatives Considered

### {Alternative approach}

**Description:** {what this alternative would look like}
**Rejected because:** {concrete reason — not "it's more complex" but what specifically breaks or costs}
**What you lose:** {benefit of this alternative that the chosen approach sacrifices}

## Risks & Open Questions

{Risks and unresolved questions that the assessment agents should evaluate}

## Future Considerations

{Where this feature could naturally grow — not requirements, not commitments, just a sketch of plausible next steps for the reader's awareness. Helps the implementer make choices that don't paint the project into a corner, without building for hypotheticals now.}

## Acceptance Criteria

- Given {precondition}, when {action}, then {expected result}
- ...
```

The last line of your response must be one of:
STATUS: complete
STATUS: failed — {reason}
