#!/usr/bin/env bash
# mysql-backup.sh — mysqldump -> gzip -> sha256 manifest.
# Usage: ./scripts/mysql-backup.sh  (reads .env if present)
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -f .env ]] && { set -a; source .env; set +a; }

: "${MYSQL_DATABASE:?set MYSQL_DATABASE in env or .env}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
mkdir -p "$BACKUP_DIR"

TS="$(date +%Y%m%d-%H%M%S)"
OUT="$BACKUP_DIR/${MYSQL_DATABASE}-${TS}.sql.gz"

mysqldump -h "${MYSQL_HOST:-127.0.0.1}" -P "${MYSQL_PORT:-3306}" \
  -u "${MYSQL_USER:?set MYSQL_USER}" -p"${MYSQL_PASSWORD:?set MYSQL_PASSWORD}" \
  --single-transaction --routines --triggers "$MYSQL_DATABASE" | gzip -9 > "$OUT"
sha256sum "$OUT" > "${OUT}.sha256"
echo "backup: $OUT ($(du -h "$OUT" | cut -f1))"
