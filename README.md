# Loom

AI-driven SDLC framework for Claude Code. One plugin, any project.

Loom weaves skills (surgical playbooks) and agents (independent reviewers)
into declarative workflows driven by ticket type. You write a config file.
Loom handles the rest — planning, implementation, review gates, feedback loops.

## Quick start

1. Add the plugin:
   ```bash
   claude --plugin-dir ~/dev/loom
   ```

2. Create `sdlc.config.yml` in your project root:
   ```yaml
   version: 1
   project:
     backlog_cwd: ~/dev/my-project-backlog
     context:
       brand_voice: docs/brand/copy/brand-context.md
   ```

3. Configure the Backlog.md MCP server in `.mcp.json`:
   ```json
   {
     "mcpServers": {
       "backlog": {
         "command": "backlog",
         "args": ["mcp", "start", "--cwd", "/path/to/backlog-repo"]
       }
     }
   }
   ```

4. Run:
   ```
   /loom:work           # pick up next ticket
   /loom:work BL-042    # work on specific ticket
   /loom:review         # review next ticket at a gate
   ```

## How it works

```
backlog → todo → active → review → done
                   ↑         │
                   └─────────┘
```

Human curates backlog → todo. Agents pick from todo.
Ticket type determines which playbook runs.
One ticket = one type = one playbook. Complex features span
multiple tickets chained via successor creation.
Skills do the work. Agents review it. Humans approve at gates.

## Concepts

- **Skills** — surgical, single-purpose playbooks (write-spec, implement, ...)
- **Agents** — independent reviewers spawned in parallel (panel-reviewer, ...)
- **Orchestrator** — reads your config, composes skills + agents, manages state
- **Playbook** — declarative step sequence per ticket type

## Built-in ticket types

| Type | Playbook | Description |
|------|----------|-------------|
| product-definition | product-definition | PRD + mocks for a feature |
| code-implementation | code-implementation | Build from an approved PRD or plan |
| code-fix | code-fix | Bug investigation + fix |
| strategy-definition | strategy-definition | Research and decision documents |
| brand-exploration | brand-exploration | Visual system — palette, typography, logos |
| copy-definition | copy-definition | Messaging, tone of voice, copy decks |

## Project footprint

Your project needs two files: `sdlc.config.yml` (Loom config) and `.mcp.json` (Backlog.md MCP server).
Context (brand voice, design system) points to docs you already have.

## Development

See [CLAUDE.md](CLAUDE.md) for framework development rules.

Run structural validation:
```bash
bash scripts/validate.sh
```
