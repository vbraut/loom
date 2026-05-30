# code-fix-review

Review playbook for code-fix tickets. Runs before the human gate.

## Steps

### 1. Evaluate standards

**Agent:** standards-reviewer
**Upstream:** all ticket references registered during the work phase (retrieve via MCP `task_view`, pass each reference path that exists and is non-empty)
**Output path:** `.loom/artifacts/{ticket_id}/standards-review.md`

Identify custom implementations where industry-standard alternatives exist.

### 2. Summarize

**Agent:** review-summarizer
**Upstream:** all ticket references from the work phase (same as step 1), plus `.loom/artifacts/{ticket_id}/standards-review.md`
**Output path:** `.loom/artifacts/{ticket_id}/review-summary.md`

Synthesize work-phase artifacts and standards review into a structured brief.

### 3. Propose tickets

**Agent:** ticket-planner
**Upstream:** `.loom/artifacts/{ticket_id}/review-summary.md`, `.loom/artifacts/{ticket_id}/backlog-snapshot.md`
**Output path:** `.loom/artifacts/{ticket_id}/successor-proposals.md`

**Pre-fetch (before spawning agent):** The orchestrator pre-fetches the backlog snapshot:
- Call `task_list()` via MCP
- Filter client-side to: id, title, type label, status. If more than 200 tickets, truncate to the 200 most recent.
- Write filtered list to `.loom/artifacts/{ticket_id}/backlog-snapshot.md`
- If `task_list()` fails, create the file with: "Backlog snapshot unavailable — proposals may overlap with existing tickets."

Propose tickets based on the review summary and backlog context.
