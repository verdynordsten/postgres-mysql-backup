#!/usr/bin/env bash
# pg-backup.sh — pg_dump -> gzip -> sha256 manifest.
# Usage: ./scripts/pg-backup.sh  (reads .env if present)
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -f .env ]] && { set -a; source .env; set +a; }

: "${PGDATABASE:?set PGDATABASE in env or .env}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
mkdir -p "$BACKUP_DIR"

TS="$(date +%Y%m%d-%H%M%S)"
OUT="$BACKUP_DIR/${PGDATABASE}-${TS}.sql.gz"

export PGHOST="${PGHOST:-127.0.0.1}" PGPORT="${PGPORT:-5432}"
export PGUSER="${PGUSER:?set PGUSER}" PGPASSWORD="${PGPASSWORD:?set PGPASSWORD}"

pg_dump --format=plain --no-owner "$PGDATABASE" | gzip -9 > "$OUT"
sha256sum "$OUT" > "${OUT}.sha256"
echo "backup: $OUT ($(du -h "$OUT" | cut -f1))"
