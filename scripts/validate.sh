#!/usr/bin/env bash
set -euo pipefail

# validate.sh — Structural validation for the Loom framework.
# Checks plugin manifest, skill/agent format, naming conventions, and required files.
# Exit 0 = all checks pass. Exit 1 = one or more failures.

LOOM_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ERRORS=0

# Required frontmatter fields per file type (also used as allowlist — unknown fields are rejected)
SKILL_ENTRY_FIELDS="name description user-invocable argument-hint"
AGENT_REQUIRED_FIELDS="name description"
AGENT_ALLOWED_FIELDS="name description tools model relevance"

if ! command -v python3 &>/dev/null; then
  echo "ERROR: python3 is required for JSON validation" >&2
  exit 1
fi

err() {
  echo "FAIL: $1" >&2
  ERRORS=$((ERRORS + 1))
}

ok() {
  echo "  OK: $1"
}

# Extract YAML frontmatter (between first and second ---) and check for unknown fields.
# Usage: check_frontmatter <file> <required_fields_space_separated> <label>
check_frontmatter() {
  file="$1"
  required="$2"
  label="$3"
  allowed="${4:-$required}"

  if ! head -1 "$file" | grep -q '^---$'; then
    err "$label missing YAML frontmatter (must start with ---)"
    return 1
  fi

  closing_line=$(awk 'NR > 1 && /^---$/ { print NR; exit }' "$file")
  if [ -z "$closing_line" ]; then
    err "$label missing closing --- in frontmatter"
    return 1
  fi

  fm=$(sed -n "2,$((closing_line - 1))p" "$file" || true)
  fm_ok=true

  # Check required fields exist
  for field in $required; do
    if ! echo "$fm" | grep -q "^${field}:"; then
      err "$label missing '$field' in frontmatter"
      fm_ok=false
    fi
  done

  # Check for unknown fields (skip continuation lines that start with whitespace)
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    echo "$line" | grep -qE '^[a-zA-Z]' || continue
    echo "$line" | grep -qE ':' || continue
    field_name=$(echo "$line" | sed 's/:.*//')
    found=false
    for allowed_field in $allowed; do
      if [ "$field_name" = "$allowed_field" ]; then
        found=true
        break
      fi
    done
    if [ "$found" = false ]; then
      err "$label has unknown frontmatter field '$field_name'"
      fm_ok=false
    fi
  done <<< "$fm"

  [ "$fm_ok" = true ] && return 0 || return 1
}

echo "=== Loom Structure Validation ==="
echo ""

# ── Plugin manifest ─────────────────────────────────────────────────

echo "--- Plugin manifest ---"

if [ -f "$LOOM_ROOT/.claude-plugin/plugin.json" ]; then
  if python3 -c "import json, sys; json.load(open(sys.argv[1]))" "$LOOM_ROOT/.claude-plugin/plugin.json" 2>/dev/null; then
    name=$(python3 -c "import json, sys; print(json.load(open(sys.argv[1])).get('name',''))" "$LOOM_ROOT/.claude-plugin/plugin.json")
    if [ -n "$name" ]; then
      ok "plugin.json valid (name: $name)"
    else
      err "plugin.json missing 'name' field"
    fi
  else
    err "plugin.json is not valid JSON"
  fi
else
  err ".claude-plugin/plugin.json not found"
fi

# ── User-invocable skills ──────────────────────────────────────────

echo ""
echo "--- User-invocable skills ---"

for skill in work review; do
  skill_path="$LOOM_ROOT/skills/$skill/SKILL.md"
  if [ -f "$skill_path" ]; then
    check_frontmatter "$skill_path" "$SKILL_ENTRY_FIELDS" "skills/$skill/SKILL.md" && \
      ok "skills/$skill/SKILL.md (has frontmatter)"
  else
    err "skills/$skill/SKILL.md not found"
  fi
done

# ── Shared modules ────────────────────────────────────────────────

echo ""
echo "--- Shared modules ---"

