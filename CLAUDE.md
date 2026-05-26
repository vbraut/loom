# Loom — Development Rules

## Architecture

- Entry-point skills in `skills/work/SKILL.md` and `skills/review/SKILL.md` — one level deep, discovered by Claude Code plugin
- Shared modules in `shared/` — config, claim, transition
- Playbooks in `playbooks/` — declarative step sequences per ticket type
- Agents in `agents/<name>/AGENT.md` — subagents spawned by the orchestrator (doers and reviewers alike)
- Templates in `templates/` — universal methodology, not project-specific
- Scripts in `scripts/` — `validate.sh` (structural checks), `install-hooks.sh` (pre-commit hook)
- Plugin manifest in `.claude-plugin/plugin.json`

## Boundary rules

1. Agents never invoke other agents. The orchestrator decides composition.
2. Agents write to `output_path` only — no backlog writes, no git operations.
3. The orchestrator never does domain work. It dispatches agents.
4. The framework never writes to project config. It reads `sdlc.config.yml` and context paths.
5. All git operations (commit, push, merge, PR creation) are handled by transition.md.

## Adding an agent

1. Read `templates/skill-authoring.md` for structure and principles
2. Create `agents/<name>/AGENT.md` with YAML frontmatter (`name`, `description`, and optionally `tools`, `model`)
3. Directory name must be kebab-case and match the `name` field
4. Add the agent to the relevant playbook in `playbooks/`
5. Run `scripts/validate.sh`

Note: entry-point skills (`skills/work/`, `skills/review/`) are orchestrators, not agents. Do not add new entry points without updating `validate.sh`.

## Adding a playbook

1. Create `playbooks/<type>.md` with the step sequence in natural language
2. Tickets with a matching label will automatically route to it
3. Run `scripts/validate.sh`

## Conventions

- Kebab-case for all directories
- `SKILL.md` and `AGENT.md` always uppercase
- Playbook filenames match ticket type labels exactly
- No project-specific content in the framework
- All skill/agent authoring follows `templates/skill-authoring.md` — concise, positive-framed, specificity matched to fragility

## Co-change rule

When you add, rename, or remove a skill, agent, or config field:
1. Update the built-in ticket types table in README.md if ticket types changed
2. Run `scripts/validate.sh`
Treat these updates as part of the change, not a follow-up task.
