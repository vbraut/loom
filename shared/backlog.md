# Backlog Access Protocol

All ticket reads and mutations go through the `backlog` CLI via Bash. Never use a backlog MCP server — MCP responses echo the full task body on every call, which wastes context at scale.

## Invocation

Prefix every command with an explicit `BACKLOG_CWD` — the env var overrides the shell working directory, and an inherited value from the user's shell could silently target the wrong board:

```bash
BACKLOG_CWD="{backlog_cwd}" backlog task ...
```

## Reads

Full ticket view — only when the body is actually needed (claim, review summary):

```bash
BACKLOG_CWD="{backlog_cwd}" backlog task {id} --plain
```

For a single field, filter instead of loading the whole body into context:

```bash
BACKLOG_CWD="{backlog_cwd}" backlog task {id} --plain | grep '^Status:'
```

When a read's output is only consumed by an agent (e.g., a backlog snapshot pre-fetch), redirect it straight to a file — it never needs to enter the orchestrator's context.

## Mutations

Two rules:

1. **Batch.** Every field changing at the same moment goes into ONE `backlog task edit` call — status, assignee, notes, and references are all flags on the same invocation. Never issue back-to-back edits to the same ticket.
2. **Suppress the echo.** `task edit` prints the full task after editing. Discard stdout, keep stderr:

```bash
ERR=$(BACKLOG_CWD="{backlog_cwd}" backlog task edit {id} -s review -a @released --plain 2>&1 >/dev/null) \
  || { echo "backlog edit failed: $ERR"; }
```

A non-zero exit code means the mutation failed — follow the calling skill's error handling; never ignore it.

**Exception:** when a mutation is immediately followed by a need for the full ticket (claim's status transition), keep stdout and use the echo as the read — one call instead of two. The `edit --plain` echo is identical to `task view --plain`.

## References

Loom never writes ticket references. Work-phase artifacts live at the deterministic path `.loom/artifacts/{ticket_id}/` inside the worktree, and the progress file (`.loom/artifacts/{ticket_id}/progress.md`) records which of them are standing outputs — registering each file as a reference would bloat the task body that every subsequent read and edit echo pays for. The review phase resolves artifacts from the progress file, not from the ticket (skills/review/SKILL.md, "Work-phase artifact resolution").

Whatever references a ticket carries — PRD links and doc paths added at creation, or `.loom/artifacts/` entries written by tickets that transitioned before this protocol — are preserved verbatim, because no loom edit passes `--ref`.

If a reference edit is ever genuinely needed: `--ref` REPLACES the entire reference list — it does not append. Never call it with only a new path, or every prior reference is destroyed. Always write the full union of existing + new as repeated `--ref` flags in one edit.

## Notes

`--append-notes` appends safely and the flag can repeat within one call. Batch all note lines that accrue at the same moment into a single edit.
