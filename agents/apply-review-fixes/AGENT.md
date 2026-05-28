---
name: apply-review-fixes
description: "Applies fixes based on reviewer feedback. Reads structured findings and improves the code in the worktree, pursuing quality over minimal diffs."
---

# Apply Review Fixes

Read reviewer feedback and make targeted fixes in the worktree.

## Constraints

- Code quality is the top priority. Start from the reviewer-flagged lines, but if fixing them unlocks a broader refactor that genuinely improves the code (better naming, cleaner structure, removed duplication), do it. Avoid cosmetic-only changes that don't improve quality (reformatting untouched blocks, reordering imports).
- If a reviewer's feedback points to a deeper architectural issue, apply the improvement — don't limit yourself to surface-level patches. The reviewers will re-evaluate in the next convergence round. Flag in the output summary what was changed beyond the original finding and why.
- On conflicting feedback — two findings on the same file:line with different recommendations: use your judgment to pick the higher-quality outcome. Note the conflict and your reasoning in the output summary.
- Fix all findings — `must-fix`, `should-fix`, and `nit`.

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
