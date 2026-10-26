# Incident: Enterprise Pool at 97% — Media Moved to Discovery

**Date:** 2026-10-25 → 2026-10-26
**System:** TrueNAS SCALE 24.10.2.4 (`freenas`, host `192.168.10.10`)
**Severity:** High — pool nearly full with ~120 TiB of thin-provisioned iSCSI on top

## Starting State

| Pool | Layout | Capacity |
|---|---|---|
| Enterprise | 7 × 18TB RAIDZ2 | **97%** (1.8T free) |
| Discovery | 7 × 20TB RAIDZ2 + 1 spare | 27% (62T free) |

The real risk was not the 97% figure itself: the Windows host `theblaze-aorus`
mounts seven file-backed, thin-provisioned iSCSI extents on Enterprise
(Defiant, Nagato, Potemkin, Quinn, Oberth, Relativity, Xosa) advertising about
**120 TiB** total. If the pool fills, all of them fail writes at once and the
NTFS volumes risk corruption. Disconnecting them live would be equally risky.

## What Was Done

1. Created SMB-type datasets `Discovery/Media/{Adult,Films}` (nfsv4 ACL,
   case-insensitive, 1M recordsize) with the source's ownership/mode.
2. Copied `Enterprise/Zapata/Media/{Adult,Films}` with
   `rsync -aHX --filter="-x system.*"` while all apps kept running.
3. Per folder: stopped the apps using it, final `rsync --delete`, verified
   zero diffs + identical file count + identical byte count, then repointed
   the host side of each bind mount (container paths unchanged, so no
   rescans) and restarted.
   - Adult (2,669 files, 3.31 TB): Emby, Jellyfin, Whisparr, JDownloader — ~1 min down.
   - Films (397 files, 11.27 TB): Plex (TrueNAS app storage update), Emby,
     Radarr, Bazarr, easynews-zipmanager-bridge — ~1 min down.
4. 30-minute soak, re-verified, deleted the originals.
5. **Space did not free** — the Enterprise periodic snapshot tasks
   (14 daily / 8 weekly) still referenced the media. Took
   `Enterprise/Zapata@pre-media-cleanup-20261026`, kept the pre-media Oct 14
   snapshot, and destroyed the Oct 15 – Oct 26 snapshots (reclaimed 13.5T).
6. Added SMB share `Media` → `/mnt/Discovery/Media`.

Compose file backups: `*.bak-claude-<timestamp>` next to each edited file in
`/mnt/Picard/docker/...`. Scripts and logs: `/root/claude-move/` on the NAS.

## Result

| Pool | Capacity |
|---|---|
| Enterprise | **79%** (23T free) |
| Discovery | 43% (72T free) |

## Lessons

- **Deleting files does not free space while snapshots hold them.** Check
  `zfs list -o space` (USEDSNAP) and plan snapshot cleanup as part of any
  big move.
- Thin-provisioned iSCSI is still overcommitted (~120 TiB advertised vs 23T
  free). Next steps: `Optimize-Volume -ReTrim` on each iSCSI drive on
  `theblaze-aorus`, consider moving one extent or `Yamato/Media/TV` (13T)
  to Discovery, and set pool alerts at 80%.
- The 4 unused 1TB NVMe drives could host apps/VMs as a mirrored pool.