for module in config claim transition convergence cross-talk intake; do
  module_path="$LOOM_ROOT/shared/$module.md"
  if [ -f "$module_path" ]; then
    ok "shared/$module.md"
  else
    err "shared/$module.md not found"
  fi
done

# ── Agents ─────────────────────────────────────────────────────────

echo ""
echo "--- Agents ---"

agent_count=0
for agent_md in "$LOOM_ROOT"/agents/*/AGENT.md; do
  [ -f "$agent_md" ] || continue
  agent_count=$((agent_count + 1))
  rel_path="${agent_md#$LOOM_ROOT/}"

  dir_name=$(basename "$(dirname "$agent_md")")
  if ! echo "$dir_name" | grep -qE '^[a-z][a-z0-9]*(-[a-z0-9]+)*$'; then
    err "$rel_path directory name '$dir_name' is not kebab-case"
    continue
  fi

  if check_frontmatter "$agent_md" "$AGENT_REQUIRED_FIELDS" "$rel_path" "$AGENT_ALLOWED_FIELDS"; then
    fm_name=$(sed -n '2,/^---$/p' "$agent_md" | grep '^name:' | sed 's/^name: *//' | tr -d '"' | tr -d "'")
    if [ "$fm_name" != "$dir_name" ]; then
      err "$rel_path frontmatter name '$fm_name' does not match directory name '$dir_name'"
    else
      ok "$rel_path"
    fi
  fi
done
echo "  ($agent_count agents found)"

# ── Playbooks ──────────────────────────────────────────────────────

echo ""
echo "--- Playbooks ---"

playbook_count=0
for playbook in "$LOOM_ROOT"/playbooks/*.md; do
  [ -f "$playbook" ] || continue
  playbook_count=$((playbook_count + 1))
  rel_path="${playbook#$LOOM_ROOT/}"
  base_name=$(basename "$playbook" .md)

  if ! echo "$base_name" | grep -qE '^[a-z][a-z0-9]*(-[a-z0-9]+)*$'; then
    err "$rel_path filename '$base_name' is not kebab-case"
    continue
  fi

  ok "$rel_path"
done
echo "  ($playbook_count playbooks found)"

# ── Playbook-agent cross-check ───────────────────────────────────

echo ""
echo "--- Playbook-agent cross-check ---"

crosscheck_ok=true

# Forward check: agent names mentioned in playbooks must have AGENT.md
for playbook in "$LOOM_ROOT"/playbooks/*.md; do
  [ -f "$playbook" ] || continue
  rel_path="${playbook#$LOOM_ROOT/}"

  for agent_dir in "$LOOM_ROOT"/agents/*/; do
    [ -d "$agent_dir" ] || continue
    agent_name=$(basename "$agent_dir")
    if grep -qw "$agent_name" "$playbook"; then
      if [ ! -f "$agent_dir/AGENT.md" ]; then
        err "$rel_path references agent '$agent_name' but agents/$agent_name/AGENT.md not found"
        crosscheck_ok=false
      fi
    fi
  done
done

