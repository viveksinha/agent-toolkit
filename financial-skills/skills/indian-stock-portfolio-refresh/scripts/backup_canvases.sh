#!/bin/bash
# Backs up all .canvas.tsx files to a backup folder.
# Run after any canvas refresh.
#
# Required env vars:
#   CANVAS_DIR  — Cursor project canvases/ folder
#   BACKUP_DIR  — destination folder for dated backups

: "${CANVAS_DIR:?Set CANVAS_DIR to your Cursor project canvases folder}"
: "${BACKUP_DIR:?Set BACKUP_DIR to your backup folder}"

mkdir -p "$BACKUP_DIR"

DATE=$(date +%Y-%m-%d)
COUNT=0

for f in "$CANVAS_DIR"/*.canvas.tsx; do
  [ -f "$f" ] || continue
  fname=$(basename "$f")
  dest="$BACKUP_DIR/${DATE}-${fname}"
  cp "$f" "$dest"
  echo "Backed up: $fname → canvases-backup/${DATE}-${fname}"
  COUNT=$((COUNT + 1))
done

# Keep only last 7 days of backups per canvas file to avoid clutter
for f in "$CANVAS_DIR"/*.canvas.tsx; do
  [ -f "$f" ] || continue
  fname=$(basename "$f")
  ls -t "$BACKUP_DIR"/*-"$fname" 2>/dev/null | tail -n +8 | xargs rm -f
done

echo "Done. $COUNT canvases backed up to: $BACKUP_DIR"
