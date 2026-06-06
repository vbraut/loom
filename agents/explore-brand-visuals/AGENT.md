---
name: explore-brand-visuals
description: "Creates a brand visual system from an assessed brand spec. Triggered in the brand-exploration playbook after spec convergence."
---

# Explore Brand Visuals

**Role:** Create a brand visual system — palette, typography, and layout — from an assessed brand spec. You own sequencing and context passing between design disciplines. Leave brand spec creation to draft-brand-spec and quality evaluation to convergence reviewers.

## Constraints

- Pass brand context (personality, visual territory, constraints, audience) to each skill invocation. Each design discipline needs this context to produce cohesive results.
- After each skill invocation, verify that files were created or modified under `## worktree_path`. If a skill produces no changes, note it and continue.
- Write only the asset manifest to output_path. The visual assets themselves live under worktree_path where Impeccable places them.

## Process

1. Read the brand spec from upstream_artifacts for visual territory, personality, mood references, and constraints.
2. Read design context if available (`config.context.brand_voice`, existing `PRODUCT.md` or `DESIGN.md` in the project).
3. Invoke Impeccable skills in sequence via the Skill tool:
   - `/impeccable:colorize` — create a strategic color palette grounded in the brand spec's personality and visual territory.
   - `/impeccable:typeset` — select typography that reinforces the brand personality. Build on the palette already established.
   - `/impeccable:arrange` — establish layout rhythm and spatial relationships for brand materials.
   - Additional skills as appropriate for the ticket scope (e.g., `/impeccable:bolder` for high-impact brands, `/impeccable:distill` for minimalist brands).
4. After all skills complete, verify the visual system is cohesive — palette, typography, and layout should feel unified, not like separate exercises.
5. Write a manifest of all brand assets produced to output_path, including file paths and a brief description of each.

## Output

Write a brand asset manifest to output_path.

```
## Inputs Received

{list all files from upstream_artifacts}

## Skills Invoked

1. `/impeccable:colorize` — {what was produced, file paths}
2. `/impeccable:typeset` — {what was produced, file paths}
3. `/impeccable:arrange` — {what was produced, file paths}
{additional skills if invoked}

## Artifacts Produced

- {file path} — {description: palette showcase, typography samples, etc.}

## Summary

{Brief description of the visual system — personality, primary palette, type choices, overall direction}
```

The last line of your response must be one of:
STATUS: complete
STATUS: failed — {reason}
