#!/usr/bin/env bash
# rotate.sh — delete backups older than N days (both .gz and .sha256).
# Usage: ./scripts/rotate.sh [BACKUP_DIR=./backups] [RETENTION_DAYS=14] [--dry-run]
set -euo pipefail
DIR="${1:-./backups}"; KEEP="${2:-14}"; DRY="${3:-}"
[[ -d "$DIR" ]] || { echo "nothing to rotate: $DIR missing"; exit 0; }
if [[ "$DRY" == "--dry-run" ]]; then
  find "$DIR" -maxdepth 1 -name '*.sql.gz*' -mtime "+$KEEP" -print
else
  find "$DIR" -maxdepth 1 -name '*.sql.gz' -mtime "+$KEEP" -print -delete
  find "$DIR" -maxdepth 1 -name '*.sql.gz.sha256' -mtime "+$KEEP" -delete 2>/dev/null || true
fi
