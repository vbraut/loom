# Initialize

Set up the execution context after dispatch has claimed a ticket.

## Inputs

- `ticket_id` — from dispatch
- `ticket_data` — from dispatch (full task_view response)
- `config` — from config loader

## Steps

### 1. Determine ticket type

Read the ticket's labels from `ticket_data`. Match each label against playbook files in `{loom_plugin_dir}/playbooks/`. A playbook file is `playbooks/{name}.md` — the label must match `{name}` exactly.

- **Zero matches**: `ERROR: No playbook found for ticket {ticket_id}. Labels: [{labels}]. Available playbooks: [{playbook_files}]. Add a label matching a playbook name.`
- **Multiple matches**: `ERROR: Ticket {ticket_id} has multiple labels matching playbooks: [{matches}]. One ticket, one type — remove extra labels.`
- **One match**: This is the ticket type. Store it.

### 2. Read playbook

Read `{loom_plugin_dir}/playbooks/{type}.md` in full. This is the step sequence to execute. Keep it in context — the orchestrator follows it inline.

### 3. Read ticket notes (feedback context)

Extract the notes field from `ticket_data`. If the ticket has been rejected before, notes will contain feedback from prior review cycles. Pass these notes as context to every step in the playbook — skills and agents receive them alongside their other context fields.

### 4. Ensure worktree

Check if a worktree already exists for this ticket:
- Branch name: `loom/{ticket_id_lowercase}` (e.g., `loom/bl-042`)
- Worktree path: `.loom/worktrees/{ticket_id_lowercase}/`

If the worktree exists (from a prior run or rejection):
- Sync it: `git -C {worktree_path} merge main` (resolve conflicts if needed)
- The existing artifacts from prior runs are preserved — skills decide what to do with them.

If no worktree exists:
- Create branch from main: `git branch loom/{ticket_id_lowercase}`
- Create worktree: `git worktree add {worktree_path} loom/{ticket_id_lowercase}`

## Output

After initialization:
- `ticket_type` — the matched playbook name
- `playbook_content` — full playbook text (in context)
- `ticket_notes` — feedback/notes from ticket (may be empty)
- `worktree_path` — absolute path to the worktree
