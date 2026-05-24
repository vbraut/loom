#!/usr/bin/env bash
set -euo pipefail

# validate.sh — Structural validation for the Loom framework.
# Checks plugin manifest, skill/agent format, naming conventions, and required files.
# Exit 0 = all checks pass. Exit 1 = one or more failures.

LOOM_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ERRORS=0

# Allowed frontmatter fields per file type
SKILL_ENTRY_FIELDS="name description user-invocable argument-hint"
SKILL_DOMAIN_FIELDS="name description"
AGENT_FIELDS="name description tools model"

err() {
  echo "FAIL: $1" >&2
  ERRORS=$((ERRORS + 1))
}

ok() {
  echo "  OK: $1"
}

# Extract YAML frontmatter (between first and second ---) and check for unknown fields.
# Usage: check_frontmatter <file> <allowed_fields_space_separated> <label>
check_frontmatter() {
  file="$1"
  allowed="$2"
  label="$3"

  if ! head -1 "$file" | grep -q '^---$'; then
    err "$label missing YAML frontmatter (must start with ---)"
    return 1
  fi

  fm=$(sed -n '2,/^---$/p' "$file" | grep -v '^---$' || true)
  fm_ok=true

  # Check required fields exist
  for field in $allowed; do
    if ! echo "$fm" | grep -q "^${field}:"; then
      err "$label missing '$field' in frontmatter"
      fm_ok=false
    fi
  done

  # Check for unknown fields
  while IFS= read -r line; do
    [ -z "$line" ] && continue
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
  if python3 -c "import json; json.load(open('$LOOM_ROOT/.claude-plugin/plugin.json'))" 2>/dev/null; then
    name=$(python3 -c "import json; print(json.load(open('$LOOM_ROOT/.claude-plugin/plugin.json')).get('name',''))")
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

  check_frontmatter "$skill_md" "$SKILL_DOMAIN_FIELDS" "$rel_path" && \
    ok "$rel_path"
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

  check_frontmatter "$agent_md" "$AGENT_FIELDS" "$rel_path" && \
    ok "$rel_path"
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

# ── Schema ─────────────────────────────────────────────────────────

echo ""
echo "--- Schema ---"

schema_path="$LOOM_ROOT/schema/sdlc.config.schema.json"
if [ -f "$schema_path" ]; then
  if python3 -c "import json; json.load(open('$schema_path'))" 2>/dev/null; then
    ok "schema/sdlc.config.schema.json (valid JSON)"
  else
    err "schema/sdlc.config.schema.json is not valid JSON"
  fi
else
  err "schema/sdlc.config.schema.json not found"
fi

# ── Backlog adapter ────────────────────────────────────────────────

echo ""
echo "--- Backlog adapter ---"

for doc in mcp dispatch; do
  doc_path="$LOOM_ROOT/backlog-adapter/$doc.md"
  if [ -f "$doc_path" ]; then
    ok "backlog-adapter/$doc.md"
  else
    err "backlog-adapter/$doc.md not found"
  fi
done

# ── File hygiene ───────────────────────────────────────────────────

echo ""
echo "--- File hygiene ---"

hygiene_ok=true
while IFS= read -r md_file; do
  rel_path="${md_file#$LOOM_ROOT/}"
  if [ ! -s "$md_file" ]; then
    err "$rel_path is empty"
    hygiene_ok=false
  elif [ "$(tail -c 1 "$md_file" | wc -l)" -eq 0 ]; then
    err "$rel_path missing trailing newline"
    hygiene_ok=false
  fi
done < <(find "$LOOM_ROOT" -name "*.md" -not -path "*/.git/*" -not -name ".gitkeep")
[ "$hygiene_ok" = true ] && ok "All .md files are non-empty with trailing newlines"

# ── Naming conventions ─────────────────────────────────────────────

echo ""
echo "--- Naming conventions ---"

bad_dirs=0
for dir in "$LOOM_ROOT"/skills/*/ "$LOOM_ROOT"/skills/*/*/ "$LOOM_ROOT"/agents/*/ "$LOOM_ROOT"/playbooks/; do
  [ -d "$dir" ] || continue
  dir_name=$(basename "$dir")
  if ! echo "$dir_name" | grep -qE '^[a-z][a-z0-9]*(-[a-z0-9]+)*$'; then
    err "Directory '$dir_name' is not kebab-case: $dir"
    bad_dirs=$((bad_dirs + 1))
  fi
done
[ "$bad_dirs" -eq 0 ] && ok "All directory names are kebab-case"

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
