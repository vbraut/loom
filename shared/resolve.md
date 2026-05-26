# Resolve

Resolve a claimed ticket into an actionable execution context: type, notes, worktree.

## Steps

### 1. Determine ticket type

Read the ticket's labels from `ticket_data`. Match each label against playbook files in `{loom_plugin_dir}/playbooks/`. A playbook file is `playbooks/{name}.md` — the label must match `{name}` exactly.

- **Zero matches**: `ERROR: No playbook found for ticket {ticket_id}. Labels: [{labels}]. Available playbooks: [{playbook_files}]. Add a label matching a playbook name.`
- **Multiple matches**: `ERROR: Ticket {ticket_id} has multiple labels matching playbooks: [{matches}]. One ticket, one type — remove extra labels.`
- **One match**: This is the ticket type.

### 2. Read ticket notes

Extract the notes field from `ticket_data`. Pass notes as context to every playbook step — they contain feedback from prior review cycles.

### 3. Ensure worktree

Worktree path is relative to the **project root** (the directory containing `sdlc.config.yml`).

- Branch name: `loom/{ticket_id_lowercase}` (e.g., `loom/bl-042`)
- Worktree path: `{project_root}/.loom/worktrees/{ticket_id_lowercase}/`

Use the project's `default_branch` from config (defaults to `main`).

**If the worktree already exists** (prior run, rejection, or review pickup):
- Sync: `git -C {worktree_path} merge {default_branch} --no-edit`
- On merge conflict: prefer default branch for non-artifact files — config, dependencies, infrastructure (conflicts here break builds/deploys). Prefer worktree for artifact files — specs, plans, reviews, mocks under `.claude/` or `.loom/` (these represent the ticket's work-in-progress). For code files, three-way merge preserving both sides' intent.
- If unresolvable: `git merge --abort`, report the conflict, stop.

**If no worktree exists:**
- If branch `loom/{ticket_id_lowercase}` already exists (orphaned): `git worktree add {worktree_path} loom/{ticket_id_lowercase}`, then sync as above.
- Otherwise: `git branch loom/{ticket_id_lowercase} {default_branch}`, then `git worktree add {worktree_path} loom/{ticket_id_lowercase}`
