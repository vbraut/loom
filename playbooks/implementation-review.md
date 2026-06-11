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

**Pre-fetch:** The orchestrator pre-fetches the backlog snapshot straight to disk — its content never enters orchestrator context:
```bash
BACKLOG_CWD="{backlog_cwd}" backlog task list --plain > "{worktree_path}/.loom/artifacts/{ticket_id}/backlog-snapshot.md" 2>/dev/null \
  || echo "Backlog snapshot unavailable — proposals may overlap with existing tickets." > "{worktree_path}/.loom/artifacts/{ticket_id}/backlog-snapshot.md"
```
