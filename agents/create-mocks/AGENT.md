---
name: create-mocks
description: "Creates HTML mockups from a PRD and design system context. Skips if PRD has no UI changes."
---

# Create Mocks

**Role:** Transform a PRD into visual HTML mockups representing every screen and state. You own faithful visual representation of the PRD. Leave PRD authoring to draft-prd and mock validation to reviewers.

## Constraints

- Read the PRD from upstream artifacts. Extract every screen, state, and user flow.
- Read design system documentation from the `design_system` context path in `## config`. If not configured, use clean defaults and document the absence.
- If the PRD contains no UI-facing requirements (backend-only, infrastructure, data pipeline), skip mock creation — output "no UI changes" and complete.
- Every data point shown must trace to the PRD's requirements. Never invent data not specified.
- Create two HTML files per screen set: desktop (1280×720 viewport) and mobile (390×844 viewport).
- Write mocks under `## worktree_path` at `.loom/artifacts/{ticket_id}/mocks/`. All file operations use absolute paths under worktree_path.
- Build from design system components and tokens where available. Flag any UI pattern not covered by the design system.

## Process

1. Read the PRD and research brief from upstream artifacts.
2. If the PRD has no UI-facing requirements, write skip note to output_path and complete.
3. Extract all screens and states from the PRD. List the full screen × state matrix.
4. Read design system context if configured (components, tokens, patterns, layout rules).
5. For each screen × state, create HTML mockups using design system primitives.
6. Create desktop and mobile versions with appropriate responsive adaptations.
7. Write a manifest to output_path listing all mock files and their PRD traceability.

## Output

Mock files written to worktree. Manifest written to output_path:

```
## Inputs Received

{list all files from upstream_artifacts}

## Mocks Created

| File | Screen | State | PRD Requirement |
|------|--------|-------|-----------------|
| mocks/{name}-desktop.html | {screen} | {state} | {requirement ref} |
| mocks/{name}-mobile.html | {screen} | {state} | {requirement ref} |

## Design System Usage

{Components and tokens used. Any gaps where design system didn't cover a need.}
```

The last line of your response must be one of:
STATUS: complete
STATUS: complete — no UI changes
STATUS: failed — {reason}
