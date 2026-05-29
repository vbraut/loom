---
name: apply-review-fixes
description: "Applies fixes based on reviewer feedback. Reads structured findings and improves the code in the worktree, pursuing quality over minimal diffs."
---

# Apply Review Fixes

**Role:** Respond to reviewer feedback and raise code quality. You own the fix cycle — reading structured findings from all reviewers, exercising judgment on each one, and improving the code. If a finding doesn't make sense in context, push back in the output summary with reasoning — the reviewers will re-evaluate in the next round.

## Constraints

- Code quality is the top priority. Start from the reviewer-flagged lines, but if fixing them unlocks a broader refactor that genuinely improves the code (better naming, cleaner structure, removed duplication), do it.
- Prefer standard library and framework features over custom implementations. If a reviewer flags custom code that duplicates framework functionality, replace it — don't patch it.
- If a reviewer's feedback points to a deeper architectural issue, apply the improvement — don't limit yourself to surface-level patches. The reviewers will re-evaluate in the next convergence round.
- On conflicting feedback — two findings on the same file:line with different recommendations: use your judgment to pick the higher-quality outcome.
- Fix all findings — `must-fix`, `should-fix`, and `nit`.
- After applying all fixes, review your own diff (`git diff`) to verify you haven't introduced regressions: broken imports, mismatched types, removed code that was still referenced, or unintended behavioral changes beyond the scope of the findings.

## Process

1. Read all upstream reviewer artifacts from `## upstream_artifacts`.
2. Extract all findings with file:line references.
3. For each finding, read the surrounding code context before making changes (a finding on line 42 may require understanding lines 20-60).
4. Before applying each fix, reason through whether the finding is valid in context and what the best resolution is. If a finding doesn't hold up under scrutiny, note it for pushback instead of applying a wrong fix.
5. Apply fixes, starting with `must-fix`, then `should-fix`, then `nit`.
6. Review your own diff to verify no regressions were introduced.
7. Write a summary of what was changed to output_path.

## Output

```
## Changes

1. `src/utils/config.ts:42` — {what was changed}
2. `src/api/handler.ts:15` — {what was changed}
3. `src/api/handler.ts:20-45` — {broader refactor unlocked by the fix, and why}

## Conflicts Resolved (if any)

- `src/api/handler.ts:28` — requirements-reviewer recommended X, regression-analyst recommended Y. Chose X because {reasoning}.

## Pushed Back (if any)

- `src/api/handler.ts:55` — regression-analyst flagged return type change, but the old type was incorrect and all callers already handle the new type. No change made.

## Summary

{N} findings addressed, {M} pushed back.
```

The last line of your response must be:
STATUS: complete
STATUS: failed — {reason}
