#!/usr/bin/env bash
set -euo pipefail

# next-task.sh — Atomic "claim next task" for the Loom SDLC pipeline.
# Acquires a dispatch lock, picks the highest-priority eligible task,
# assigns it to the caller, releases the lock, prints the task ID.
#
# Usage:
#   ./next-task.sh work  <assignee>   # pick next work task
#   ./next-task.sh review <assignee>  # pick next review task
#
# Requires: BACKLOG_CWD env var pointing to the backlog directory.
# Exit codes: 0=claimed, 1=no eligible tasks, 2=lock failed, 3=usage error

# ── Constants ───────────────────────────────────────────────────────

STALE_ASSIGNEE_SECONDS=$((12 * 3600))  # 12 hours
NOW=$(date +%s)

# ── Input validation ────────────────────────────────────────────────

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <work|review> <assignee>" >&2
  exit 3
fi

MODE="$1"
ASSIGNEE="$2"

if [[ "$MODE" != "work" && "$MODE" != "review" ]]; then
  echo "Error: mode must be 'work' or 'review', got '$MODE'" >&2
  exit 3
fi

if [[ ! "$ASSIGNEE" =~ ^@${MODE}-[0-9]+$ ]]; then
  echo "Error: assignee must match @${MODE}-<timestamp>, got '$ASSIGNEE'" >&2
  exit 3
fi

if [[ -z "${BACKLOG_CWD:-}" ]]; then
  echo "Error: BACKLOG_CWD is not set" >&2
  exit 3
fi

if [[ ! -d "$BACKLOG_CWD" ]]; then
  echo "Error: BACKLOG_CWD is not a directory: $BACKLOG_CWD" >&2
  exit 3
fi

if ! command -v backlog &>/dev/null; then
  echo "Error: 'backlog' command not found in PATH" >&2
  exit 3
fi

LOCK_DIR="$BACKLOG_CWD/.loom/dispatch.lock"

# ── Helpers ─────────────────────────────────────────────────────────

log() { echo "$@" >&2; }

# Check if an assignee string means "free" (empty, @none, @released, or stale timestamp).
is_free() {
  local assignee="$1"
  [[ -z "$assignee" ]] && return 0
  [[ "$assignee" == "@none" ]] && return 0
  [[ "$assignee" == "@released" ]] && return 0
  if [[ "$assignee" =~ ^@(work|review)-([0-9]+)$ ]]; then
    local ts="${BASH_REMATCH[2]}"
    (( (NOW - ts) > STALE_ASSIGNEE_SECONDS )) && return 0
  fi
  return 1
}

# Get the assignee field for a task ID (single CLI call, cached).
# Returns __ERROR__ sentinel on CLI failure.
declare -A ASSIGNEE_CACHE=()
get_assignee() {
  local tid="$1"
  if [[ -n "${ASSIGNEE_CACHE[$tid]+x}" ]]; then
    echo "${ASSIGNEE_CACHE[$tid]}"
    return
  fi
  local raw
  if ! raw=$(timeout 60 backlog task "$tid" --plain 2>/dev/null); then
    ASSIGNEE_CACHE[$tid]="__ERROR__"
    echo "__ERROR__"
    return
  fi
  local val
  val=$(echo "$raw" | grep "^Assignee:" | sed 's/^Assignee: //' || true)
  ASSIGNEE_CACHE[$tid]="$val"
  echo "$val"
}


# ── Dispatch lock ───────────────────────────────────────────────────

# Cross-platform mtime in epoch seconds.
get_mtime() {
  local path="$1"
  # BSD stat (macOS)
  stat -f %m "$path" 2>/dev/null && return
  # GNU stat (Linux)
  stat -c %Y "$path" 2>/dev/null && return
  # Fallback: no mtime available
  echo ""
}

acquire_lock() {
  mkdir -p "$BACKLOG_CWD/.loom"

  if [[ -d "$LOCK_DIR" ]]; then
    local mtime
    mtime=$(get_mtime "$LOCK_DIR")
    if [[ -n "$mtime" ]]; then
      local lock_age=$(( NOW - mtime ))
      if (( lock_age > 600 )); then
        rmdir "$LOCK_DIR" 2>/dev/null || true
        log "Removed stale dispatch lock (${lock_age}s old)"
      fi
    else
      # Cannot determine age — remove as possibly stale
      rmdir "$LOCK_DIR" 2>/dev/null || true
      log "Removed dispatch lock (could not determine age)"
    fi
  fi

  local acquired=false
  for attempt in 1 2 3 4 5; do
    if mkdir "$LOCK_DIR" 2>/dev/null; then
      acquired=true
      break
    fi
    log "Dispatch lock held by another agent. Waiting 30s... (attempt $attempt/5)"
    sleep 30
  done

  if [[ "$acquired" == true ]]; then
    log "Dispatch lock acquired"
  else
    log "LOCK_FAILED: Could not acquire dispatch lock after 5 attempts"
    exit 2
  fi
}

release_lock() {
  rmdir "$LOCK_DIR" 2>/dev/null || true
}

# ── Parsers ─────────────────────────────────────────────────────────

