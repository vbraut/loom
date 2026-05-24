#!/usr/bin/env bash
set -euo pipefail

LOOM_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$LOOM_ROOT/.git/hooks/pre-commit"

cat > "$HOOK" << 'HOOK_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
exec bash "$(git rev-parse --show-toplevel)/scripts/validate.sh"
HOOK_SCRIPT

chmod +x "$HOOK"
echo "Pre-commit hook installed."
