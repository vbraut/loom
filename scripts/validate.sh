#!/usr/bin/env bash
set -euo pipefail

# validate.sh — Structural validation for the Loom framework.
# Checks plugin manifest, skill/agent format, naming conventions, and required files.
# Exit 0 = all checks pass. Exit 1 = one or more failures.

LOOM_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ERRORS=0

# Required frontmatter fields per file type (also used as allowlist — unknown fields are rejected)
SKILL_ENTRY_FIELDS="name description user-invocable argument-hint"
SKILL_DOMAIN_FIELDS="name description"
AGENT_FIELDS="name description tools model"

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
    for required_field in $required; do
      if [ "$field_name" = "$required_field" ]; then
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

# ── Orchestrator shared modules ────────────────────────────────────

echo ""
echo "--- Orchestrator shared modules ---"

for module in config dispatch resolve transition; do
  module_path="$LOOM_ROOT/orchestrator/shared/$module.md"
  if [ -f "$module_path" ]; then
    ok "orchestrator/shared/$module.md"
  else
    err "orchestrator/shared/$module.md not found"
  fi
done

# ── Domain skills (two levels deep under skills/) ─────────────────

echo ""
echo "--- Domain skills ---"

skill_count=0
for skill_md in "$LOOM_ROOT"/skills/*/*/SKILL.md; do
  [ -f "$skill_md" ] || continue
  skill_count=$((skill_count + 1))
  rel_path="${skill_md#$LOOM_ROOT/}"

  dir_name=$(basename "$(dirname "$skill_md")")
  if ! echo "$dir_name" | grep -qE '^[a-z][a-z0-9]*(-[a-z0-9]+)*$'; then
    err "$rel_path directory name '$dir_name' is not kebab-case"
    continue
  fi

  if check_frontmatter "$skill_md" "$SKILL_DOMAIN_FIELDS" "$rel_path"; then
    fm_name=$(sed -n '2,/^---$/p' "$skill_md" | grep '^name:' | sed 's/^name: *//' | tr -d '"' | tr -d "'")
    if [ "$fm_name" != "$dir_name" ]; then
      err "$rel_path frontmatter name '$fm_name' does not match directory name '$dir_name'"
    else
      ok "$rel_path"
    fi
  fi
done
echo "  ($skill_count domain skills found)"

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

  if check_frontmatter "$agent_md" "$AGENT_FIELDS" "$rel_path"; then
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
