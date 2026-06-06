# implementation-review

Review playbook for implementation tickets. Runs before the human gate.

## Steps

### 1. Evaluate standards

**Agent:** standards-reviewer
**Upstream:** `.loom/artifacts/{ticket_id}/research.md` (if exists)
**Output path:** `.loom/artifacts/{ticket_id}/standards-review.md`

### 2. Summarize

**Agent:** review-summarizer
**Upstream:** all ticket references from the work phase (same as step 1), plus `.loom/artifacts/{ticket_id}/standards-review.md`
**Output path:** `.loom/artifacts/{ticket_id}/review-summary.md`

### 3. Propose tickets

**Agent:** ticket-planner
**Upstream:** `.loom/artifacts/{ticket_id}/review-summary.md`, `.loom/artifacts/{ticket_id}/backlog-snapshot.md`
**Output path:** `.loom/artifacts/{ticket_id}/successor-proposals.md`

**Pre-fetch:** The orchestrator pre-fetches the backlog snapshot:
- Call `task_list()` via MCP
- Filter client-side to: id, title, type label, status. If more than 200 tickets, truncate to the 200 most recent.
- Write filtered list to `.loom/artifacts/{ticket_id}/backlog-snapshot.md`
- If `task_list()` fails, create the file with: "Backlog snapshot unavailable — proposals may overlap with existing tickets."
