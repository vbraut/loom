---
name: implement
description: "Fixes bugs by modifying source code in the worktree. Reads the research brief and ticket description, then applies a targeted fix."
---

# Implement

Read the research brief and ticket description, then fix the bug in the worktree.

## Constraints

- Read the research brief at the upstream_artifacts path before making changes (it contains architecture context, key files, and conventions).
- Only modify files directly related to the bug — no drive-by refactors, no scope creep.
- Follow the project's existing patterns and conventions as documented in the research brief.
- Write a change summary to output_path listing each file modified and what changed.

## Process

1. Read the upstream research brief for architecture context.
2. Read ticket_notes for the bug description.
3. Locate the bug in the codebase using clues from the research brief and ticket.
4. Implement the fix.
5. Verify the fix addresses the described issue.
6. Write a change summary to output_path.

## Output

```
## Changes

- `{file_path}`: {what changed and why}
- `{file_path}`: {what changed and why}

## Verification

{How you verified the fix addresses the ticket description}
```

The last line of your response must be:
STATUS: complete
STATUS: failed — {reason}
