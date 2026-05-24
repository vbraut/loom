#!/usr/bin/env bash
set -euo pipefail

LOOM_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GIT_DIR="$(cd "$LOOM_ROOT" && git rev-parse --git-dir)"
HOOK="$GIT_DIR/hooks/pre-commit"

mkdir -p "$GIT_DIR/hooks"

cat > "$HOOK" << 'HOOK_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
exec bash "$(git rev-parse --show-toplevel)/scripts/validate.sh"
HOOK_SCRIPT

chmod +x "$HOOK"
echo "Pre-commit hook installed."