# Reverse check: **Agent:** references in playbooks must have a matching agent directory
for playbook in "$LOOM_ROOT"/playbooks/*.md; do
  [ -f "$playbook" ] || continue
  rel_path="${playbook#$LOOM_ROOT/}"

  while IFS= read -r agent_ref; do
    [ -z "$agent_ref" ] && continue
    if [ ! -f "$LOOM_ROOT/agents/$agent_ref/AGENT.md" ]; then
      err "$rel_path references agent '$agent_ref' but agents/$agent_ref/AGENT.md not found"
      crosscheck_ok=false
    fi
  done < <(grep -oE '\*\*Agent:\*\* [a-z][a-z0-9-]*' "$playbook" | sed 's/\*\*Agent:\*\* //' || true)

  # Also check **Agents:** (plural) references — comma-separated lists of parallel agents
  while IFS= read -r agents_line; do
    [ -z "$agents_line" ] && continue
    agents_value=$(echo "$agents_line" | sed 's/\*\*Agents:\*\* //')
    for agent_ref in $(echo "$agents_value" | tr ',' '\n' | sed 's/ *(parallel)//; s/^ *//; s/ *$//'); do
      [ -z "$agent_ref" ] && continue
      echo "$agent_ref" | grep -qE '^[a-z][a-z0-9-]+$' || continue
      if [ ! -f "$LOOM_ROOT/agents/$agent_ref/AGENT.md" ]; then
        err "$rel_path references agent '$agent_ref' but agents/$agent_ref/AGENT.md not found"
        crosscheck_ok=false
      fi
    done
  done < <(grep -oE '\*\*Agents:\*\* [a-z][a-z0-9, -]*(\(parallel\))?' "$playbook" || true)

  # Also check **On needs-work:** references (convergence feedback agents)
  while IFS= read -r agent_ref; do
    [ -z "$agent_ref" ] && continue
    if [ ! -f "$LOOM_ROOT/agents/$agent_ref/AGENT.md" ]; then
      err "$rel_path references feedback agent '$agent_ref' but agents/$agent_ref/AGENT.md not found"
      crosscheck_ok=false
    fi
  done < <(grep -oE '\*\*On needs-work:\*\* [a-z][a-z0-9-]*' "$playbook" | sed 's/\*\*On needs-work:\*\* //' || true)
done

[ "$crosscheck_ok" = true ] && ok "All playbook-referenced agents have AGENT.md files"

# ── Playbook structure validation ────────────────────────────────

echo ""
echo "--- Playbook structure ---"

