# Loom — Implementation Plan

## Context

Loom is a portable AI-driven SDLC framework. Original design doc at `~/dev/reign/docs/design/sdlc-v2-design.md` (Reign repo). GitHub repo `vbraut/loom` (private).

Eight incremental steps. Each step produces a testable, reviewable unit. Steps 1-2 are infrastructure; 3-7 build playbooks in order of complexity; 8 migrates Reign.

## Step 1: Repo scaffold + orchestrator skeleton — COMPLETE

**PR:** #1 (`step-1/scaffold` branch)

**What was built:**

```
~/dev/loom/
├── .claude-plugin/
│   └── plugin.json                 # plugin manifest
├── .github/
│   └── workflows/
│       └── ci.yml                  # validate.sh in CI
├── .gitignore
├── skills/
│   ├── work/SKILL.md               # /loom:work — orchestrator entry point
│   └── review/SKILL.md             # /loom:review — human review gate
├── shared/
│   ├── config.md                   # config loader (sdlc.config.yml)
│   ├── claim.md                    # ticket pickup, locking, type routing, worktree
│   └── transition.md               # commit, status changes, lock release, cleanup
├── playbooks/
│   └── .gitkeep
├── agents/
│   └── .gitkeep
├── templates/
│   ├── sdlc.config.example.yml     # annotated example config
│   └── skill-authoring.md          # authoring guide for agents
├── scripts/
│   ├── validate.sh                 # structural checks
│   └── install-hooks.sh            # pre-commit hook installer
├── CLAUDE.md                       # framework dev rules
└── README.md                       # landing page (steampunk ASCII art)
```

**Divergences from original plan:**

| Original plan | What happened | Why |
|---|---|---|
| `schema/sdlc.config.schema.json` | Not created | Nothing consumes it. Config validation lives in `config.md` instructions + example template. |
| `backlog-adapter/mcp.md` | Not created | MCP server is self-describing. Separate docs for AI-consumed content drifts. |
| `backlog-adapter/dispatch.md` | Not created | Dispatch contract lives in the script itself + `claim.md` module. |
| `skills/define/.gitkeep` etc. | Not created | Empty placeholders add no value. Created when populated in steps 3-7. |
| `orchestrator/shared/initialize.md` | Now `claim.md` | Merged dispatch + resolve into one module: pick, lock, type, worktree. |
| `templates/skill-authoring.md` | Added | Codified authoring principles based on research (Anthropic docs, academic papers). Not in original plan. |
| `.github/workflows/ci.yml` | Added | Runs validate.sh on push. |
| `scripts/install-hooks.sh` | Added | Pre-commit hook for validate.sh. |
| `default_branch` config field | Added | Avoids hardcoding `main` in claim.md and transition.md. |

**Authoring guide principles** (applied to all existing files):
- Three-question conciseness test: Does Claude need this? Token cost justified? Would removing cause wrong output?
- Positive framing over prohibition (explain WHY when constraining)
- Hard-to-easy constraint ordering (hardest/most-violated first)
- Match specificity to fragility (exact scripts for git, high-level guidance for judgment)
- Position anchoring: rules first, action last (constraints before "go" instruction)
- No repeated context between sequential modules

**CLAUDE.md minimalism**: Boundary rules and conventions trimmed to only content not already stated in orchestrator skills, transition.md, or validate.sh. Three boundary rules (was five), two conventions removed.

**Self-documenting philosophy**: The framework has no separate documentation files for AI. Entry-point orchestrators have SKILL.md, agents have AGENT.md, shared modules carry their own instructions. README is for humans only.

## Step 2: Claim script

**Goal:** Framework can claim tickets from a Backlog.md repo using the 5-stage lifecycle.

**Deliverables:**
- `scripts/next-task.sh` — ticket auto-pick + locking for both `/work` (todo) and `/review` (review)
- Lock format: `@work-{ts}` / `@review-{ts}`, release via `@released`, stale after 12h
- Sequence dependency checking (blocked tickets not picked)
- Filesystem-based concurrency lock (mkdir atomicity)

**Testable:** Point config at a test backlog with tickets in various statuses. Run claim — it picks the right ticket, acquires lock, orchestrator reads metadata via MCP.

