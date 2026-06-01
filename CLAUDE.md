# Loom — Development Rules

## Architecture

- Entry-point skills in `skills/work/SKILL.md` and `skills/review/SKILL.md` — one level deep, discovered by Claude Code plugin
- Shared modules in `shared/` — config, claim, transition, convergence, cross-talk, quality-principles, elicitation-methods.csv
- Playbooks in `playbooks/` — declarative step sequences per ticket type, with conditional agents via `**When:**` and step gates via `**Skip when:**`
- Agents in `agents/<name>/AGENT.md` — subagents spawned by the orchestrator (doers and reviewers alike)
- Personas in `personas/<name>.md` — domain expert profiles injected into persona-reviewer agent; `_universal.md` for shared quality principles
- Templates in `templates/` — universal methodology, not project-specific
- Scripts in `scripts/` — `validate.sh` (structural checks), `install-hooks.sh` (pre-commit hook)
- Plugin manifest in `.claude-plugin/plugin.json`

## Boundary rules

1. Agents never invoke other agents. The orchestrator decides composition.
2. Agents write tracking artifacts to `output_path` and work products to the worktree (files the agent is instructed to create or modify as part of its task) — no backlog writes, no git operations.
3. The framework never writes to project config. It reads `sdlc.config.yml` and context paths.

## Adding an agent

1. Read `templates/skill-authoring.md` for structure and principles
2. Create `agents/<name>/AGENT.md` with YAML frontmatter (`name`, `description`, and optionally `tools`, `model`)
3. Directory name must be kebab-case and match the `name` field
4. Add the agent to the relevant playbook in `playbooks/`
5. Run `scripts/validate.sh`

Note: entry-point skills (`skills/work/`, `skills/review/`) are orchestrators, not agents. Do not add new entry points without updating `validate.sh`.

## Adding a playbook

1. Create `playbooks/<type>.md` — filename must match the `type:` label value (e.g., `type:code-fix` → `playbooks/code-fix.md`)
2. Run `scripts/validate.sh`

## Conventions

- Kebab-case for all directories
- `SKILL.md` and `AGENT.md` always uppercase
- No project-specific content in the framework

## Co-change rule

When you add, rename, or remove a skill, agent, or config field:
1. Update the built-in ticket types table in README.md if ticket types changed
2. Run `scripts/validate.sh`
Treat these updates as part of the change, not a follow-up task.
