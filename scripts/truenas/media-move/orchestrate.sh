#!/bin/bash
# Runs the whole Zapata/Media -> Discovery/Media move unattended.
M=/root/claude-move; ST=$M/STATUS
say() { echo "$(date '+%F %T') $*" | tee -a $ST; }
waitpass() { until grep -qE "=== $1 pass1 exit" $M/copy.log; do sleep 60; done
  rc=$(grep -oE "=== $1 pass1 exit [0-9]+" $M/copy.log | awk '{print $NF}')
  [ "$rc" = 0 ] || [ "$rc" = 24 ] || { say "ABORT: $1 first copy rsync exit $rc"; exit 1; }; }
say "orchestrator started"
for D in Adult Films; do
  waitpass $D; say "$D first copy done; cutover starting"
  if $M/cutover.sh $D; then say "$D cutover OK"; else say "ABORT: $D cutover failed (apps restored on original path)"; exit 1; fi
done
say "soaking 30 min before cleanup"; sleep 1800
fail=0
for D in Adult Films; do SRC=/mnt/Enterprise/Zapata/Media/$D; DST=/mnt/Discovery/Media/$D
  n=$(rsync -aHXn --filter="-x system.*" --itemize-changes $SRC/ $DST/ | grep -v '^\.d' | wc -l)
  [ "$n" -eq 0 ] || { say "$D: $n files on source not on destination"; fail=1; }
  for c in $(docker ps -a --format '{{.Names}}'); do
    docker inspect -f '{{range .Mounts}}{{println .Source}}{{end}}' $c | grep -qx "$SRC" && { say "$D: $c still mounts source"; fail=1; }
  done
done
for c in emby jellyfin whisparr jdownloader radarr bazarr easynews-zipmanager-bridge ix-plex-plex-1; do
  [ "$(docker inspect -f '{{.State.Status}}' $c 2>/dev/null)" = running ] || { say "$c not running"; fail=1; }
done
[ $fail -eq 0 ] || { say "ABORT before cleanup: checks failed; originals kept"; exit 1; }
say "checks passed; deleting originals"
before=$(zfs get -Hp -o value available Enterprise)
rm -rf /mnt/Enterprise/Zapata/Media/Adult /mnt/Enterprise/Zapata/Media/Films
sleep 300; after=$(zfs get -Hp -o value available Enterprise)
say "originals deleted; Enterprise avail $((before/2**30))G -> $((after/2**30))G (frees continue in background); capacity now $(zpool get -H -o value capacity Enterprise)"
say "DONE"
