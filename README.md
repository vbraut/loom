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

- **Agents** — single-purpose subagents, both doers and reviewers (e.g., implement, requirements-reviewer, persona-reviewer)
- **Personas** — domain expert profiles (PM, UX, Security, Data, etc.) injected into the parameterized persona-reviewer agent for domain-specific assessment
- **Orchestrator** — glue between backlog, git, and playbooks: picks tickets, manages worktrees, executes the right playbook, transitions state
- **Playbook** — the authority on what happens for a ticket type: which agents to invoke, in what order, with what context. Supports conditional steps via `**When:**` fields

## Ticket types

| Type | Description | Status |
|------|-------------|--------|
| code-fix | Bug investigation + fix | Done |
| planning | PRD from spec or ticket description | Done |
| implementation | Implementation plan + code from a PRD or spec | Done |
| product-definition | PRD + mocks for a feature | Planned |
| strategy-definition | Research and decision documents | Planned |
| brand-exploration | Visual system — palette, typography, logos | Planned |
| copy-definition | Messaging, tone of voice, copy decks | Planned |

## Research foundations

Loom's agent design is informed by multi-agent deliberation research. The principles below shaped the architecture; the specific agents and workflow are Loom's own design.

**Method diversity AND domain diversity.** DMAD — *"Breaking Mental Set to Improve Reasoning through Diverse Multi-Agent Debate"* (ICLR 2025) — showed that assigning structurally different reasoning methods to same-model agents outperforms giving them different personas alone. Loom applies both: five cognitive operations (inversion, decomposition, analogy, dependency mapping, naive questioning) provide method diversity, while persona-based reviewers (PM, Dev, UX, Security, Data, etc.) provide domain expertise diversity. Cognitive operations stress-test HOW the approach was reasoned about; personas stress-test WHAT domain concerns it addresses.

**Single-round independence.** DMAD itself uses multi-round cross-talk (agents refine after seeing peers). Loom's assessment agents run independently with no cross-talk — a deliberate trade-off. M3MADBench (arXiv 2601.02854, 2026) found that 65% of multi-agent errors come from "collective delusion" where agents mutually reinforce wrong assumptions. Independence sacrifices self-correction but avoids groupthink. Iterative refinement happens later, in the convergence review loop.

**Confidence-weighted synthesis.** *"Demystifying Multi-Agent Debate"* (arXiv 2601.19921, 2026) proved that vanilla multi-agent deliberation preserves expected correctness as a martingale — it cannot systematically improve. Confidence-modulated updates break this ceiling (1-3pp on reasoning benchmarks). Loom's assessment agents self-rate confidence 1-10; the synthesizer weights findings by evidence quality rather than vote count.

**Collaborative over adversarial.** M3MADBench showed collaborative analysis outperforms adversarial across all five tested domains — adversarial framing introduces divergent noise that degrades results. Loom's agents seek truth through independent analysis, not assigned positions.

**Disagreement classification and trade-off naming.** Error catches (one agent found a real flaw) vs. value tensions (both sides valid, priorities decide) and explicit "What You Lose" cost naming draw from the Council Review pattern, itself built on Karpathy's LLM Council concept.

**Universal quality principles.** All agents receive shared quality principles — quality over speed, pre-existing issues in touched files must be fixed, no partial solutions. These override agent-specific rules when in conflict, ensuring consistent standards across the entire workflow.

**50-method elicitation registry.** After assessment synthesis, the elicit-approach agent selects 10 contextually relevant methods from a 50-method registry spanning 12 categories (core reasoning, risk analysis, creative techniques, competitive analysis, etc.). Methods are applied sequentially, each building on prior findings.

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