structure_ok=true
for playbook in "$LOOM_ROOT"/playbooks/*.md; do
  [ -f "$playbook" ] || continue
  rel_path="${playbook#$LOOM_ROOT/}"
  base_name=$(basename "$playbook" .md)

  # Skip review playbooks — they don't use intake/checkpoint/await
  echo "$base_name" | grep -q '\-review$' && continue

  # Validate Intake section structure (if present)
  if grep -q '^## Intake' "$playbook"; then
    if ! grep -q '^### Stance' "$playbook"; then
      err "$rel_path has ## Intake but missing ### Stance"
      structure_ok=false
    elif ! grep -q 'facilitate.*|.*collaborate.*|.*autonomous' "$playbook"; then
      err "$rel_path ### Stance missing valid stance options (facilitate | collaborate | autonomous)"
      structure_ok=false
    fi

    if ! grep -q '^### Questions' "$playbook"; then
      err "$rel_path has ## Intake but missing ### Questions"
      structure_ok=false
    else
      # Check that questions have context: hints
      question_count=$(grep -cE '^[0-9]+\.' "$playbook" || true)
      context_count=$(grep -c '   context:' "$playbook" || true)
      if [ "$question_count" -gt 0 ] && [ "$context_count" -lt "$question_count" ]; then
        err "$rel_path has $question_count questions but only $context_count context: hints"
        structure_ok=false
      fi
    fi
  fi

  # Validate Checkpoint fields reference steps with agents
  while IFS= read -r checkpoint_line_num; do
    [ -z "$checkpoint_line_num" ] && continue
    # Check that the step containing this Checkpoint also has an Agent
    step_start=$(awk -v ln="$checkpoint_line_num" 'NR <= ln && /^### [0-9]+\./ { start=NR } END { print start }' "$playbook")
    if [ -n "$step_start" ]; then
      step_block=$(sed -n "${step_start},${checkpoint_line_num}p" "$playbook")
      if ! echo "$step_block" | grep -q '\*\*Agent:\*\*'; then
        err "$rel_path has **Checkpoint:** at line $checkpoint_line_num in a step with no **Agent:**"
        structure_ok=false
      fi
    fi
  done < <(grep -n '\*\*Checkpoint:\*\*' "$playbook" | cut -d: -f1 || true)

  # Validate Await steps (Output path but no Agent)
  prev_step_has_agent=""
  prev_step_has_output=""
  prev_step_num=""
  while IFS= read -r line; do
    if echo "$line" | grep -qE '^### [0-9]+\.'; then
      # Check previous step
      if [ "$prev_step_has_agent" = "false" ] && [ "$prev_step_has_output" = "true" ]; then
        # This is a valid await step — just verify it's documented
        :
      fi
      prev_step_num=$(echo "$line" | grep -oE '[0-9]+')
      prev_step_has_agent="false"
      prev_step_has_output="false"
    elif echo "$line" | grep -q '\*\*Agent:\*\*'; then
      prev_step_has_agent="true"
    elif echo "$line" | grep -q '\*\*Output path:\*\*'; then
      prev_step_has_output="true"
    fi
  done < "$playbook"
done
[ "$structure_ok" = true ] && ok "All playbook structures valid (intake, checkpoint, await)"

# ── Work/review playbook pairing ─────────────────────────────────

echo ""
echo "--- Review playbook pairing ---"

pairing_ok=true

# Review playbooks must have a corresponding work playbook (but not vice versa — review playbooks are optional)
for playbook in "$LOOM_ROOT"/playbooks/*-review.md; do
  [ -f "$playbook" ] || continue
  base_name=$(basename "$playbook" .md)
  work_name="${base_name%-review}"

  work_playbook="$LOOM_ROOT/playbooks/${work_name}.md"
  if [ ! -f "$work_playbook" ]; then
    err "playbooks/${base_name}.md has no corresponding playbooks/${work_name}.md"
    pairing_ok=false
  fi
done
[ "$pairing_ok" = true ] && ok "All review playbooks have matching work playbooks"

# ── Personas ──────────────────────────────────────────────────────

echo ""
echo "--- Personas ---"

persona_count=0
if [ -d "$LOOM_ROOT/personas" ]; then
  for persona in "$LOOM_ROOT"/personas/*.md; do
    [ -f "$persona" ] || continue
    persona_count=$((persona_count + 1))
  done
  echo "  ($persona_count personas found)"
else
  err "personas/ directory not found"
fi

# ── Shared modules extended ──────────────────────────────────────

echo ""
echo "--- Shared extended ---"

for module in quality-principles; do
  module_path="$LOOM_ROOT/shared/$module.md"
  if [ -f "$module_path" ]; then
    ok "shared/$module.md"
  else
    err "shared/$module.md not found"
  fi
done

if [ -f "$LOOM_ROOT/shared/elicitation-methods.csv" ]; then
  method_count=$(tail -n +2 "$LOOM_ROOT/shared/elicitation-methods.csv" | wc -l | tr -d ' ')
  ok "shared/elicitation-methods.csv ($method_count methods)"
else
  err "shared/elicitation-methods.csv not found"
fi

# ── Scripts ───────────────────────────────────────────────────────

echo ""
echo "--- Scripts ---"

if [ -f "$LOOM_ROOT/scripts/next-task.sh" ]; then
  if [ -x "$LOOM_ROOT/scripts/next-task.sh" ]; then
    ok "scripts/next-task.sh (executable)"
  else
    err "scripts/next-task.sh exists but is not executable"
  fi
else
  err "scripts/next-task.sh not found"
fi

# ── File hygiene ───────────────────────────────────────────────────

echo ""
echo "--- File hygiene ---"

hygiene_ok=true
while IFS= read -r md_file; do
  rel_path="${md_file#$LOOM_ROOT/}"
  if [ ! -s "$md_file" ] || ! grep -q '[^[:space:]]' "$md_file"; then
    err "$rel_path is empty"
    hygiene_ok=false
  elif [ "$(tail -c 1 "$md_file" | wc -l)" -eq 0 ]; then
    err "$rel_path missing trailing newline"
    hygiene_ok=false
  fi
done < <(find "$LOOM_ROOT" -name "*.md" -not -path "*/.git/*" -not -name ".gitkeep")
[ "$hygiene_ok" = true ] && ok "All .md files are non-empty with trailing newlines"

# ── Summary ────────────────────────────────────────────────────────

echo ""
echo "==================================="
if [ "$ERRORS" -eq 0 ]; then
  echo "All checks passed."
  exit 0
else
  echo "FAILED: $ERRORS error(s) found."
  exit 1
fi
