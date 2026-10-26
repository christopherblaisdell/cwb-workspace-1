#!/bin/bash
# Writes ZFS pool/snapshot metrics for node-exporter's textfile collector.
# Run from a TrueNAS cron job every 5 minutes.
OUT=/mnt/Picard/docker/appdata/node-exporter/textfile
mkdir -p "$OUT"; TMP="$OUT/zpool.prom.$$"
{
  echo "# HELP zpool_size_bytes Pool size in bytes."; echo "# TYPE zpool_size_bytes gauge"
  echo "# HELP zpool_alloc_bytes Pool allocated bytes."; echo "# TYPE zpool_alloc_bytes gauge"
  echo "# HELP zpool_free_bytes Pool free bytes."; echo "# TYPE zpool_free_bytes gauge"
  echo "# HELP zpool_capacity_ratio Pool allocated fraction (0-1), as zpool list CAP."; echo "# TYPE zpool_capacity_ratio gauge"
  echo "# HELP zpool_healthy 1 if pool health is ONLINE."; echo "# TYPE zpool_healthy gauge"
  zpool list -Hp -o name,size,alloc,free,cap,health | while IFS=$'\t' read n size alloc free cap health; do
    [ "$n" = freenas-boot ] && continue
    echo "zpool_size_bytes{pool=\"$n\"} $size"
    echo "zpool_alloc_bytes{pool=\"$n\"} $alloc"
    echo "zpool_free_bytes{pool=\"$n\"} $free"
    echo "zpool_capacity_ratio{pool=\"$n\"} $(awk "BEGIN{print $cap/100}")"
    echo "zpool_healthy{pool=\"$n\",health=\"$health\"} $([ "$health" = ONLINE ] && echo 1 || echo 0)"
  done
  echo "# HELP zfs_dataset_used_by_snapshots_bytes Space held only by snapshots (datasets >= 100GiB)."
  echo "# TYPE zfs_dataset_used_by_snapshots_bytes gauge"
  zfs list -Hp -o name,usedbysnapshots -t filesystem,volume | awk -F'\t' '$2 >= 107374182400 && $1 !~ /^freenas-boot/ {split($1,p,"/"); printf "zfs_dataset_used_by_snapshots_bytes{pool=\"%s\",dataset=\"%s\"} %s\n", p[1], $1, $2}'
  echo "# HELP zpool_metrics_last_run_timestamp_seconds Last successful run of zpool-metrics.sh."
  echo "# TYPE zpool_metrics_last_run_timestamp_seconds gauge"
  echo "zpool_metrics_last_run_timestamp_seconds $(date +%s)"
} > "$TMP" && mv "$TMP" "$OUT/zpool.prom"
