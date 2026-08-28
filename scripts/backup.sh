#!/bin/zsh
# Snapshots the workspace: git bundle (history) + tarball (everything, including
# gitignored PHI) + checksums. Keeps the last 20 snapshots.
set -euo pipefail

WORKSPACE="${1:-$HOME/Documents/cwb-workspace-1}"
BACKUP_DIR="$HOME/Backups/$(basename "$WORKSPACE")"
TS=$(date +%Y%m%d-%H%M%S)
NAME=$(basename "$WORKSPACE")

mkdir -p "$BACKUP_DIR"
cd "$WORKSPACE"

if [[ -n $(git status --porcelain) ]]; then
  git add -A
  git commit -q -m "Auto-snapshot ${TS}" || true
  echo "Committed pending changes."
fi

git bundle create "$BACKUP_DIR/$NAME-$TS.bundle" --all >/dev/null 2>&1
tar -czf "$BACKUP_DIR/$NAME-full-$TS.tar.gz" -C "$(dirname "$WORKSPACE")" "$NAME"
shasum -a 256 "$BACKUP_DIR/$NAME-$TS.bundle" "$BACKUP_DIR/$NAME-full-$TS.tar.gz" \
  > "$BACKUP_DIR/checksums-$TS.txt"

git bundle verify "$BACKUP_DIR/$NAME-$TS.bundle" >/dev/null 2>&1 \
  && echo "Bundle verified OK." \
  || { echo "BUNDLE VERIFICATION FAILED"; exit 1; }

# Prune to the 20 most recent snapshots.
ls -t "$BACKUP_DIR"/*.bundle 2>/dev/null | tail -n +21 | xargs -r rm --
ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | tail -n +21 | xargs -r rm --
ls -t "$BACKUP_DIR"/checksums-*.txt 2>/dev/null | tail -n +21 | xargs -r rm --

echo "Backed up to $BACKUP_DIR"
ls -lht "$BACKUP_DIR" | head -4
echo ""
echo "REMINDER: copy $BACKUP_DIR to an external drive. Same-disk backup is not backup."
