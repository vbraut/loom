# Loom — Implementation Plan

## Context

Loom is a portable AI-driven SDLC framework. Original design doc at `~/dev/reign/docs/design/sdlc-v2-design.md` (Reign repo). GitHub repo `vbraut/loom` (private).

Ten incremental steps. Each step produces a testable, reviewable unit. Steps 1-2 are infrastructure; 3-8 build playbooks in order of complexity; 9 migrates Reign; 10 adds cross-project routing.

**Standing directive:** For every step that builds playbooks or agents, study the Reign SDLC, RAW, and ai-shared-toolkit repos first. Identify what each does well for the problem at hand, then build a workflow that combines the strongest elements of all three.

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
- Agents: `agents/implement/AGENT.md`, `agents/apply-review-fixes/AGENT.md`, `agents/run-tests/AGENT.md`, `agents/research-codebase-arch/AGENT.md`, `agents/requirements-reviewer/AGENT.md`, `agents/regression-analyst/AGENT.md`, `agents/simplification-reviewer/AGENT.md`
- `shared/convergence.md` — reusable convergence loop handler
- All agents follow `templates/skill-authoring.md`

**Playbook summary:**
```
research-codebase-arch → implement → requirements-reviewer + regression-analyst + simplification-reviewer → [converge] → apply-review-fixes → run-tests
```

**Testable:** Create a code-fix ticket with a real bug. `/loom:work` investigates, fixes, reviews, transitions to `review`. `/loom:review` presents artifacts for approval.

## Step 4: Review flow + work workflow refinement

**Goal:** Build the review playbook and refine the work workflow. The review orchestrator already handles the human gate — this step populates the playbook that runs before it, and improves the work playbook based on patterns found in existing repos.

**Deliverables:**
- `playbooks/code-fix-review.md` — separate per-type review playbook (standards-reviewer → review-summarizer → ticket-planner)
- Agent: `agents/review-summarizer/AGENT.md` — synthesizes work-phase artifacts into structured brief for human reviewer
- Agent: `agents/ticket-planner/AGENT.md` — decomposes PRDs/specs into implementation tickets or identifies follow-up work from review summaries
- Agent: `agents/standards-reviewer/AGENT.md` — identifies custom implementations where industry-standard alternatives exist
- Agent: `agents/test-coverage/AGENT.md` — maps ticket requirements to test cases, runs parallel with run-tests in verify step
- Orchestrator pre-fetch for ticket-planner (`task_list()` → backlog snapshot)
- Work playbook updates: verify step (run-tests + test-coverage parallel), retry-from-step-2 on failure
- Both orchestrators pass `## config` (with `default_branch`) to agents
- All agents use `git diff {default_branch}...HEAD` for full branch diffs

**Testable:** Push a code-fix ticket through `/work` to `review`. Run `/loom:review` — playbook runs standards-reviewer, summarizer, ticket-planner, human gate presents artifacts, approve/reject. On rejection, verify feedback appears in ticket notes with `--- REVIEW REJECTION ---` delimiter.

## Step 5: Planning + implementation playbooks

**Goal:** Two ticket types that cover the full feature lifecycle from spec to shipped code. `type:planning` turns a PRD/spec into a technical implementation plan. `type:implementation` turns an approved plan into code with visual verification.

**Design decisions (from cross-repo research):**

- **Plan convergence includes regression-analyst** — not just requirements-reviewer. Regression-analyst checks the plan for blast radius: "if we change module X, what consumers break?" Catching this at plan time is cheaper than at code time. Inspired by Reign's multi-reviewer plan debate.
- **No separate `finalize-plan` agent** — plan convergence uses apply-review-fixes (same mechanism as code convergence). When convergence passes, the plan is finalized.
- **No separate `prd-compliance-auditor`** — requirements-reviewer already traces requirements to implementation via its Coverage Matrix. The PRD is passed as upstream.
- **No separate `fix-visual-deviations` agent** — on visual verify failure, retry from implement. The implement agent gets visual findings as upstream and fixes the code, then runs the full pipeline again.
- **Visual steps always run** — if no mocks/references exist, capture-screenshots still captures the live app (builds a visual baseline for future reference) and visual-parity-reviewer passes with no references to compare.
- **Review playbooks are optional** — code-fix convergence is already thorough enough without a dedicated review playbook. Types that don't have a `{type}-review.md` skip straight to the human gate.

### 5a: `type:planning`

**Work playbook (`playbooks/planning.md`):**
```
1. Research        — research-codebase-arch
2. Draft plan      — draft-plan
3. Plan converge   — requirements-reviewer + regression-analyst, max 3 rounds
4. Completion
```

The plan is a markdown file in the worktree. After review approval, it merges to main. Implementation tickets branch from main and inherit it.

**Review playbook (`playbooks/planning-review.md`):**
```
1. Summarize       — review-summarizer
2. Propose tickets — ticket-planner (decomposes plan into implementation tickets)
```

**New agent:** `agents/draft-plan/AGENT.md` — reads PRD/spec + research brief, produces technical implementation plan with file paths, specific changes, and dependency ordering.

### 5b: `type:implementation`

