#!/usr/bin/env bash
set -euo pipefail

# validate.sh — Structural validation for the Loom framework.
# Checks plugin manifest, skill/agent format, naming conventions, and required files.
# Exit 0 = all checks pass. Exit 1 = one or more failures.

LOOM_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ERRORS=0

err() {
  echo "FAIL: $1" >&2
  ERRORS=$((ERRORS + 1))
}

ok() {
  echo "  OK: $1"
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
    if head -1 "$skill_path" | grep -q '^---$'; then
      if grep -q '^name:' "$skill_path"; then
        ok "skills/$skill/SKILL.md (has frontmatter)"
      else
        err "skills/$skill/SKILL.md missing 'name' in frontmatter"
      fi
    else
      err "skills/$skill/SKILL.md missing YAML frontmatter (must start with ---)"
    fi
  else
    err "skills/$skill/SKILL.md not found"
  fi
done

# ── Orchestrator shared modules ────────────────────────────────────

echo ""
echo "--- Orchestrator shared modules ---"

for module in config dispatch initialize transition; do
  module_path="$LOOM_ROOT/orchestrator/shared/$module.md"
  if [ -f "$module_path" ]; then
    ok "orchestrator/shared/$module.md"
  else
    err "orchestrator/shared/$module.md not found"
  fi
done

# ── Surgical skills (domain skills, two levels deep) ──────────────

echo ""
echo "--- Surgical skills ---"

skill_count=0
for skill_md in "$LOOM_ROOT"/skills/*/*/SKILL.md; do
  [ -f "$skill_md" ] || continue
  skill_count=$((skill_count + 1))
  rel_path="${skill_md#$LOOM_ROOT/}"

  if ! head -1 "$skill_md" | grep -q '^---$'; then
    err "$rel_path missing YAML frontmatter"
    continue
  fi

  if ! grep -q '^name:' "$skill_md"; then
    err "$rel_path missing 'name' in frontmatter"
    continue
  fi

  if ! grep -q '^description:' "$skill_md"; then
    err "$rel_path missing 'description' in frontmatter"
    continue
  fi

  dir_name=$(basename "$(dirname "$skill_md")")
  if ! echo "$dir_name" | grep -qE '^[a-z][a-z0-9]*(-[a-z0-9]+)*$'; then
    err "$rel_path directory name '$dir_name' is not kebab-case"
    continue
  fi

  ok "$rel_path"
done
echo "  ($skill_count surgical skills found)"

# ── Agents ─────────────────────────────────────────────────────────

echo ""
echo "--- Agents ---"

agent_count=0
for agent_md in "$LOOM_ROOT"/agents/*/AGENT.md; do
  [ -f "$agent_md" ] || continue
  agent_count=$((agent_count + 1))
  rel_path="${agent_md#$LOOM_ROOT/}"

  if ! head -1 "$agent_md" | grep -q '^---$'; then
    err "$rel_path missing YAML frontmatter"
    continue
  fi

  for field in name description tools model; do
    if ! grep -q "^${field}:" "$agent_md"; then
      err "$rel_path missing '$field' in frontmatter"
    fi
  done

  dir_name=$(basename "$(dirname "$agent_md")")
  if ! echo "$dir_name" | grep -qE '^[a-z][a-z0-9]*(-[a-z0-9]+)*$'; then
    err "$rel_path directory name '$dir_name' is not kebab-case"
    continue
  fi

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

# ── Naming conventions ─────────────────────────────────────────────

echo ""
echo "--- Naming conventions ---"

bad_dirs=0
for dir in "$LOOM_ROOT"/skills/*/  "$LOOM_ROOT"/skills/*/*/ "$LOOM_ROOT"/agents/*/; do
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
