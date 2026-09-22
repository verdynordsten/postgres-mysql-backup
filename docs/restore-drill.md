# Weekly restore drill

A backup you never restored is a hope, not a backup. Every Sunday:

1. Pick the latest backup: `ls -t backups/pg-*.sql.gz | head -1` (pg) or `ls -t backups/mysql-*.sql.gz | head -1` (mysql)
2. Restore into a scratch DB (never prod):
   `./scripts/pg-restore.sh backups/<file> drill_restore --yes`
3. Row-count the 3 biggest tables in both prod and drill, compare.
4. If counts match → log `docs/drill-log.md` line: date, file, OK.
5. If mismatch → treat as incident (see linux-vps-ops runbook),
   re-run backup immediately, investigate before Monday.
