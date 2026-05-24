# Loom — Development Rules

## Architecture

- Entry-point skills in `skills/work/SKILL.md` and `skills/review/SKILL.md` — one level deep, discovered by Claude Code plugin
- Orchestrator shared modules in `orchestrator/shared/` — config, dispatch, resolve, transition
- Playbooks in `playbooks/` — declarative step sequences per ticket type
- Domain skills in `skills/<domain>/<name>/SKILL.md` — two levels deep, NOT discovered (orchestrator-only)
- Agents in `agents/<name>/AGENT.md` — structured input, structured output, no side effects
- Templates in `templates/` — universal methodology, not project-specific
- Backlog adapter in `backlog-adapter/` — MCP tool contract and dispatch script contract
- Schema in `schema/` — JSON Schema for `sdlc.config.yml`
- Scripts in `scripts/` — `validate.sh` (structural checks), `install-hooks.sh` (pre-commit hook)
- Plugin manifest in `.claude-plugin/plugin.json`

## Boundary rules

1. Skills never invoke other skills. The orchestrator decides composition.
2. Agents never write to the backlog. They write findings to `output_path` only.
3. The orchestrator never does domain work. It dispatches skills and agents.
4. The framework never writes to project config. It reads `sdlc.config.yml` and context paths.
5. Skills never run git state commands (commit, merge, checkout, worktree). Only skills in `skills/ship/` may run `git push` and create PRs.

## Adding a domain skill

1. Create `skills/<domain>/<name>/SKILL.md` with YAML frontmatter (`name`, `description`)
2. Directory name must be kebab-case and match the `name` field
3. Add the skill to the relevant playbook in `playbooks/`
4. Run `scripts/validate.sh`

Note: entry-point skills (`skills/work/`, `skills/review/`) are one level deep and require extra frontmatter fields (`user-invocable`, `argument-hint`). These are not domain skills — do not add new entry points without updating `validate.sh`.

## Adding an agent

1. Create `agents/<name>/AGENT.md` with YAML frontmatter (`name`, `description`, `tools`, `model`)
2. Add the agent to the relevant playbook
3. Run `scripts/validate.sh`

## Adding a playbook

1. Create `playbooks/<type>.md` with the step sequence in natural language
2. Tickets with a matching label will automatically route to it
3. Run `scripts/validate.sh`

## Conventions

- Kebab-case for all directories
- `SKILL.md` and `AGENT.md` always uppercase
- Playbook filenames match ticket type labels exactly
- No project-specific content in the framework

## Co-change rule

When you add, rename, or remove a skill, agent, or config field:
1. Update the built-in ticket types table in README.md if ticket types changed
2. Run `scripts/validate.sh`
Treat these updates as part of the change, not a follow-up task.
