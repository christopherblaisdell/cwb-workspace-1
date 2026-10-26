# TrueNAS Session Log — Remote Access, Pool Rescue, Alerts, Backups

**Dates:** 2026-10-25 → 2026-10-26
**System:** TrueNAS SCALE 24.10.2.4 (`freenas`, host `192.168.10.10`)
**Worked from:** a Claude Code cloud session (phone + web)
**Companion docs:** `2026-10-26-enterprise-pool-full.md` (the media move in detail),
`2026-08-16-truenas-network-outage.md` (earlier bridge incident)

This file records everything that was found and changed on the NAS in this
session, so nothing lives only in chat history. Scripts and configs that were
deployed are checked in under `scripts/truenas/`.

---

## 1. Remote access

- The NAS host moved from `192.168.0.165` (Aug incident) to **`192.168.10.10`**.
  `br0` is gone; VM 26 uses a `macvtap` on `enp9s0f1` (the VM-only approach the
  Aug incident recommended).
- Cloud sessions cannot reach LAN IPs (proxy denies private ranges), so access
  went through the Cloudflare tunnel: `ssh-nas.mrblaze.org` (Cloudflare Access
  protected) → OpenSSH on the NAS.
- Login: `cloudflared access login` link approved by the owner on their phone,
  then SSH as `root` with a password the owner pasted into chat.
  **That password must be rotated** (see Open items).
- Found: **`nas.mrblaze.org` exposes the TrueNAS web UI to the internet with no
  Cloudflare Access policy in front of it.**

## 2. Disk / pool inventory (actual hardware)

| Pool | Disks | Notes |
|---|---|---|
| Enterprise | 7 × 18TB Seagate IronWolf Pro (ST18000NE000), RAIDZ2 | iSCSI extents, SMB shares |
| Discovery | 7 × 20TB Seagate Exos (ST20000NM002D), RAIDZ2 + 1 × 20TB hot spare | |
| Picard | 4TB Crucial MX500 SSD | docker compose root |
| Voyager | (SSD) | app data (`/mnt/Voyager/appdata`), VM 26 disk |
| unused | 4 × 1TB Sabrent Rocket NVMe | candidate fast mirror pool for apps/VMs |

Layout advice given: ideal would be one pool of two 7-wide RAIDZ2 vdevs + hot
spare; not reachable without temporary space (~97T data > one pool). Keep two
pools balanced, alert at 80%, consider an NVMe mirror pool for apps/VMs,
optionally widen Discovery with the spare (RAIDZ expansion).

## 3. Enterprise at 97% — fixed (now 79%)

Full detail in `2026-10-26-enterprise-pool-full.md`. Summary:

- Root risk: 7 thin-provisioned **file-backed iSCSI extents** for Windows host
  `theblaze-aorus` advertise ~120 TiB on a pool with 1.8T free. A full pool
  would fail writes on all of them at once. Advised **not** to disconnect them
  live (that itself risks NTFS corruption); write rate was ~1 MB/s, so weeks
  of headroom.
- None of the iSCSI extents were empty or duplicates (each its own GPT/NTFS
  volume). `CitiesSkylines` (85G) is the only one not connected.
- Moved `Zapata/Media/Adult` (3.31 TB) then `Zapata/Media/Films` (11.27 TB) to
  `Discovery/Media/*` with an unattended on-NAS orchestrator: rsync while live,
  per-folder ~1 min app stop, final sync, byte/file-count verify, repoint bind
  mounts (container paths unchanged), restart, 30 min soak, delete originals.
- Space didn't free until the Oct 15–26 `Enterprise/Zapata` snapshots that
  held the media were destroyed (owner approved). Kept Oct 13/14 and took
  `Enterprise/Zapata@pre-media-cleanup-20261026`.
- A timed-out `zfs diff` left a temp snapshot; killing the process removed it.
- New SMB share **`Media`** → `/mnt/Discovery/Media`.

