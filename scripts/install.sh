#!/usr/bin/env bash
# Install agent-toolkit for Cursor and optionally Claude Code.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL_CLAUDE="${INSTALL_CLAUDE:-1}"

"$REPO_ROOT/scripts/install-cursor.sh"
"$REPO_ROOT/scripts/install-git-hooks.sh"

if [ "$INSTALL_CLAUDE" = "1" ]; then
  if command -v claude >/dev/null 2>&1; then
    echo
    "$REPO_ROOT/scripts/install-claude.sh"
  else
    echo
    echo "Claude CLI not found — installed Cursor only."
    echo "To add Claude Code later: INSTALL_CLAUDE=1 ./scripts/install.sh"
    echo "Or run: ./scripts/install-claude.sh"
  fi
fi
