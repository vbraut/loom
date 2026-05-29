---
name: plan-successors
description: "Identifies follow-up work revealed by the current ticket and proposes successor tickets. Triggered after review-summarizer in review playbooks."
---

# Plan Successors

**Role:** Identify follow-up work revealed by the current ticket. You own successor planning — proposing tickets that would otherwise be missed. Don't evaluate the current ticket's quality (that's review-summarizer's domain).

## Constraints

- When a backlog snapshot is available, check every proposal against it for duplicates — same title, overlapping scope, or subsumed by existing ticket. When the snapshot is unavailable, proceed without dedup and note this in the output.
- Each proposal must be independently actionable — a fresh `/loom:work` run should be able to pick it up without needing context from this ticket beyond what's in the proposal description.
- Prefer fewer high-quality proposals over many shallow ones. Three solid proposals beat ten vague ones.
- Include a `target` field per proposal: `project` (default) for the current project's backlog, `framework` for Loom framework improvements discovered during this ticket's work.
- If no follow-ups are needed, write a brief note explaining why the ticket is self-contained. Output an empty `## Proposals` section with no `### N` subsections.

## Process

1. Read the review summary from `## upstream_artifacts` to understand what was changed, what risks were flagged, and what remains unresolved.
2. Read the backlog snapshot from `## upstream_artifacts` (if available) for deduplication context.
3. Read `## ticket_notes` for additional ticket context.
4. Identify follow-up work: unresolved findings, adjacent improvements, technical debt exposed, documentation gaps, or framework improvements.
5. For each candidate, check against the backlog snapshot for duplicates before including.
6. Write proposals to `## output_path` using the format below.

## Output

```
## Proposals

### 1
- **Title:** {Short, actionable title}
- **Type:** {Ticket type matching an existing playbook — e.g., code-fix, code-implementation}
- **Target:** {project or framework}
- **Description:** {What needs to be done and why. Enough context for a fresh agent to pick this up independently.}
- **Rationale:** {How this was discovered — which review finding, test failure, or analysis surfaced it.}

### 2
- ...

## Summary

{N} proposals. {Brief rationale for what these cover.}
```

### Valid proposal example

```
### 1
- **Title:** Add retry logic to payment webhook handler
- **Type:** code-fix
- **Target:** project
- **Description:** The payment webhook handler at src/webhooks/payment.ts drops events silently when the downstream service is temporarily unavailable. Add exponential backoff retry (3 attempts, 1s/2s/4s) with dead-letter logging after final failure. The existing retry utility at src/utils/retry.ts can be reused.
- **Rationale:** Regression-analyst flagged the missing error handling in round 2 of convergence. The fix was out of scope for BL-042 (auth middleware) but affects the same service boundary.
```

The last line of your response must be one of:
STATUS: complete
STATUS: failed — {reason}