Pool state after: Enterprise 79% (23T free), Discovery 43% (72T free),
Picard 20%, Voyager 41%.

## 4. Space findings (not acted on)

- **`Discovery/Zhukov/Media`**: 17G live, **~3T held by one Oct 12 snapshot**
  (data deleted after Oct 12). Past its 14-day retention; expected to expire at
  the next 02:15 snapshot run. Last chance to recover anything from it.
- **Picard**: ~733G held by snapshots; 20% full, not urgent.
- Enterprise remaining: iSCSI ~42.7T, `Yamato/Media/TV` ~13T, `Zapata` 6.2T.
- `ix-apps/docker` has ~98G of old snapshots.

## 5. Pool alerting — added and tested

Before: Alertmanager's only receiver was a **no-op**, so no Prometheus alert
ever reached anyone. TrueNAS had raised a "pool is 85%" alert that apparently
went unnoticed.

Added (files in `scripts/truenas/observability/`):
- `zpool-metrics.sh` → `/mnt/Picard/docker/stacks/ops-observability-stack/scripts/`,
  run by **TrueNAS cron job #15** every 5 min, writing
  `/mnt/Picard/docker/appdata/node-exporter/textfile/zpool.prom`.
- node-exporter: `--collector.textfile.directory=/textfile` plus a bind mount of
  that dir (the `/host` rootfs view could not see `/mnt/Picard`).
- `zfs-alerts.yml` → `prometheus/rules/`: `ZpoolCapacityWarning` (>80%, 15m),
  `ZpoolCapacityCritical` (>90%, 5m), `ZpoolUnhealthy`, `ZfsSnapshotSpaceHigh`
  (>1 TiB held by snapshots, 1h), `ZpoolMetricsStale`.
- `alertmanager.yml`: receiver now posts to **ntfy.sh** (same topic Gatus uses)
  via `url_file: /etc/alertmanager/ntfy-url` (built from `gatus.env`, not in
  git) with `?template=alertmanager`; `send_resolved: true`.
- Compose backups: `docker-compose.yml.bak-claude-<ts>`,
  `alertmanager.yml.bak-claude-<ts>`.
- Test alert fired; Alertmanager reported 1 webhook delivery, 0 failures.
- Expected first real alert: `ZfsSnapshotSpaceHigh` on `Discovery/Zhukov/Media`.

## 6. Backups (Backrest) — added

Before: **nothing was backed up.** Kopia is running but has no repository
connected.

Added (files in `scripts/truenas/backrest/`):
- Container `backrest` (`garethgeorge/backrest:v1.14.1`), compose at
  `/mnt/Picard/docker/compose/backrest/`, UI **`http://192.168.10.10:9898`**.
- Repository `discovery`: restic repo on new dataset **`Discovery/Backrest`**
  (`Discovery/Backups` is an unmounted `mountpoint=none` placeholder, so the
  dataset was created there and renamed to the top level). Repo password in
  `/root/backrest-repo-password.txt` on the NAS (root-only).
- Prune weekly (Sun 06:00, max 10% unused); check monthly (1st, 07:00, 5% data);
  low IO/CPU priority; ntfy alert on any error (Shoutrrr hook — not yet
  exercised).