# Parse grouped task list into lines: STATUS PRIORITY TASK_ID
parse_grouped_list() {
  local current_status=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^([a-z][-a-z]*):$ ]]; then
      current_status="${BASH_REMATCH[1]}"
      continue
    fi
    if [[ "$line" =~ ^[[:space:]]+\[([A-Z]+)\][[:space:]]+([A-Z]+-[0-9]+(\.[0-9]+)?) ]]; then
      echo "$current_status ${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    fi
  done
}

# Parse sequence list -> newline-separated unblocked task IDs.
# Emits all tasks from Unsequenced + Sequence 1 (all have satisfied deps).
parse_unblocked() {
  local in_section="" seq_num=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^Unsequenced: ]]; then
      in_section="unsequenced"; continue
    fi
    if [[ "$line" =~ ^Sequence\ ([0-9]+): ]]; then
      seq_num="${BASH_REMATCH[1]}"
      in_section="sequence"; continue
    fi
    if [[ "$line" =~ ^[[:space:]]+([A-Z]+-[0-9]+(\.[0-9]+)?) ]]; then
      local tid="${BASH_REMATCH[1]}"
      if [[ "$in_section" == "unsequenced" ]]; then
        echo "$tid"
      elif [[ "$in_section" == "sequence" && "$seq_num" -eq 1 ]]; then
        echo "$tid"
      fi
    fi
  done
}

priority_rank() {
  case "$1" in
    HIGH)   echo 1 ;;
    MEDIUM) echo 2 ;;
    LOW)    echo 3 ;;
    *)      echo 9 ;;
  esac
}

# Convert ticket ID to a numeric sort key. ABC-049 -> 49000, ABC-049.01 -> 49001.
ticket_sort_key() {
  local tid="$1"
  if [[ "$tid" =~ ^[A-Z]+-0*([0-9]+)\.([0-9]+)$ ]]; then
    echo $(( ${BASH_REMATCH[1]} * 1000 + ${BASH_REMATCH[2]} ))
  elif [[ "$tid" =~ ^[A-Z]+-0*([0-9]+)$ ]]; then
    echo $(( ${BASH_REMATCH[1]} * 1000 ))
  else
    echo 999000
  fi
}

# ── Selection ───────────────────────────────────────────────────────

# pick_task <target_status> <check_sequences>
#   target_status: the status to filter for (e.g. "todo", "review")
#   check_sequences: "true" to filter by unblocked sequences, "false" to skip
pick_task() {
  local target_status="$1"
  local check_sequences="$2"

  local grouped_raw
  if ! grouped_raw=$(timeout 60 backlog task list --plain 2>/dev/null); then
    log "Warning: backlog task list failed"
    return
  fi

  local parsed
  parsed=$(echo "$grouped_raw" | parse_grouped_list)

  # Optionally filter by sequences
  local unblocked=""
  if [[ "$check_sequences" == "true" ]]; then
    local seq_output
    if seq_output=$(timeout 60 backlog sequence list --plain 2>/dev/null); then
      unblocked=$(echo "$seq_output" | parse_unblocked)
      if [[ -z "$unblocked" ]]; then
        log "Warning: sequence list returned no unblocked tasks; skipping sequence filtering"
        check_sequences="false"
      fi
    else
      log "Warning: backlog sequence list failed; skipping sequence filtering"
      check_sequences="false"
    fi
  fi

  local sort_lines=""
  local candidate_count=0
  while IFS=' ' read -r status prio tid; do
    [[ -z "$tid" ]] && continue

    # Only consider tasks in the target status
    [[ "$status" != "$target_status" ]] && continue

    # If checking sequences, skip tasks not in unblocked set
    if [[ "$check_sequences" == "true" ]]; then
      if ! echo "$unblocked" | grep -qxF "$tid"; then
        continue
      fi
    fi

    # Check assignee
    local assignee
    assignee=$(get_assignee "$tid")
    if [[ "$assignee" == "__ERROR__" ]]; then
      log "Warning: could not fetch assignee for $tid; skipping"
      continue
    fi
    is_free "$assignee" || continue

    local prank num
    prank=$(priority_rank "$prio")
    num=$(ticket_sort_key "$tid")
    sort_lines+="$prank $num $tid"$'\n'
    candidate_count=$((candidate_count + 1))
  done <<< "$parsed"

  # Format sanity check
  if [[ "$candidate_count" -eq 0 && -n "$grouped_raw" ]]; then
    log "Warning: 0 candidates from non-empty task list — possible format change"
  fi

  echo "$sort_lines" | grep -v '^$' | sort -n -k1,1 -k2,2 | head -1 | awk '{print $3}'
}

# ── Main ────────────────────────────────────────────────────────────

acquire_lock
trap release_lock EXIT

TARGET_STATUS=""
CHECK_SEQUENCES=""
case "$MODE" in
  work)
    TARGET_STATUS="todo"
    CHECK_SEQUENCES="true"
    ;;
  review)
    TARGET_STATUS="review"
    CHECK_SEQUENCES="false"
    ;;
esac

PICKED=$(pick_task "$TARGET_STATUS" "$CHECK_SEQUENCES")

if [[ -z "$PICKED" ]]; then
  log "No eligible tasks for mode '$MODE'"
  exit 1
fi

# Claim the task
EDIT_ERR=$(timeout 60 backlog task edit "$PICKED" -a "$ASSIGNEE" --plain 2>&1 >/dev/null) || {
  log "Failed to claim $PICKED: $EDIT_ERR"
  exit 1
}

echo "$PICKED"
exit 0
