#!/usr/bin/env bash
# Register the agent-toolkit marketplace and install Claude Code plugins.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARKETPLACE_NAME="agent-toolkit"
SCOPE="${CLAUDE_SCOPE:-user}"

if ! command -v claude >/dev/null 2>&1; then
  echo "Error: claude CLI not found. Install Claude Code first:" >&2
  echo "  https://code.claude.com/docs/en/quickstart" >&2
  exit 1
fi

PLUGINS=(
  product-skills
  execution-skills
  growth-skills
  launch-skills
  content-marketing-skills
  engineering-skills
  design-skills
  sales-skills
)

if [ -n "${PLUGINS_TO_INSTALL:-}" ]; then
  # shellcheck disable=SC2206
  PLUGINS=($PLUGINS_TO_INSTALL)
fi

echo "Installing agent-toolkit for Claude Code"
echo "  Repo:        $REPO_ROOT"
echo "  Marketplace: $MARKETPLACE_NAME"
echo "  Scope:       $SCOPE"
echo

claude plugin marketplace add "$REPO_ROOT"

for plugin in "${PLUGINS[@]}"; do
  echo "  installing plugin: $plugin"
  claude plugin install "$plugin@$MARKETPLACE_NAME" --scope "$SCOPE"
done

echo
echo "Done. Installed ${#PLUGINS[@]} plugin(s) from @$MARKETPLACE_NAME."
echo "Invoke skills naturally or by name (e.g. /prioritize, /craft-spec)."
