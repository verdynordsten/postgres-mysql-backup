#!/usr/bin/env bash
# mysql-restore.sh — restore a .sql.gz backup into a target database.
# Usage: ./scripts/mysql-restore.sh BACKUP_FILE TARGET_DB [--yes]
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
gunzip -c "$FILE" | mysql -h "${MYSQL_HOST:-127.0.0.1}" -P "${MYSQL_PORT:-3306}" \
  -u "${MYSQL_USER:?set MYSQL_USER}" -p"${MYSQL_PASSWORD:?set MYSQL_PASSWORD}" "$TARGET"
echo "restored into: $TARGET"
