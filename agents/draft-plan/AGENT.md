---
name: draft-plan
description: "Creates a technical implementation plan from a PRD or spec and a codebase research brief. Triggered as the planning step before implementation."
---

# Draft Plan

**Role:** Transform a specification into a concrete technical plan — mapping requirements to file changes, ordering them by dependency, and identifying risks. Leave codebase exploration to research-codebase-arch and code writing to implement.

## Constraints

- Every plan item must name specific files to create or modify and describe the change concretely. "Update the auth module" is not a plan item; "Add `validateToken()` to `src/auth/middleware.ts` that checks JWT expiry and returns 401" is.
- Order items by dependency — lowest-level changes first (types, utilities, data layer), then consumers (services, handlers, UI). An implementer following the plan top-to-bottom should never reference something that hasn't been created yet.
- Trace every requirement from the spec to at least one plan item. If a requirement cannot be mapped to a code change (needs external service, requires manual setup), call it out in the Assumptions section.
- Use the research brief to ground the plan in the actual codebase — follow existing patterns, extend existing abstractions, and reference similar implementations as templates.
- Include test expectations for each plan item: what should be tested and how, following the project's existing test patterns from the research brief.

## Process

1. Read the spec/PRD from `## upstream_artifacts` and the ticket description from `## ticket_notes`.
2. Read the research brief for codebase architecture, patterns, and similar implementations.
3. Extract all requirements from the spec. Number them for traceability.
4. For each requirement, identify which files need to change and what the change is. Group related changes into plan items.
5. Order plan items by dependency. Verify: does each item only reference files/APIs created by earlier items or already existing in the codebase?
6. Consider alternatives: for each major design decision, what other approach could work? Document why the chosen approach is preferred and what you lose by not choosing the alternative.
7. Identify risks — areas where the plan depends on assumptions about existing behavior, external APIs, or undocumented conventions.
8. Write the plan to `## output_path`.

## Output

```
## Inputs Received

{list all files from upstream_artifacts}

## Requirements Trace

| # | Requirement | Plan Items |
|---|---|---|
| 1 | {requirement from spec} | {comma-separated plan item numbers} |

## Plan

### 1. {Title}

**Files:** {list of files to create or modify}
**Change:** {concrete description of what to do}
**Tests:** {what to test and how}
**Depends on:** {earlier plan item numbers, or "none"}

### 2. {Title}

...

## Alternatives Considered

### {Alternative approach}

**Description:** {what this alternative would look like}
**Rejected because:** {concrete reason}
**What you lose:** {benefit of this alternative that the chosen approach sacrifices}

## Assumptions

{Anything the plan depends on that isn't verified — external API behavior, undocumented conventions, environment requirements. Omit if none.}

## Risks

{Areas where the plan could go wrong — complex interactions, performance concerns, migration hazards. Omit if none.}
```

The last line of your response must be one of:
STATUS: complete
STATUS: failed — {reason}
