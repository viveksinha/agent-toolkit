#!/usr/bin/env bash
# Symlink agent-toolkit plugins, standalone skills, and rules into Cursor config directories.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="${MANIFEST:-$REPO_ROOT/scripts/skills-manifest.conf}"
CURSOR_SKILLS="${CURSOR_SKILLS:-$HOME/.cursor/skills}"
CURSOR_RULES="${CURSOR_RULES:-$HOME/.cursor/rules}"

mkdir -p "$CURSOR_SKILLS" "$CURSOR_RULES"

link_path() {
  local target="$1"
  local link_name="$2"

  if [[ -e "$link_name" && ! -L "$link_name" ]]; then
    rm -rf "$link_name"
  fi
  ln -sfn "$target" "$link_name"
}

echo "Installing agent-toolkit for Cursor"
echo "  Repo:   $REPO_ROOT"
echo "  Skills: $CURSOR_SKILLS"
echo "  Rules:  $CURSOR_RULES"
echo

linked_plugins=0
for plugin in "$REPO_ROOT"/*-skills; do
  [ -d "$plugin" ] || continue
  name="$(basename "$plugin")"
  link_path "$plugin" "$CURSOR_SKILLS/$name"
  echo "  linked plugin: $name"
  linked_plugins=$((linked_plugins + 1))
done

linked_standalone=0
if [[ -f "$MANIFEST" ]]; then
  while IFS=$' \t' read -r name path _rest; do
    [[ -z "${name:-}" || "$name" == \#* ]] && continue
    [[ -z "${path:-}" ]] && continue
    target="$REPO_ROOT/$path"
    [[ -d "$target" ]] || continue
    link_path "$target" "$CURSOR_SKILLS/$name"
    echo "  linked skill: $name → $path"
    linked_standalone=$((linked_standalone + 1))
  done < "$MANIFEST"
else
  echo "  (no manifest — skipped standalone skill links)"
fi

linked_rules=0
for rule in "$REPO_ROOT"/rules/*.mdc; do
  [ -f "$rule" ] || continue
  name="$(basename "$rule")"
  link_path "$rule" "$CURSOR_RULES/$name"
  echo "  linked rule: $name"
  linked_rules=$((linked_rules + 1))
done

echo
echo "Done. Linked $linked_plugins plugin(s), $linked_standalone standalone skill(s), and $linked_rules rule(s)."
echo "Restart Cursor or start a new agent session to pick up changes."
