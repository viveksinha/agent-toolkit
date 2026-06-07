#!/usr/bin/env bash
# Pull latest agent-toolkit changes and refresh local installs.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARKETPLACE_NAME="agent-toolkit"

echo "Updating agent-toolkit"
echo "  Repo: $REPO_ROOT"
echo

if [ -d "$REPO_ROOT/.git" ]; then
  echo "Pulling latest changes..."
  git -C "$REPO_ROOT" pull --ff-only
  echo
else
  echo "Warning: not a git repository — skipping git pull." >&2
  echo
fi

echo "Refreshing Cursor symlinks..."
"$REPO_ROOT/scripts/install-cursor.sh"
echo

if command -v claude >/dev/null 2>&1; then
  echo "Refreshing Claude Code marketplace..."
  if claude plugin marketplace update "$MARKETPLACE_NAME"; then
    echo "  marketplace updated"
  else
    echo "  marketplace not registered yet — run scripts/install-claude.sh" >&2
  fi
  echo
  echo "To refresh installed plugins after a marketplace update:"
  echo "  claude plugin update --all"
else
  echo "Claude CLI not found — skipped Claude marketplace update."
  echo "Run scripts/install-claude.sh after installing Claude Code."
fi

echo
echo "Update complete."
