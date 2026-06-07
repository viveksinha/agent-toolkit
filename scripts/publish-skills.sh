#!/usr/bin/env bash
# Sync skills from ~/.cursor/skills/, refresh Cursor symlinks, commit, and push.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUSH="${PUSH:-1}"
COMMIT_MSG="${1:-Sync skills from ~/.cursor/skills}"

usage() {
  cat <<'EOF'
Usage: publish-skills.sh [commit-message]

  1. sync-from-cursor.sh --apply
  2. install-cursor.sh
  3. git add, commit, push

Environment:
  PUSH=0     Commit only; do not push
  PUSH=1     Commit and push to origin main (default)
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

echo "=== Step 1: sync ~/.cursor/skills → repo ==="
"$REPO_ROOT/scripts/sync-from-cursor.sh" --apply
echo

echo "=== Step 2: refresh Cursor symlinks ==="
"$REPO_ROOT/scripts/install-cursor.sh"
echo

echo "=== Step 3: git commit ==="
if [[ ! -d "$REPO_ROOT/.git" ]]; then
  echo "Not a git repository — skipped commit/push." >&2
  exit 0
fi

git -C "$REPO_ROOT" add -A

if git -C "$REPO_ROOT" diff --staged --quiet; then
  echo "Nothing to commit."
  exit 0
fi

git -C "$REPO_ROOT" commit -m "$COMMIT_MSG"

if [[ "$PUSH" == "1" ]]; then
  echo
  echo "=== Step 4: git push ==="
  git -C "$REPO_ROOT" push origin main
  echo "Published."
else
  echo "Committed locally (PUSH=0 — skipped push)."
fi
