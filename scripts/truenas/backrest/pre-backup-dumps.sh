#!/bin/bash
# Nightly DB dumps + TrueNAS config export, picked up by the Backrest app-configs plan.
# Run from a TrueNAS cron job before the backup window.
set -u
OUT=/mnt/Picard/docker/backups/pre-backup; mkdir -p "$OUT/db" "$OUT/truenas-config"; chmod 700 "$OUT"
fail=0
for c in nextcloud-db romm-gc-db romm-new-db; do
  docker exec "$c" sh -c 'P="${MARIADB_ROOT_PASSWORD:-$MYSQL_ROOT_PASSWORD}"; D=$(command -v mariadb-dump || command -v mysqldump); "$D" -uroot -p"$P" --all-databases --single-transaction --routines --events' \
    2>/dev/null | gzip > "$OUT/db/$c.sql.gz.tmp" && [ "${PIPESTATUS[0]}" = 0 ] \
    && mv "$OUT/db/$c.sql.gz.tmp" "$OUT/db/$c.sql.gz" || { echo "dump failed: $c"; rm -f "$OUT/db/$c.sql.gz.tmp"; fail=1; }
done
docker exec immich-postgres sh -c 'pg_dumpall -U "$POSTGRES_USER" --clean --if-exists' 2>/dev/null | gzip > "$OUT/db/immich-postgres.sql.gz.tmp" \
  && [ "${PIPESTATUS[0]}" = 0 ] && mv "$OUT/db/immich-postgres.sql.gz.tmp" "$OUT/db/immich-postgres.sql.gz" \
  || { echo "dump failed: immich-postgres"; rm -f "$OUT/db/immich-postgres.sql.gz.tmp"; fail=1; }
# TrueNAS config DB + secret seed (needed to restore encrypted settings)
cp /data/freenas-v1.db "$OUT/truenas-config/freenas-v1.db" && cp /data/pwenc_secret "$OUT/truenas-config/pwenc_secret" || fail=1
date +%s > "$OUT/last-run"
exit $fail