## Step 3: `code-fix` playbook — vertical slice

**Goal:** Simplest end-to-end playbook. Proves the full orchestrator loop: claim → execute playbook → convergence → transition.

**Deliverables:**
- `playbooks/code-fix.md`
- Agents: `agents/implement/AGENT.md`, `agents/apply-review-fixes/AGENT.md`, `agents/run-tests/AGENT.md`, `agents/research-codebase-arch/AGENT.md`, `agents/requirements-reviewer/AGENT.md`, `agents/regression-analyst/AGENT.md`
- All agents follow `templates/skill-authoring.md`
- Convergence loop in orchestrator (count verdicts, re-run on needs-work, cap rounds)

**Playbook summary:**
```
research-codebase-arch → implement → requirements-reviewer + regression-analyst → [converge] → apply-review-fixes → run-tests
```

**Testable:** Create a code-fix ticket with a real bug. `/loom:work` investigates, fixes, reviews, transitions to `review`. `/loom:review` presents artifacts for approval.

## Step 4: Review flow

**Goal:** Build the review playbook and its agents. The review orchestrator already handles the human gate — this step populates the playbook that runs before it.

**Deliverables:**
- `playbooks/code-fix-review.md` (or review steps added to `code-fix.md` — decided when building)
- Agent: `agents/review-summarizer/AGENT.md`
- Agent: `agents/plan-successors/AGENT.md`
- Orchestrator pre-fetch for plan-successors (`task_list()` → full backlog context)

**Testable:** Push a code-fix ticket through `/work` to `review`. Run `/loom:review` — playbook runs summarizer + successor planner, human gate presents artifacts, approve/reject. On rejection, verify feedback appears in ticket notes.

## Step 5: `code-implementation` playbook

**Goal:** Most complex playbook — plan debate, implementation, visual verification, multi-round review.

**Deliverables:**
- `playbooks/code-implementation.md`
- New agents: `agents/draft-plan/AGENT.md`, `agents/finalize-plan/AGENT.md`, `agents/take-screenshots/AGENT.md`, `agents/fix-visual-deviations/AGENT.md`, `agents/prd-compliance-auditor/AGENT.md`, `agents/visual-parity-summary/AGENT.md`
- Reuses from step 3: `research-codebase-arch`, `implement`, `requirements-reviewer`, `apply-review-fixes`, `run-tests`

**Playbook summary:**
```
research-codebase-arch → draft-plan → requirements-reviewer [plan debate] → finalize-plan →
implement → requirements-reviewer + prd-compliance-auditor [converge] → apply-review-fixes →
run-tests → take-screenshots → visual-parity-summary → fix-visual-deviations →
requirements-reviewer [final]
```

## Step 6: `product-definition` playbook + quality agents

**Goal:** Completes the primary feature lifecycle (define → implement → ship).

**Deliverables:**
- `playbooks/product-definition.md`
- New agents: `agents/write-spec/AGENT.md`, `agents/capture-refs/AGENT.md`, `agents/create-mocks/AGENT.md`, `agents/refine-spec/AGENT.md`, `agents/refine-mocks/AGENT.md`, `agents/prd-mock-alignment/AGENT.md`, `agents/edge-case-hunter/AGENT.md`, `agents/design-system-guardian/AGENT.md`, `agents/critique/AGENT.md`, `agents/polish/AGENT.md`
- Note: ship skills eliminated — PR creation handled by `shared/transition.md`. No `skills/ship/` domain.

**Playbook summary:**
```
research-codebase-design → write-spec → capture-refs → create-mocks → prd-mock-alignment →
requirements-reviewer + edge-case-hunter + design-system-guardian [converge] → refine-spec → refine-mocks
```

## Step 7: Non-code playbooks

**Goal:** Strategy, brand, and copy workflows — artifact-only playbooks.

**Deliverables:**
- `playbooks/strategy-definition.md`
- `playbooks/brand-exploration.md`
- `playbooks/copy-definition.md`
- Any new agents specific to these workflows (likely minimal — most reuse existing)

## Step 8: Reign migration

**Goal:** Migrate Reign off the v1 SDLC system to Loom.

