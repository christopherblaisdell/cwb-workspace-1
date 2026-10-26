#!/bin/bash
# usage: cutover.sh <Adult|Films>
set -u
D=$1; SRC=/mnt/Enterprise/Zapata/Media/$D; DST=/mnt/Discovery/Media/$D
TS=$(date +%Y%m%d-%H%M%S); LOG=/root/claude-move/cutover-$D-$TS.log
exec > >(tee -a $LOG) 2>&1
# project|workdir|composefile|services
if [ "$D" = Adult ]; then
  STACKS=("docker|/mnt/Picard/docker|media-services-docker-compose.yml|emby jellyfin"
          "arr-usenet|/mnt/Picard/docker/compose/arr-usenet|docker-compose.yml|whisparr"
          "jdownloader|/mnt/Picard/docker/stacks/jdownloader|docker-compose.yml|jdownloader")
else
  STACKS=("docker|/mnt/Picard/docker|media-services-docker-compose.yml|emby"
          "arr-usenet|/mnt/Picard/docker/compose/arr-usenet|docker-compose.yml|radarr"
          "bazarr|/mnt/Picard/docker/compose/bazarr|docker-compose.yml|bazarr"
          "compose|/mnt/Picard/docker/compose|easynews-zipmanager-bridge-compose.yml|easynews-zipmanager-bridge")
fi
CTRS=""; for s in "${STACKS[@]}"; do IFS='|' read p w f svcs <<<"$s"; CTRS="$CTRS $svcs"; cp -p "$w/$f" "$w/$f.bak-claude-$TS"; done
echo "== $(date) backups done; stopping:$CTRS"
[ "$D" = Films ] && midclt call -job app.stop plex >/dev/null && echo "plex stopped"
docker stop $CTRS
echo "== $(date) final sync"
rsync -aHX --delete --filter="-x system.*" --stats $SRC/ $DST/ | grep -E "Number of|Total transferred|deleted"
rc=${PIPESTATUS[0]}
CHK=$(rsync -aHXn --delete --filter="-x system.*" --itemize-changes $SRC/ $DST/ | grep -v '^\.d' | wc -l)
NS=$(find $SRC -type f | wc -l); ND=$(find $DST -type f | wc -l)
BS=$(du -sb --apparent-size $SRC | cut -f1); BD=$(du -sb --apparent-size $DST | cut -f1)
echo "rsync rc=$rc pending-diffs=$CHK files src=$NS dst=$ND bytes src=$BS dst=$BD"
if [ $rc -ne 0 ] || [ $CHK -ne 0 ] || [ $NS -ne $ND ] || [ $BS -ne $BD ]; then
  echo "!! VERIFY FAILED - restarting apps on ORIGINAL paths"; docker start $CTRS
  [ "$D" = Films ] && midclt call -job app.start plex >/dev/null; exit 1
fi
echo "== $(date) repointing apps"
for s in "${STACKS[@]}"; do IFS='|' read p w f svcs <<<"$s"
  sed -i "s#$SRC:#$DST:#g" "$w/$f"
  (cd "$w" && docker compose -p "$p" -f "$f" up -d --no-deps $svcs) || echo "!! compose up failed for $p"
done
if [ "$D" = Films ]; then
  midclt call app.config plex | python3 -c "
import json,sys; c=json.load(sys.stdin)
for m in c['storage']['additional_storage']:
  if m.get('host_path_config',{}).get('path')=='$SRC': m['host_path_config']['path']='$DST'
print(json.dumps({'values':{'storage':c['storage']}}))" > /root/claude-move/plex-update.json
  midclt call -job app.update plex "$(cat /root/claude-move/plex-update.json)" >/dev/null && echo "plex updated"
  midclt call -job app.start plex >/dev/null 2>&1; CTRS="$CTRS ix-plex-plex-1"
fi
sleep 15
echo "== $(date) verification"
for c in $CTRS; do
  st=$(docker inspect -f '{{.State.Status}}' $c 2>/dev/null)
  mnt=$(docker inspect -f '{{range .Mounts}}{{if or (eq .Source "'$SRC'") (eq .Source "'$DST'")}}{{.Source}}=>{{.Destination}}{{end}}{{end}}' $c)
  dest=${mnt#*=>}; cnt=$(docker exec $c sh -c "ls '$dest' 2>/dev/null | wc -l" 2>/dev/null)
  echo "$c status=$st mount=$mnt entries=$cnt"
done
echo "== done"