**Work playbook (`playbooks/implementation.md`):**
```
1. Research        — research-codebase-arch
2. Implement       — implement (upstream includes approved plan)
3. Converge        — requirements-reviewer + regression-analyst + simplification-reviewer, max 6 rounds
4. Verify          — run-tests + test-coverage (parallel)
5. Capture         — capture-screenshots
6. Visual verify   — visual-parity-reviewer
   On failure: retry from step 2
7. Completion      — pr: true
```

**Review playbook (`playbooks/implementation-review.md`):**
```
1. Evaluate standards — standards-reviewer
2. Summarize          — review-summarizer
3. Propose tickets    — ticket-planner
```

**New agents:**
- `agents/capture-screenshots/AGENT.md` — starts dev server, writes Playwright script, captures at mobile (390x844) + desktop (1280x800) viewports.
- `agents/visual-parity-reviewer/AGENT.md` — compares captured vs mock/reference screenshots. Evaluates layout, components, spacing, typography, colors. Returns VERDICT.

### 5c: Framework changes

- Make review playbooks optional in `shared/claim.md` and `skills/review/SKILL.md` — if no `{type}-review.md` exists, skip straight to human gate
- Drop `playbooks/code-fix-review.md`
- Update `scripts/validate.sh` — remove mandatory work/review pairing

### Summary

3 new agents: `draft-plan`, `capture-screenshots`, `visual-parity-reviewer`
4 new playbooks: `planning.md`, `planning-review.md`, `implementation.md`, `implementation-review.md`
1 dropped: `code-fix-review.md`
8 reused agents: research-codebase-arch, implement, requirements-reviewer, regression-analyst, simplification-reviewer, apply-review-fixes, run-tests, test-coverage + review agents (standards-reviewer, review-summarizer, ticket-planner)

**Testable:** Create a planning ticket from a spec. `/loom:work` produces a plan, convergence reviews it (requirements + regression). `/loom:review` summarizes and proposes implementation tickets. Approve → implementation tickets created. Pick an implementation ticket, `/loom:work` implements from plan, converges, verifies, captures screenshots. `/loom:review` runs standards review, summarizes, proposes follow-ups.

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

## Step 7: Specialist reviewer agents

**Goal:** Expand the reviewer library with specialist agents that catch classes of issues the current panel misses. These are opt-in — playbooks include them in their convergence panels when relevant. Not every playbook needs every reviewer.

**Why:** Cloudflare's production data (30-day window across their codebase) shows specialist reviewers catch issues that generalist reviewers consistently miss. Their security reviewer found 484 critical findings, performance reviewer generated 14,615 findings, and compliance reviewer generated 9,654 findings — all orthogonal to what correctness/regression/simplification reviewers catch.

**Deliverables:**
- `agents/security-reviewer/AGENT.md` — injection, auth bypass, secrets, crypto, data exposure
- `agents/performance-reviewer/AGENT.md` — N+1 queries, algorithmic regression, unnecessary allocations, bundle size
- `agents/compliance-reviewer/AGENT.md` — project-specific architectural rules, coding standards, RFC adherence (reads from `sdlc.config.yml` context paths)
- Update `playbooks/code-fix.md` and `playbooks/implementation.md` to include specialist reviewers in convergence panels
- Design brief with full context: `docs/specialist-reviewers.md`

**Integration model:** Playbooks opt in by adding specialist reviewers to their convergence step's `**Agents:**` field. The orchestrator treats them identically — same STATUS/VERDICT protocol, same findings format, same convergence logic. No framework changes needed.

**Testable:** Run a code-fix ticket with security reviewer enabled. Verify it produces structured findings, participates in convergence, and its findings flow to apply-review-fixes correctly.

## Step 8: Non-code playbooks

**Goal:** Strategy, brand, and copy workflows — artifact-only playbooks.

**Deliverables:**
- `playbooks/strategy-definition.md`
- `playbooks/brand-exploration.md`
- `playbooks/copy-definition.md`
- Any new agents specific to these workflows (likely minimal — most reuse existing)

## Step 9: Reign migration

**Goal:** Migrate Reign off the v1 SDLC system to Loom.

**Deliverables:**
- `reign/sdlc.config.yml` pointing to existing context
- Update `reign-backlog/backlog.config.yml` statuses to 5-stage model
- Migrate existing tickets (re-label with types, split multi-phase)
- Remove old `.claude/skills/sdlc-work/` and `.claude/skills/sdlc-review/`
- Update `reign/CLAUDE.md` to reference Loom

## Step 10: Cross-project successor routing

**Goal:** Allow ticket-planner to route follow-up tickets to different backlogs — e.g., framework improvements discovered while working on a project get filed in Loom's own backlog, not the current project's.

**Deliverables:**
- `target` field in ticket-planner proposals (`"project"` default, `"framework"` for Loom itself)
- Transition step routes `task_create` to the appropriate backlog based on target
- Loom gets its own `sdlc.config.yml` (Loom is itself a project with the same config contract)
- Orchestrator resolves framework backlog via `{loom_plugin_dir}/sdlc.config.yml`

**Testable:** Run a review that produces both project and framework proposals. Verify project proposals go to the current backlog and framework proposals go to Loom's backlog.

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
