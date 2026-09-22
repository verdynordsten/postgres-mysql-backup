# postgres-mysql-backup

Scheduled logical backups for PostgreSQL + MySQL/MariaDB with gzip,
sha256 manifests, retention rotation, and verified restore drills.
This is the backup/restore discipline from my CV, as runnable scripts.

## Quickstart (fork-friendly)

```bash
git clone https://github.com/verdynordsten/postgres-mysql-backup.git
cd postgres-mysql-backup

cp .env.example .env            # DB hosts, users, passwords
./scripts/pg-backup.sh          # backs up $PGDATABASE -> ./backups/
./scripts/mysql-backup.sh       # backs up $MYSQL_DATABASE -> ./backups/
./scripts/rotate.sh ./backups 14
bash tests/test.sh              # self-test, no live DB required
```

Restore drill (proves the backup is not decoration):

```bash
./scripts/pg-restore.sh ./backups/mydb-YYYYMMDD-HHMMSS.sql.gz mydb_restored
./scripts/mysql-restore.sh ./backups/mydb-YYYYMMDD-HHMMSS.sql.gz mydb_restored
```

## Layout

| Path | What |
|---|---|
| `scripts/pg-backup.sh` | `pg_dump` custom format + gzip + sha256 |
| `scripts/mysql-backup.sh` | `mysqldump` single-transaction + gzip + sha256 |
| `scripts/pg-restore.sh` / `mysql-restore.sh` | restore into a target DB (asks confirm) |
| `scripts/rotate.sh` | delete backups older than N days |
| `cron/crontab.example` | nightly backup + weekly restore-drill lines |
| `docs/restore-drill.md` | the drill I run weekly, step by step |
| `tests/test.sh` | manifest/rotate/restore-command tests, no live DB |

## CI

`.github/workflows/ci.yml` spins up real Postgres 16 + MySQL 8 services,
runs backup → restore → row-count comparison, then the self-test.

## Evidence (real run)

![backup-verify](docs/screenshots/shot-backup-verify.png)
![logwatch](docs/screenshots/shot-logwatch.png)

Plus live CI: every push runs real backup → restore → row-count on Postgres 16 + MySQL 8 (see Actions tab).
