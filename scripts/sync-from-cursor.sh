#!/usr/bin/env bash
# Copy standalone skills from ~/.cursor/skills/ into this repo (repo ← home).
# Plugin folders (*-skills) are not synced here — edit those in the repo directly.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="${MANIFEST:-$REPO_ROOT/scripts/skills-manifest.conf}"
CURSOR_SKILLS="${CURSOR_SKILLS:-$HOME/.cursor/skills}"

APPLY=0

usage() {
  cat <<'EOF'
Usage: sync-from-cursor.sh [--dry-run|--apply]

  --dry-run   Show what would sync (default)
  --apply     Copy changed files into the repo

Reads scripts/skills-manifest.conf for skill name → repo path mappings.
After --apply, run ./scripts/install-cursor.sh to refresh symlinks.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ ! -f "$MANIFEST" ]]; then
  echo "Manifest not found: $MANIFEST" >&2
  exit 1
fi

RSYNC_FLAGS=(-a --exclude='.DS_Store' --exclude='.trendlyne_cookie' --exclude='*.cookie')
if [[ "$APPLY" -eq 0 ]]; then
  RSYNC_FLAGS+=(--dry-run)
fi

manifest_has() {
  local name="$1"
  grep -q "^${name}[[:space:]]" "$MANIFEST" 2>/dev/null
}

echo "Sync from Cursor → repo"
echo "  Home:     $CURSOR_SKILLS"
echo "  Repo:     $REPO_ROOT"
echo "  Manifest: $MANIFEST"
echo "  Mode:     $([[ "$APPLY" -eq 1 ]] && echo apply || echo dry-run)"
echo

synced=0
skipped=0

while IFS=$' \t' read -r name path _rest; do
  [[ -z "${name:-}" || "$name" == \#* ]] && continue
  [[ -z "${path:-}" ]] && continue

  src="$CURSOR_SKILLS/$name"
  dest="$REPO_ROOT/$path"

  if [[ ! -e "$src" ]]; then
    echo "  skip (missing in ~/.cursor): $name"
    skipped=$((skipped + 1))
    continue
  fi

  if [[ -L "$src" ]]; then
    echo "  skip (symlink): $name → $(readlink "$src")"
    skipped=$((skipped + 1))
    continue
  fi

  if [[ ! -f "$src/SKILL.md" ]]; then
    echo "  skip (no SKILL.md): $name"
    skipped=$((skipped + 1))
    continue
  fi

  mkdir -p "$dest"
  echo "  sync: $name → $path"
  rsync "${RSYNC_FLAGS[@]}" "$src/" "$dest/"
  synced=$((synced + 1))
done < "$MANIFEST"

echo
echo "Unmapped top-level skills in $CURSOR_SKILLS (add to skills-manifest.conf):"
unmapped=0
for entry in "$CURSOR_SKILLS"/*/; do
  [[ -d "$entry" ]] || continue
  name="$(basename "$entry")"
  [[ "$name" == *-skills ]] && continue
  [[ -L "$entry" ]] && continue
  [[ -f "$entry/SKILL.md" ]] || continue
  if manifest_has "$name"; then
    continue
  fi
  echo "  ? $name"
  unmapped=$((unmapped + 1))
done
if [[ "$unmapped" -eq 0 ]]; then
  echo "  (none)"
fi

echo
echo "Done. Synced $synced skill(s), skipped $skipped."
if [[ "$APPLY" -eq 1 ]]; then
  echo "Run ./scripts/install-cursor.sh to refresh ~/.cursor symlinks."
else
  echo "Re-run with --apply to copy changes into the repo."
fi
