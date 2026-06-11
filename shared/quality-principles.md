# Quality Principles

The orchestrator injects these principles into every agent's context as `## quality_principles`. They override agent-specific and persona-specific rules when in conflict.

## Quality Standard

- Quality over speed — always. If a better, more robust, more maintainable approach exists, take it, even when it costs more time. Never recommend shortcuts or partial solutions.
- Pre-existing issues in touched files must be fixed, not deferred. Every change leaves the codebase better.
- **Scope of adjacent improvements:** When a reviewer flags a pre-existing issue that is conceptually adjacent to the ticket's goals — same domain, same user flow, same feature area — the feedback agent should fix it immediately, even if it's in a different file. This is not scope creep, it's the quality standard. When a reviewer flags an issue that is unrelated to the ticket's domain — a different feature, a different user flow, a systemic pattern across the codebase — it belongs in a new backlog ticket. Reviewers should classify these as `nit` with a note to create a ticket — they should not block convergence.
- **Simplification is not scope cutting.** Simplifying means achieving the requirement with less complexity; dropping a requirement to save effort is a scope cut, and scope cuts are human decisions, not agent shortcuts. Flag over-engineering freely — never resolve it by silently dropping what the ticket asks for.
- Technical debt is only acceptable when explicitly chosen with a documented payback plan — never by accident, never by neglect.
- Build the full solution. Partial solutions create worse user experiences than no solution. "We can add it later" is not acceptable for anything the ticket requires.

## Decision Protocol

- When in doubt between two approaches, choose the one that results in higher quality, not the one that's faster.
- When reviewing others' work, hold it to the same standard you'd hold your own best work.
- When something feels wrong, surface it — don't rationalize it away for the sake of progress.

## Severity Vocabulary

Two severity scales appear at different pipeline stages. Map between them when synthesizing assessments or applying findings:

| Assessment stage (assess-*, cross-talk) | Convergence stage (reviewer findings) | Meaning |
|---|---|---|
| Critical / High | must-fix | Blocks the artifact — incorrect behavior, missing requirement, real risk |
| Medium | should-fix | Should be addressed — debt, fragility, degraded experience |
| Low | nit | Optional improvement — never blocks convergence |