- `pre-backup-dumps.sh` (TrueNAS **cron job #16**, 03:00) dumps nextcloud-db,
  romm-gc-db, romm-new-db (MariaDB) and immich-postgres, and copies the
  TrueNAS config DB + `pwenc_secret`, to
  `/mnt/Picard/docker/backups/pre-backup` (a symlink into
  `/mnt/Discovery/Backups/Picard-docker/backups`).
- Plan **app-configs** (03:30 daily; 14d/8w/6m): `/mnt/Picard/docker`,
  `/mnt/Voyager/appdata` (the real target of the `appdata` symlink), the dumps;
  excludes rclone FUSE `mounts/` (45T virtual), sabnzbd download temp, nzbdav
  config backups, prometheus/loki/kopia/backrest data, caches, transcodes.
  First full snapshot `90d1fd4d`: 223,734 files, 52.6 GiB (repo ~31G).
- Plan **personal-files** (04:00 daily; 14d/8w/12m/3y): `Picard/documents`
  (empty), `Yamato/BackedUp` (incl. Immich library), `Zapata/Deduplicated`.
  - First run was **cancelled**: it was backing up all ~6TB of
    `Zapata/Deduplicated` without checking what it was. Owner confirmed Google
    Drive is still in use, so `FromGoogleDrive{,2,3}`, `FromCloud`,
    `DownloadsFromCloud`, `Downloads`, `Temp`, BetterJoy and installers
    (`*.dmg/*.exe/*.msi`) are now excluded — snapshots are sufficient there.
  - `FromBackedUp` (641G) is an older copy of `Yamato/BackedUp` (78 of 85
    entries match; 7 unique files total ~36MB) — **excluded**, snapshots
    cover it.
  - **Kept:** `Backups/theBlaze-Ally` (148G, device backup, likely the only
    copy), `UDX` (32G, work repos/diagrams), `Aspirion` (848M), loose files.
  - **Bug caught:** `--one-file-system` on this plan would have skipped the
    child datasets `Yamato/BackedUp/Misc` (488G) and `Yamato/BackedUp/Photos`
    (77.5G, Immich). Flag removed from personal-files (kept on app-configs,
    where it skips the rclone FUSE mounts).
  - **Bug caught:** the Backrest API "Cancel" did not stop the original 6TB
    run; it kept copying excluded folders (1.1 of 6.4 TiB). Stopped by sending
    SIGINT to the restic process; this fired the ntfy error hooks (confirming
    backup-failure alerts reach the phone).
  - First correct snapshot `1a4ba89c`: 768,502 files, **810 GiB**; verified it
    contains `Photos`, `Misc`, `Backups`, `UDX` and not the Google Drive /
    cloud folders. Manual prune (Backrest `DoRepoTask` TASK_PRUNE) dropped the
    data from the cancelled runs: repo 1.1T → **710G** for all 3 snapshots.

These backups protect against losing a pool, not the whole NAS. Off-site
(e.g. Backblaze B2) is still needed.

## 7. Container review (advice only)

Suggested adding Vaultwarden, Paperless-ngx, Czkawka, CrowdSec; consolidating
Heimdall/Homarr, Gatus/Uptime Kuma, the duplicate media/arr "streaming" stacks
and the three RomM instances; and replacing Watchtower auto-updates of
`:latest` databases with Diun notifications + pinned versions.

## 8. Session housekeeping

- The incident commit initially could not be pushed: the Claude GitHub App lacked write
  access to `christopherblaisdell/cwb-workspace-1` (403 on git and the GitHub
  API) until the owner granted access; everything has since been pushed.
- An attempt to open this session from a Mac started a **separate** Claude Code
  session (`cwb-workspace-1-cc`); its bridge status request never reached the
  cloud session. To continue the same session, open its claude.ai/code link.
- Working files on the NAS: `/root/claude-move/` (move scripts, logs, STATUS),
  `/root/claude-obs/` (alert/backup staging, size scans).

## Open items (owner)

1. **Rotate the NAS root password** (it was pasted into chat) and disable SSH
   password login for root.
2. **Put Cloudflare Access in front of `nas.mrblaze.org`.**
3. **Change the IPMI `ADMIN/ADMIN` password** (from the Aug incident; status unknown).
4. **Set a Backrest login** (Settings → Users); the UI is open on the LAN.
5. **Save the restic repo password** from `/root/backrest-repo-password.txt`
   in a password manager.
6. Choose an **off-site backup target** and store its credentials as
   environment Network secrets (not in chat).
7. Run **`Optimize-Volume -DriveLetter X -ReTrim`** for each iSCSI drive on
   `theblaze-aorus`.
8. Remove the `claude-cloud-session` SSH key from TrueNAS if it was ever added.