**Deliverables:**
- `reign/sdlc.config.yml` pointing to existing context
- Update `reign-backlog/backlog.config.yml` statuses to 5-stage model
- Migrate existing tickets (re-label with types, split multi-phase)
- Remove old `.claude/skills/sdlc-work/` and `.claude/skills/sdlc-review/`
- Update `reign/CLAUDE.md` to reference Loom

## Design decisions

### Backlog scoping: one backlog per project (1:1)

Each project gets its own backlog repo. `/loom:work` only picks tickets from the current project's `backlog_cwd`. This ensures the AI always has the correct CLAUDE.md in context (loaded from CWD at session start) and worktrees branch from the right repo.

No shared backlogs, no cross-project filtering. Cross-project visibility is a human concern, not an AI execution concern.

### Playbook authority

The playbook is the sole authority on what happens during execution. The orchestrator's role is limited to three concerns:

1. **Ticket lifecycle** — dispatch, lock, status transitions, lock release
2. **Git lifecycle** — worktree setup, commit, push, PR, merge, cleanup
3. **Playbook routing** — match ticket type → playbook, read and execute it

The orchestrator knows HOW to invoke agents (AGENT.md location, STATUS protocol, MCP registration) but the playbook decides WHEN and WITH WHAT. This applies to both `/loom:work` and `/loom:review` — review adds only the human gate (present artifacts, ask approve/reject, route to transition).

Previously, the orchestrator hardcoded step-type handlers (rigid "For each skill step" and "For each agent step" templates) and review-specific phases (review-summarizer, plan-successors as always-run agents). These are now playbook decisions. claim.md resolves the playbook path; the orchestrator reads and executes it.

### Unified agent model

The original design distinguished "domain skills" (`skills/<domain>/<name>/SKILL.md`) from "agents" (`agents/<name>/AGENT.md`). In practice, both are subagents spawned by the orchestrator via the Agent tool. The doer/reviewer distinction is a role (expressed in persona and constraints), not a type (expressed in file format). Sequential vs parallel execution is a playbook decision.

Unified under `agents/` only. `skills/` is reserved for the two entry-point orchestrators (work, review) that Claude Code discovers as user-invocable commands. `tools` and `model` are optional frontmatter fields — doer agents that don't need specific tool restrictions or model overrides simply omit them.

### Cross-project successor routing

Follow-up tickets from plan-successors can target either the current project or Loom itself (framework improvements discovered while working on a project). Two-target model:

- **`target: "project"`** (default) — created in the current project's `backlog_cwd`
- **`target: "framework"`** — created in Loom's own backlog, resolved by reading `{loom_plugin_dir}/sdlc.config.yml`

This works because Loom is itself a project with the same config contract. The orchestrator already knows `loom_plugin_dir`, so it can read Loom's `sdlc.config.yml` to find its `backlog_cwd`. No registry of sibling projects needed.

Requires:
- Plan-successors agent outputs a `target` field per proposed action
- Transition step routes `task_create` to the appropriate backlog
- Loom has its own `sdlc.config.yml` (created when Loom manages its own development)

## Design doc divergences to reconcile

The design doc (`reign/docs/design/sdlc-v2-design.md`) has stale references that should be updated:

| Section | Stale reference | Current state |
|---|---|---|
| §2 | "The `backlog-adapter/` directory..." | Deleted — MCP is self-describing, dispatch contract in the script |
| §3 architecture diagram | Shows `backlog-adapter/` and `schema/` | Deleted |
| §6 skill file format | No mention of authoring guide | `templates/skill-authoring.md` governs all skill/agent writing |
| §8 framework tree | Shows `backlog-adapter/`, `schema/`, empty skill domain dirs | All deleted. Add `templates/skill-authoring.md` |
| §10 Step 1 deliverables | Lists `schema/`, `backlog-adapter/`, `initialize.md`, empty dirs | Updated in this plan |
| §12 documentation plan | `docs/authoring/skills.md` etc. | Now `templates/skill-authoring.md` (single file, in-framework) |
| §6 | Separate skill/agent file formats and directories | Unified under `agents/`. `skills/` reserved for entry-point orchestrators only. |
| §12 | CONTRIBUTING.md, freshness hashes, promptfoo evals | Future concerns — evaluate when Step 8 is reached |
