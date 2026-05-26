# Skill & Agent Authoring Guide

How to write skills and agents for Loom. Follow this when creating new files in `skills/` or `agents/`.

## Core principles

1. **Conciseness is recurring cost.** Skill content stays in context every turn once loaded. Before keeping any line, apply the three-question test:
   - Does Claude need this? (If Claude already knows it, delete.)
   - Does this justify its token cost? (It stays in context every turn.)
   - Would removing this cause the wrong output? (If not, delete.)

2. **Positive framing over prohibition.** Tell the agent what TO do, not what NOT to do. Negative instructions require the model to infer the inverse. When you must prohibit, explain WHY — Claude generalizes from rationale to edge cases.

3. **Hard-to-easy ordering.** Place the constraint most likely to be violated first. Research shows 25% performance difference based on constraint ordering alone in multi-turn contexts.

4. **Position anchoring.** Critical rules at the top (first thing read). Output format at the bottom (last thing read before acting). Never bury important constraints in the middle of a long file.

5. **Match specificity to fragility.** Fragile operations (git commands, parseable output, API calls) get exact scripts. Judgment calls (analysis, writing, review quality) get high-level guidance. Don't over-specify what Claude already knows how to do.

6. **Examples for style, rules for behavior.** If the desired output format or quality varies without guidance, show 1-3 diverse examples. For behavioral constraints, state the rule with its rationale. Don't use examples for mechanical procedures.

7. **One term per concept.** Pick one word and use it throughout: "ticket" or "task", not both. Inconsistent terminology forces the model to infer synonymy instead of following instructions.

8. **No repeated context.** Orchestrator modules build on each other sequentially. Never restate what a prior phase produced — the AI already has it. No "Inputs" sections listing what the caller already passed.

9. **One-sentence role, not a persona.** "You are a senior engineer evaluating spec completeness" focuses behavior. Multi-paragraph persona descriptions waste tokens without improving output.

10. **Reserve emphasis for invariants.** MUST/NEVER/CRITICAL only for safety or correctness invariants. Normal prose for everything else. Claude 4.x overtriggers on emphatic language — it interprets "NEVER" as more absolute than you intend, causing refusals or rigid behavior where judgment was needed.

11. **Explain WHY for non-obvious constraints.** "Prefer default branch for non-artifact files during merge conflicts" is a rule. Adding "(config/dependency conflicts break deploys)" makes it a generalizable principle.

12. **Line budgets.** SKILL.md under 300 lines, AGENT.md under 150 lines. If approaching the limit, split reference material into a separate file that the skill reads on demand.

## Domain skill template

Domain skills live at `skills/<domain>/<name>/SKILL.md`. They are spawned as subagents by the orchestrator with curated context.

```markdown
---
name: kebab-case-name
description: "What it does and when to use it, in third person. State triggers, not process — if the description summarizes the workflow, the model may follow the summary instead of reading the full skill."
---

# Skill Name

{1-2 sentences: what this skill produces and for whom.}

## Constraints

{3-7 rules. Hardest/most-critical first. Positive framing.
 Each gets a WHY in parentheses when the reason isn't obvious.}

- Produce X before Y (Y depends on X for validation)
- Use exact terminology from the ticket description (downstream agents match on these terms)
- Write to output_path only — no side effects outside that file

## Process

{Numbered steps. Imperative voice. Match specificity to fragility.}

1. Read the upstream artifact at `{artifact_path}`.
2. Evaluate against the criteria in ticket notes.
3. Write findings to `{output_path}` using the format below.

## Output

{Exact format ONLY when the orchestrator or downstream steps parse it.
 Omit this section entirely for free-form output.}

The last line of your response must be:
STATUS: complete

## Examples

{1-3 input/output pairs ONLY for judgment-heavy skills where output
 quality varies significantly without them. Omit for procedural skills.
 Diverse cases — cover the edge, not just the happy path.}

### Example: edge case — spec with ambiguous scope

Input: ...
Output: ...
```

## Agent template

Agents live at `agents/<name>/AGENT.md`. They are independent reviewers spawned in parallel. They produce a verdict and a report. They have no side effects.

```markdown
---
name: kebab-case-name
description: "What it evaluates and what verdict it produces. Triggers, not process."
tools: [Read, Bash, Grep]
model: sonnet
---

# Agent Name

{One sentence: what perspective this agent brings to a review.}

## Verdict

The last line of your response must be exactly one of:
STATUS: complete — VERDICT: pass
STATUS: complete — VERDICT: needs-work

## Evaluation criteria

{What to look for. Positive framing. Hardest/most-violated criteria first.
 Use contrast examples sparingly — "X not Y" — to disambiguate judgment calls.}

- Every acceptance criterion has a corresponding test (not just happy-path coverage)
- Error messages include enough context for the user to self-diagnose (not just "something went wrong")
- API contracts match the engineering spec exactly (field names, types, nullability)

## Report format

{Structure for the written report. Keep minimal — the orchestrator reads
 the verdict line; humans read the report.}

Write your findings as:

### Summary
{2-3 sentences: overall assessment}

### Findings
{Bulleted list. Each finding: what's wrong, where, and what "fixed" looks like.}
```

## Shared module style

Shared modules at `shared/*.md` are read sequentially within a single session. They are imperative checklists, not standalone documents.

- No preamble beyond a one-line purpose statement
- No Inputs/Output sections (the AI has context from prior phases)
- No "This gives you..." summaries (the AI knows what it just processed)
- Error messages inline with exact format strings
- Real gotchas called out (heredoc quoting, TOCTOU races, merge conflicts)
- Steps numbered, imperative voice, no fluff

## Entry-point skill style

Entry-point skills at `skills/work/SKILL.md` and `skills/review/SKILL.md` are the orchestrator itself. They define the full phase sequence.

- Phase structure with clear boundaries (Phase 0, 1, 2...)
- Error recovery at each phase ("if X fails, revert status, release lock, stop")
- Boundary rules as a short Rules section within the execution phase
- No repeated context between phases

## Anti-patterns

These waste tokens or degrade output:

| Pattern | Why it's bad | Do instead |
|---|---|---|
| `## Inputs` table listing caller-provided context | AI already has it — you're restating its own memory | Omit; reference values inline in steps |
| `## Output` listing what the AI just produced | Same — it knows what it wrote | Omit unless downstream parsing requires a format |
| "This gives you: X, Y, Z" after a step | Narrating obvious results | Omit |
| "You are a meticulous, detail-oriented..." | Multi-sentence personas waste tokens | One sentence max |
| DO NOT / NEVER lists without WHY | Model infers the inverse poorly; overtriggers on emphasis | Positive rule + rationale |
| Worked examples for mechanical steps | Examples are for judgment, not procedures | Step-by-step commands instead |
| Repeating downstream parsing rules | Single source of truth; repetition drifts | Reference: "using the format in X" |
| Explaining shell/git/tool defaults | Claude knows how git works | Only document surprising behavior |
