#!/usr/bin/env bash

# Simple entry point for brand new users
# Just run: ./start.sh
# That's it! No arguments needed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERACTIVE_SCRIPT="$SCRIPT_DIR/scripts/interactive-select.sh"

if [ ! -x "$INTERACTIVE_SCRIPT" ]; then
  echo "Error: Interactive script not found at $INTERACTIVE_SCRIPT"
  exit 1
fi

# Show a simple intro
cat <<'EOF'
╔════════════════════════════════════════════════════╗
║                                                    ║
║    🍺 Homebrew DevOps Tools - Interactive Setup   ║
║                                                    ║
║  Pick your development environment and tools     ║
║  Everything is safe - preview before installing! ║
║                                                    ║
╚════════════════════════════════════════════════════╝

EOF

# Run interactive mode
exec "$INTERACTIVE_SCRIPT"
