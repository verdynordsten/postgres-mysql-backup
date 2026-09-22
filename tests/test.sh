#!/usr/bin/env bash
# Self-test: no live DB required. Mocks pg_dump/mysqldump/psql/mysql.
set -euo pipefail
cd "$(dirname "$0")/.."
pass=0; fail=0
ok() { pass=$((pass+1)); echo "  ok: $1"; }
bad() { fail=$((fail+1)); echo "  FAIL: $1"; }

echo "[1] bash syntax"
for f in scripts/*.sh tests/test.sh; do bash -n "$f" && ok "syntax $f" || bad "syntax $f"; done

echo "[2] .env.example complete, no real secrets"
for v in PGHOST PGUSER PGPASSWORD PGDATABASE MYSQL_HOST MYSQL_USER MYSQL_PASSWORD MYSQL_DATABASE BACKUP_DIR RETENTION_DAYS; do
  grep -q "$v" .env.example && ok "env $v" || bad "env $v"
done
grep -qiE "ghp_|sk-|ya29" .env.example && bad "secret leak" || ok "no secret leak"

echo "[3] backup scripts with mocked binaries"
MOCK=/tmp/bak-mock && rm -rf $MOCK ./backups && mkdir -p $MOCK
printf '#!/usr/bin/env bash\necho "-- mock pg dump"\n' > $MOCK/pg_dump && chmod +x $MOCK/pg_dump
printf '#!/usr/bin/env bash\necho "-- mock mysql dump"\n' > $MOCK/mysqldump && chmod +x $MOCK/mysqldump
export PATH="$MOCK:$PATH"
export PGDATABASE=t1 PGUSER=u PGPASSWORD=p MYSQL_DATABASE=t2 MYSQL_USER=u MYSQL_PASSWORD=p BACKUP_DIR=./backups
./scripts/pg-backup.sh >/dev/null && ok "pg-backup runs" || bad "pg-backup runs"
./scripts/mysql-backup.sh >/dev/null && ok "mysql-backup runs" || bad "mysql-backup runs"
ls backups/pg-t1-*.sql.gz backups/mysql-t2-*.sql.gz >/dev/null 2>&1 && ok "both backups created" || bad "backups created"
f=$(ls backups/pg-t1-*.sql.gz | head -1)
sha256sum -c "${f}.sha256" >/dev/null 2>&1 && ok "sha256 verifies" || bad "sha256"
zcat "$f" | grep -q "mock pg dump" && ok "backup content real" || bad "backup content"

echo "[4] restore commands route to right binary"
printf '#!/usr/bin/env bash\necho "PSQL_CALLED db=$2"\n' > $MOCK/psql && chmod +x $MOCK/psql
printf '#!/usr/bin/env bash\necho "MYSQL_CALLED db=${@: -1}"\n' > $MOCK/mysql && chmod +x $MOCK/mysql
out="$(./scripts/pg-restore.sh "$f" drill --yes 2>&1 || true)"
if grep -q "PSQL_CALLED" <<<"$out"; then ok "pg-restore calls psql"; else bad "pg-restore"; fi
out="$(./scripts/mysql-restore.sh "$f" drill --yes 2>&1 || true)"
if grep -q "MYSQL_CALLED" <<<"$out"; then ok "mysql-restore calls mysql"; else bad "mysql-restore"; fi
printf 'n\n' | ./scripts/pg-restore.sh "$f" drill 2>&1 | grep -q "aborted" && ok "restore asks confirm" || bad "confirm"

echo "[5] rotation"
touch -d '30 days ago' backups/old-20000101-000000.sql.gz
./scripts/rotate.sh ./backups 14 >/dev/null
[[ ! -f backups/old-20000101-000000.sql.gz ]] && ok "old deleted" || bad "old deleted"
[[ -f "$f" ]] && ok "fresh kept" || bad "fresh kept"
./scripts/rotate.sh ./backups 14 --dry-run >/dev/null && ok "dry-run works" || bad "dry-run"
rm -rf ./backups $MOCK

echo
echo "pass=$pass fail=$fail"
[[ $fail -eq 0 ]]
