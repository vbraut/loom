# Dispatch Script Contract

The `scripts/next-task.sh` script handles multi-session-safe ticket dispatch. The MCP server lacks the three capabilities needed for safe dispatch: sequence dependency checking, filesystem-based concurrency locks, and atomic pick-next sorting.

## Modes

| Mode | Command | Filters | Use case |
|------|---------|---------|----------|
| work | `next-task.sh work <assignee>` | `todo` status only | `/loom:work` dispatch |
| review | `next-task.sh review <assignee>` | `review` status only | `/loom:review` dispatch |

## Exit codes

| Code | Meaning | Orchestrator action |
|------|---------|---------------------|
| 0 | Ticket claimed — ID printed to stdout | Proceed with claimed ticket |
| 1 | No eligible tickets | Stop gracefully |
| 2 | Lock contention — could not acquire dispatch lock after retries | Stop with error |
| 3 | Usage error | Stop with error |

## Sorting priority

Within a mode, tickets are sorted by:
1. Priority: HIGH > MEDIUM > LOW
2. Status rank (within mode's eligible statuses)
3. Ticket age (lower ticket number = older = picked first)

## Concurrency safety

- Filesystem lock at `backlog/.locks/dispatch/` (mkdir-based)
- Stale lock detection: locks older than 10 minutes are removed
- Retry: up to 10 attempts with 30-second waits

## Assignee format

The orchestrator passes a timestamped session lock as the `<assignee>` argument: `@work-{ts}` or `@review-{ts}`. The script sets this value atomically during the claim — no subsequent MCP override is needed.

## Dependency checking

The script checks sequence dependencies via `backlog sequence list`. A ticket is only eligible if all its dependencies are satisfied (in `done` status or unsequenced).

## Integration with orchestrator

1. Orchestrator runs `next-task.sh <mode> "@{mode}-$(date +%s)"`
2. Script prints claimed ticket ID to stdout (exit 0) or nothing (exit 1+)
3. Orchestrator reads ticket ID from stdout
4. Orchestrator transitions status via MCP (for work: `todo` → `active`)
5. Orchestrator reads ticket metadata via `task_view`
6. Orchestrator proceeds with resolve
