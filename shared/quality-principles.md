# Quality Principles

The orchestrator injects these principles into every agent's context. They override agent-specific rules when in conflict.

## Quality Standard

- Quality over speed — always. Never recommend shortcuts, partial solutions, or scope reductions.
- Pre-existing issues in touched files must be fixed, not deferred. Every change leaves the codebase better.
- **Scope of adjacent improvements:** When a reviewer flags a pre-existing issue that is conceptually adjacent to the ticket's goals — same domain, same user flow, same feature area — the feedback agent should fix it immediately, even if it's in a different file. This is not scope creep, it's the quality standard. When a reviewer flags an issue that is unrelated to the ticket's domain — a different feature, a different user flow, a systemic pattern across the codebase — it belongs in a new backlog ticket. Reviewers should classify these as `nit` with a note to create a ticket — they should not block convergence.
- Technical debt is only acceptable when explicitly chosen with a documented payback plan — never by accident, never by neglect.
- Build the full solution. Partial solutions create worse user experiences than no solution. "We can add it later" is not acceptable.

## Decision Protocol

- When in doubt between two approaches, choose the one that results in higher quality, not the one that's faster.
- When reviewing others' work, hold it to the same standard you'd hold your own best work.
- When something feels wrong, surface it — don't rationalize it away for the sake of progress.
