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

## Playbook pipelines

Each ticket type maps to a playbook — a declarative step sequence the orchestrator executes autonomously. Three mechanisms recur across playbooks:

### Assessment pipeline

Shared by all work playbooks. Prevents anchoring bias through independent assessment, then enables genuine debate through real agent-to-agent cross-talk.

```
  INDEPENDENT ASSESSMENT            CROSS-TALK                 SYNTHESIS
  ┌────────────────────────┐   ┌────────────────────────┐   ┌──────────────────┐
  │                        │   │                        │   │                  │
  │  5 cognitive agents    │   │  Each agent receives   │   │  assess-         │
  │  + N persona reviewers │──▶│  all others' findings  │──▶│  synthesizer     │
  │                        │   │  via SendMessage.      │   │                  │
  │  All assess in parallel│   │  Updates position.     │   │  Compiles the    │
  │  with no cross-talk.   │   │  Repeats until no      │   │  converged       │
  │  Named for SendMessage.│   │  Critical/High remain  │   │  positions into  │
  │                        │   │  or max rounds (3).    │   │  one approach.   │
  └────────────────────────┘   └────────────────────────┘   └──────────────────┘
```

Cognitive agents apply method diversity (DMAD): inversion, decomposition, analogy, dependency mapping, naive questioning. Persona reviewers apply domain expertise: PM and Dev always, plus 1-3 selected dynamically from the [persona pool](#personas).

### Convergence loops

Used to validate artifacts (PRDs, plans, code) through iterative review.

```
  ┌─── reviewers (parallel) ───┐
  │                             │
  │  reviewer-a ── VERDICT ─────┤── all pass ──▶ next step
  │  reviewer-b ── VERDICT ─────┤      │
  │  reviewer-c ── VERDICT ─────┤  any needs-work
  │  ...                        │      │
  └─────────────────────────────┘      ▼
            ▲                   apply-review-fixes
            │                          │
            └──── next round ──────────┘

  Exit: N consecutive clean rounds, or max rounds reached.
```

### planning

Produces a PRD with optional HTML mocks. 12 steps.

```
 1 ── research-codebase-arch ────── explore architecture, product focus
 │
 2 ── draft-prd ─────────────────── problem, requirements, UX, criteria
 │
 │    ┌─ ASSESS PRD (parallel, named) ──────────────────────────────┐
 3    │ assess-inversion      assess-dependency     persona-pm      │
 │    │ assess-decomposition  assess-outsider       persona-dev     │
 │    │ assess-analogy                              persona-{...}   │
 │    └────────────────── outputs: *-r1.md (initial round) ────────┘
 │
 4 ── CROSS-TALK ────────────────── SendMessage rounds (max 3)
 │                                   outputs: *-r2.md, *-r3.md, ...
 5 ── assess-synthesizer ────────── compile converged positions
 │
 6 ── apply-review-fixes ────────── revise PRD with synthesis findings
 7 ── elicit-approach ───────────── 10 methods from 50-method registry
 8 ── apply-review-fixes ────────── revise PRD with elicitation findings
 │
 │    ┌─ CONVERGE PRD (max 5 rounds, 2 consecutive clean) ─────────┐
 9    │ requirements-reviewer    security-reviewer                   │
 │    │ regression-analyst       edge-case-hunter                    │
 │    │ simplification-reviewer  adversarial-reviewer                │
 │    │ design-system-reviewer†  ↻ apply-review-fixes               │
 │    └─────────────────────────────────────────────────────────────┘
 │
10 ── create-mocks‡ ─────────────── HTML mockups from PRD
 │
 │    ┌─ CONVERGE MOCKS (max 3 rounds, if step 10 produced mocks) ─┐
11    │ mock-alignment-reviewer  design-system-reviewer†             │
 │    │ ↻ apply-review-fixes                                        │
 │    └─────────────────────────────────────────────────────────────┘
 │
12 ── completion

† when design_system configured  ‡ skipped if no UI changes
```

### implementation

Produces an assessed implementation plan, then code. Requires PR for transition. 15 steps.

```
 1 ── research-codebase-arch ────── explore architecture, code focus
 2 ── draft-implementation-plan ─── requirements → file changes, ordered by dependency
 │
 │    ┌─ ASSESS PLAN (parallel, named) ─────────────────────────────┐
 3    │ assess-inversion      assess-dependency     persona-pm      │
 │    │ assess-decomposition  assess-outsider       persona-dev     │
 │    │ assess-analogy                              persona-{...}   │
 │    └────────────────── outputs: *-r1.md (initial round) ────────┘
 │
 4 ── CROSS-TALK ────────────────── SendMessage rounds (max 3)
 │                                   outputs: *-r2.md, *-r3.md, ...
 5 ── assess-synthesizer ────────── compile converged positions
 │
 6 ── apply-review-fixes ────────── revise plan with synthesis findings
 7 ── elicit-approach ───────────── 10 methods from registry
 8 ── apply-review-fixes ────────── revise plan with elicitation findings
 │
 │    ┌─ CONVERGE PLAN (max 5 rounds, 2 consecutive clean) ────────┐
 9    │ requirements-reviewer    security-reviewer                   │
 │    │ regression-analyst       edge-case-hunter                    │
 │    │ simplification-reviewer  adversarial-reviewer                │
 │    │ ↻ apply-review-fixes                                        │
 │    └─────────────────────────────────────────────────────────────┘
 │
10 ── implement ─────────────────── execute the converged plan
 │
 │    ┌─ CONVERGE CODE (max 6 rounds, 2 consecutive clean) ────────┐
11    │ requirements-reviewer    security-reviewer                   │
 │    │ regression-analyst       edge-case-hunter                    │
 │    │ simplification-reviewer  design-system-reviewer†             │
 │    │ ↻ apply-review-fixes                                        │
 │    └─────────────────────────────────────────────────────────────┘
 │
12 ── run-tests + test-coverage ─── parallel; ↻ retry from 10 on failure
13 ── capture-screenshots ───────── mobile + desktop viewports
14 ── visual-parity-reviewer ────── compare to mocks; ↻ retry from 10
15 ── completion (PR required)

† when design_system configured
```

### code-fix

Bug investigation and fix. Requires PR for transition. 8 steps.

```
 1 ── research-codebase-arch ────── locate bug, draft fix approach
 │
 │    ┌─ ASSESS (parallel, named) ──────────────────────────────────┐
 2    │ assess-inversion      assess-dependency     persona-pm      │
 │    │ assess-decomposition  assess-outsider       persona-dev     │
 │    │ assess-analogy                              persona-{...}   │
 │    └────────────────── outputs: *-r1.md (initial round) ────────┘
 │
 3 ── CROSS-TALK ────────────────── SendMessage rounds (max 3)
 │                                   outputs: *-r2.md, *-r3.md, ...
 4 ── assess-synthesizer ────────── compile converged positions
 5 ── implement ─────────────────── fix the bug
 │
 │    ┌─ CONVERGE (max 6 rounds, 2 consecutive clean) ─────────────┐
 6    │ requirements-reviewer    security-reviewer                   │
 │    │ regression-analyst       edge-case-hunter                    │
 │    │ simplification-reviewer  design-system-reviewer†             │
 │    │ ↻ apply-review-fixes                                        │
 │    └─────────────────────────────────────────────────────────────┘
 │
 7 ── run-tests + test-coverage ─── parallel; ↻ retry from 5 on failure
 8 ── completion (PR required)

† when design_system configured
```

### Review playbooks

Run at the review gate before human approval. Lighter than work playbooks — no assessment or convergence.

```
planning-review                     implementation-review

1 ─ review-summarizer               1 ─ standards-reviewer
2 ─ ticket-planner                  2 ─ review-summarizer
    (decompose PRD into             3 ─ ticket-planner
     implementation tickets)            (propose follow-up tickets)
```

## Agent catalog

29 agents organized by function.

### Doer agents

| Agent | Purpose | Playbooks |
|-------|---------|-----------|
| research-codebase-arch | Explore architecture, produce context brief for all downstream agents | all |
| draft-prd | Create PRD from ticket — problem, requirements, UX, acceptance criteria | planning |
| draft-implementation-plan | Create technical plan — map requirements to file changes, ordered by dependency | implementation |
| implement | Write code following the assessed and converged approach | code-fix, implementation |
| create-mocks | Build HTML mockups for all screens and states in a PRD | planning |
| capture-screenshots | Screenshot running application at mobile and desktop viewports | implementation |

### Cognitive assessment agents

Five methods applied in parallel. Each adapts to artifact type — product-level reasoning for PRDs, code-level for plans and fixes.

| Agent | Method | What it does |
|-------|--------|-------------|
| assess-inversion | Inversion | Assume it shipped and failed — work backward to find causes |
| assess-decomposition | Decomposition | Break into atomic claims, challenge each against evidence |
| assess-analogy | Analogy | Find cross-domain patterns and simpler alternatives |
| assess-dependency | Dependency mapping | Trace critical paths, find missing prerequisites, sequencing errors |
| assess-outsider | Naive questioning | Identify unexplained assumptions, jargon, self-containment gaps |

### Assessment infrastructure

| Agent | Purpose |
|-------|---------|
| persona-reviewer | Domain expert review, parameterized with a [persona](#personas) profile |
| assess-synthesizer | Compile converged positions from cross-talk into unified approach |
| elicit-approach | Stress-test synthesis through 10 methods from 50-method registry |

### Convergence reviewers

All return `VERDICT: pass` or `VERDICT: needs-work`. Adapt to both code and document artifacts.

| Agent | Focus |
|-------|-------|
| requirements-reviewer | Correctness and completeness against ticket/PRD/plan requirements |
| regression-analyst | Blast radius — consumer impact, behavioral regressions |
| simplification-reviewer | Over-engineering, scope bloat, missed simplifications |
| security-reviewer | Injection, auth bypass, data exposure, cryptographic misuse |
| edge-case-hunter | Boundary conditions, unhandled paths, undefined states |
| adversarial-reviewer | Cynical catch-all — minimum 10 issues per review |
| design-system-reviewer | UI compliance with project design system (conditional) |
| mock-alignment-reviewer | PRD-to-mock coverage — every requirement has a visual |
| visual-parity-reviewer | Screenshot-to-mock comparison |

### Verification agents

| Agent | Purpose |
|-------|---------|
| run-tests | Execute the project's test suite |
| test-coverage | Map ticket requirements to test cases, identify coverage gaps |

### Feedback agent

| Agent | Purpose |
|-------|---------|
| apply-review-fixes | Apply reviewer findings — fixes, broader refactors, or reasoned pushback |

### Review agents

| Agent | Purpose | Playbooks |
|-------|---------|-----------|
| standards-reviewer | Flag custom code where industry-standard alternatives exist | implementation-review |
| review-summarizer | Synthesize work-phase artifacts into structured brief for human reviewer | both review playbooks |
| ticket-planner | Propose follow-up tickets from review findings and backlog context | both review playbooks |

### Personas

14 domain expert profiles injected into the persona-reviewer agent. PM and Dev are always included; others are selected dynamically based on ticket content.

| Always | Dynamic pool |
|--------|-------------|
| pm, dev | analyst, architect, craft, data, devops, end-user, qa, security, sm, tech-lead, tech-writer, ux |

## Research foundations

Loom's agent design is informed by multi-agent deliberation research. The principles below shaped the architecture; the specific agents and workflow are Loom's own design.

**Method diversity AND domain diversity.** DMAD — *"Breaking Mental Set to Improve Reasoning through Diverse Multi-Agent Debate"* (ICLR 2025) — showed that assigning structurally different reasoning methods to same-model agents outperforms giving them different personas alone. Loom applies both: five cognitive operations (inversion, decomposition, analogy, dependency mapping, naive questioning) provide method diversity, while persona-based reviewers (PM, Dev, UX, Security, Data, etc.) provide domain expertise diversity. Cognitive operations stress-test HOW the approach was reasoned about; personas stress-test WHAT domain concerns it addresses.

**Three-phase assessment: independent → cross-talk → synthesize.** Assessment follows a three-phase pattern emerging from recent multi-agent research. Phase 1: all assessment agents (cognitive and persona alike) assess independently in parallel with no cross-talk, avoiding the anchoring bias that M3MADBench (arXiv 2601.02854, 2026) found causes 65% of multi-agent errors through "collective delusion." Phase 2: agents engage in real cross-talk via SendMessage — each agent receives all other agents' findings and updates their position through iterative rounds until convergence (no remaining Critical/High concerns) or a round cap. This follows the CollabEval pattern (*"Enhancing LLM-as-a-Judge via Multi-Agent Collaboration"*, arXiv 2603.00993, 2026) of independent assessment followed by structured collaborative discussion, with the critical advantage that SendMessage preserves each agent's full context (files read, code traced, reasoning performed) rather than starting cold from written summaries. Phase 3: the synthesizer compiles the converged positions into a single self-contained approach document. Because cross-talk has already resolved most disagreements, the synthesizer acts as a compiler rather than an arbiter — it only resolves tensions that survived cross-talk rounds.

**Evidence-weighted synthesis over self-reported confidence.** *"Demystifying Multi-Agent Debate"* (arXiv 2601.19921, 2026) showed that confidence-modulated updates can break the martingale ceiling of vanilla multi-agent deliberation — but only with RL-trained calibration. Raw self-reported LLM confidence is poorly calibrated and systematically overconfident (*"LLMs are Overconfident"*, arXiv 2510.26995; *"Mind the Confidence Gap"*, arXiv 2502.11028). Loom uses evidence quality instead: the synthesizer evaluates whether findings cite specific code paths, trace actual behavior, and verify claims against the codebase. A single well-evidenced finding outweighs a vague majority. Cross-boundary convergence (cognitive + persona agents independently confirming the same concern) serves as the primary consensus signal.

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
