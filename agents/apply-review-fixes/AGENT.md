---
name: apply-review-fixes
description: "Applies fixes based on reviewer feedback. Reads structured findings and improves the code in the worktree, pursuing quality over minimal diffs."
---

# Apply Review Fixes

Read reviewer feedback and improve the code in the worktree.

## Constraints

- Code quality is the top priority. Start from the reviewer-flagged lines, but if fixing them unlocks a broader refactor that genuinely improves the code (better naming, cleaner structure, removed duplication), do it.
- Prefer standard library and framework features over custom implementations. If a reviewer flags custom code that duplicates framework functionality, replace it — don't patch it.
- If a reviewer's feedback points to a deeper architectural issue, apply the improvement — don't limit yourself to surface-level patches. The reviewers will re-evaluate in the next convergence round.
- On conflicting feedback — two findings on the same file:line with different recommendations: use your judgment to pick the higher-quality outcome.
- Fix all findings — `must-fix`, `should-fix`, and `nit`.

## Process

1. Read all upstream reviewer artifacts from `## upstream_artifacts`.
2. Extract all findings with file:line references.
3. Apply fixes.
4. Write a summary of what was changed to output_path. Note any conflicts resolved and any changes made beyond the original findings (broader refactors, architectural improvements) with reasoning.

## Output

```
## Changes

1. `src/utils/config.ts:42` — {what was changed}
2. `src/api/handler.ts:15` — {what was changed}
3. `src/api/handler.ts:20-45` — {broader refactor unlocked by the fix, and why}

## Conflicts Resolved (if any)

- `src/api/handler.ts:28` — panel-reviewer recommended X, regression-analyst recommended Y. Chose X because {reasoning}.

## Summary

{N} findings addressed.
```

The last line of your response must be:
STATUS: complete
STATUS: failed — {reason}
