# planning-review

Review playbook for planning tickets. Runs before the human gate.

## Steps

### 1. Summarize

**Agent:** review-summarizer
**Upstream:** all ticket references registered during the work phase (retrieve via MCP `task_view`, pass each reference path that exists and is non-empty)
**Output path:** `.loom/artifacts/{ticket_id}/review-summary.md`

### 2. Propose tickets

**Agent:** ticket-planner
**Upstream:** `.loom/artifacts/{ticket_id}/review-summary.md`, `.loom/artifacts/{ticket_id}/backlog-snapshot.md`
**Output path:** `.loom/artifacts/{ticket_id}/successor-proposals.md`

**Pre-fetch:** The orchestrator pre-fetches the backlog snapshot:
- Call `task_list()` via MCP
- Filter client-side to: id, title, type label, status. If more than 200 tickets, truncate to the 200 most recent.
- Write filtered list to `.loom/artifacts/{ticket_id}/backlog-snapshot.md`
- If `task_list()` fails, create the file with: "Backlog snapshot unavailable — proposals may overlap with existing tickets."
