#!/usr/bin/env bash
# Install PII-blocking git hooks for this repository.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_DIR="$(git -C "$REPO_ROOT" rev-parse --git-path hooks)"
SRC="$REPO_ROOT/scripts/hooks/pre-push"
DEST="$HOOKS_DIR/pre-push"

chmod +x "$REPO_ROOT/scripts/check-pii.sh"
chmod +x "$SRC"

mkdir -p "$HOOKS_DIR"
cp "$SRC" "$DEST"
chmod +x "$DEST"

echo "Installed pre-push hook → $DEST"
echo "Pushes will be blocked if PII or secrets are detected."
