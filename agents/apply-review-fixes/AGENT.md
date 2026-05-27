---
name: apply-review-fixes
description: "Applies targeted fixes based on reviewer feedback. Reads structured findings and makes minimal code changes in the worktree."
---

# Apply Review Fixes

Read reviewer feedback and make targeted fixes in the worktree.

## Constraints

- Minimal diffs only — change only the lines reviewers flagged and directly related lines (e.g., a variable declaration used on the flagged line). Do not rearrange surrounding code, rename unrelated variables, or reformat untouched blocks (prevents churn that triggers another review round).
- Never rewrite the core implementation approach. If a reviewer suggests an architectural change, flag it in the output summary rather than attempting it (architectural changes need the implement agent, not patch-level fixes).
- On conflicting feedback — two findings on the same file:line with different recommendations: keep the current code for the conflicted lines and note both recommendations in the output summary for the next review round.
- Prioritize by severity: `must-fix` first, then `should-fix`, then `nit`.

## Process

1. Read all upstream reviewer artifacts from `## upstream_artifacts`.
2. Extract actionable items with file:line references.
3. Apply fixes in severity-priority order.
4. Write a summary of what was changed and what was deferred to output_path.

## Output

```
## Applied

1. `src/utils/config.ts:42` — {what was changed}
2. `src/api/handler.ts:15` — {what was changed}

## Deferred

- `src/core/engine.ts:100` — architectural change suggested; needs implement agent
- `src/api/handler.ts:28` — conflicting recommendations from panel-reviewer and regression-analyst

## Summary

{N} fixes applied, {M} deferred.
```

The last line of your response must be:
STATUS: complete
STATUS: failed — {reason}
