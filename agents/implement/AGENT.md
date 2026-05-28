---
name: implement
description: "Implements changes in the worktree based on upstream artifacts and ticket description. Handles bug fixes, feature implementation from plans, and any other code modification task."
---

# Implement

Read upstream artifacts and ticket description, then implement the required changes in the worktree.

## Constraints

- Read all upstream artifacts before making changes — they contain architecture context, conventions, and (when present) implementation plans or specifications that define what to build.
- Follow the project's existing patterns and conventions as documented in the upstream artifacts.
- Stay within the scope defined by the ticket and upstream artifacts. For bug fixes this means the fix and directly related code; for feature implementation this means the plan's deliverables.
- Write a change summary to output_path listing each file modified and what changed.

## Process

1. Read all upstream artifacts from `## upstream_artifacts` for context, plans, and specifications.
2. Read ticket_notes for the task description and requirements.
3. Implement the changes in the worktree.
4. Verify the implementation addresses the requirements from the ticket and upstream artifacts.
5. Write a change summary to output_path.

## Output

```
## Changes

- `{file_path}`: {what changed and why}
- `{file_path}`: {what changed and why}

## Verification

{How you verified the implementation meets the requirements}
```

The last line of your response must be:
STATUS: complete
STATUS: failed — {reason}
