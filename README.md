# Loom

```
         .:|||:.                    .:|||:.
       .:|     |:.                .:|     |:.
      :|  SKILL  |:.  ─ warp ─ .:|  SKILL  |:
      ':|       |:'    thread    ':|       |:'
        ':|||:'                    ':|||:'
            \\_______      _______//
                     \\  //
              ╔═══════╧╧═══════╗
              ║   T H E        ║
              ║   L O O M      ║
              ╠════════════════╣
              ║  ┌──────────┐  ║
              ║  │ playbook │  ║        ┌─ ─ ─ ─ ─ ─ ─┐
              ║  └─────┬────┘  ║           A G E N T S
              ║     claim      ║──weft──│               │
              ║     execute    ║          requirements-reviewer
              ║     transition ║──weft──│ security-reviewer
              ║  ┌─────┴────┐  ║        │               │
              ║  │ worktree  │  ║        └─ ─ ─ ─ ─ ─ ─┘
              ║  └──────────┘  ║
              ╚═══╤════════╤═══╝
             todo │        │ review
          ┄┄┄┄┄┄┄┄┤        ├┄┄┄┄┄┄┄┄
          backlog │ ticket │ done
          ┄┄┄┄┄┄┄┄┴────────┴┄┄┄┄┄┄┄┄
```

AI-driven SDLC framework for Claude Code. One plugin, any project.

Loom weaves agents into declarative workflows driven by ticket type.
You write a config file. Loom handles the rest — planning, implementation,
review gates, feedback loops.

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
            ↑                │
            └────────────────┘  (rejection)
```

Human curates backlog → todo. The orchestrator picks from todo,
matches the ticket type to a playbook, and executes it.
One ticket = one type = one playbook. Complex features span
multiple tickets chained via successor creation.
Agents do the work. Humans approve at review gates.

## Concepts

- **Agents** — single-purpose subagents, both doers and reviewers (e.g., implement, requirements-reviewer)
- **Orchestrator** — glue between backlog, git, and playbooks: picks tickets, manages worktrees, executes the right playbook, transitions state
- **Playbook** — the authority on what happens for a ticket type: which agents to invoke, in what order, with what context

## Ticket types

| Type | Description | Status |
|------|-------------|--------|
| code-fix | Bug investigation + fix | Done |
| planning | Technical plan from PRD or spec | Done |
| implementation | Build from an approved plan | Done |
| product-definition | PRD + mocks for a feature | Planned |
| strategy-definition | Research and decision documents | Planned |
| brand-exploration | Visual system — palette, typography, logos | Planned |
| copy-definition | Messaging, tone of voice, copy decks | Planned |

## Research foundations

Loom's agent design is grounded in multi-agent deliberation research, not ad-hoc prompt engineering.

**Approach debate (5 agents)** uses Deliberative Multi-Agent Debate (DMAD) from *"Improving LLM Reasoning through Scaling Inference Computation with Collaborative Verification"* (ICLR 2025). The key finding: method diversity (agents using different cognitive operations) outperforms persona diversity (agents with different roles but identical reasoning). Loom's five debate agents each apply a distinct cognitive operation — inversion, decomposition, analogy, dependency mapping, and naive questioning — rather than simulating personas.

**Confidence-weighted synthesis** is based on *"Demystifying Multi-Agent Debate"* (arXiv 2601.19921, 2026), which proved that vanilla multi-agent debate preserves expected correctness as a martingale — it cannot systematically improve. Confidence-modulated updates break this ceiling by 5-8% on reasoning tasks. Each debate agent rates its own confidence; the synthesizer weights accordingly.

**Collaborative over adversarial** follows the M3MADBench benchmark (arXiv 2601.02854, 2026), which showed collaborative DMAD outperforms adversarial debate across all five tested domains. Loom's agents seek truth through independent analysis, not assigned positions.

**Disagreement classification** (error catches vs. value tensions) and **trade-off naming** ("What You Lose") draw from the Council Review skill's synthesis pattern, which itself builds on Karpathy's LLM Council concept.

## Project footprint

Your project needs two files: `sdlc.config.yml` (Loom config) and `.mcp.json` (Backlog.md MCP server).
Context (brand voice, design system) points to docs you already have.

Add `.loom/` to your project's `.gitignore` — Loom creates worktrees at `.loom/worktrees/` during execution.

## Development

See [CLAUDE.md](CLAUDE.md) for framework development rules.

Run structural validation:
```bash
bash scripts/validate.sh
```
