#!/usr/bin/env bash
# pg-restore.sh — restore a .sql.gz backup into a target database.
# Usage: ./scripts/pg-restore.sh BACKUP_FILE TARGET_DB [--yes]
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -f .env ]] && { set -a; source .env; set +a; }

FILE="${1:-}"; TARGET="${2:-}"; FLAG="${3:-}"
[[ -f "$FILE" ]] || { echo "usage: $0 BACKUP_FILE TARGET_DB [--yes]" >&2; exit 2; }
[[ -n "$TARGET" ]] || { echo "usage: $0 BACKUP_FILE TARGET_DB [--yes]" >&2; exit 2; }
if [[ "$FLAG" != "--yes" ]]; then
  read -r -p "restore $FILE into database '$TARGET'? [y/N] " a
  [[ "$a" == "y" || "$a" == "Y" ]] || { echo "aborted"; exit 0; }
fi
export PGHOST="${PGHOST:-127.0.0.1}" PGPORT="${PGPORT:-5432}"
export PGUSER="${PGUSER:?set PGUSER}" PGPASSWORD="${PGPASSWORD:?set PGPASSWORD}"
gunzip -c "$FILE" | psql -d "$TARGET" -v ON_ERROR_STOP=1 -q
echo "restored into: $TARGET"
