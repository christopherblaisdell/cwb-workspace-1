# Incident: TrueNAS Host Knocked Offline During VM Network Bridging

**Date:** 2026-08-16
**System:** TrueNAS SCALE host at `192.168.0.165` (Supermicro board, IPMI at `192.168.0.14`)
**Severity:** High — lost management access to the TrueNAS host (SSH/HTTPS/ICMP all down)

## Background

Goal was to get a Windows VM (VM 26) running on TrueNAS onto the same LAN
(`192.168.0.x`) as the TrueNAS host and all other devices, without dealing with
subnetting/NAT between the VM and the host.

Initial state:
- TrueNAS host interface `enp9s0f0` held IP `192.168.0.165/24`.
- VM 26 NIC was attached directly to `enp9s0f0`, type `E1000` (previously `VIRTIO`,
  changed earlier in the session because the VM had no internet with `VIRTIO`).
- Host-to-VM and VM-to-LAN connectivity still didn't work reliably attached directly
  to the physical interface.

## What Went Wrong

To make the VM behave like a normal LAN device, a Linux bridge (`br0`) was created
with `enp9s0f0` as a member, then an attempt was made to move the host's own
management IP (`192.168.0.165`) from `enp9s0f0` onto `br0`.

The bridge move did not complete cleanly:
- `br0` was created and `enp9s0f0` was enslaved to it.
- The IP move to `br0` did not fully succeed, but `enp9s0f0` was left enslaved to
  `br0` — which silently blocks the physical interface's own IP traffic.
- Result: `192.168.0.165` stopped responding to HTTPS, SSH, and ICMP. The host's
  MAC was still visible on the network, but the management plane was completely
  unreachable remotely.
- Two separate `interface.commit()` calls were involved (create bridge, then move
  IP). TrueNAS's automatic rollback-on-failed-checkin only protected the second
  call — the first one (enslaving the NIC) had already been committed and was not
  rolled back.

**Root cause:** changing the TrueNAS *host's* own management interface to solve a
problem that only required changes on the *VM* side.

## Recovery Steps Taken

1. No IPMI/console access was available from the remote session — recovery required
   physical/out-of-band access.
2. Identified the IPMI/BMC on the LAN by scanning the router's DHCP client list for
   a device with ports `80`, `443`, `623` (IPMI/RMCP), and `22` open — found at
   `192.168.0.14` (ATEN-style BMC login page).
3. Logged into the IPMI web UI using the Supermicro default credentials
   `ADMIN` / `ADMIN`.
4. Used the IPMI Remote Console (iKVM/HTML5) to get a virtual monitor/keyboard on
   the physical box.
5. From the console: ran `ip link set enp9s0f0 nomaster` to free the physical NIC
   from `br0`, then deleted `br0`.
6. Cleaned up the persisted network config via the TrueNAS API so the bad
   bridge config would not reappear on reboot.
7. Confirmed `192.168.0.165` was reachable again via ping/HTTPS/SSH.

**Outcome:** TrueNAS host fully recovered, no data loss. The original VM
networking goal was left unresolved — deferred to a VM-side-only approach instead
of touching the host's bridge/IP again.

## Recovery-Readiness Plan (for next time)

### Immediate
1. **Change the IPMI password.** `ADMIN`/`ADMIN` on a LAN-reachable BMC is a real
   security hole — anyone on the network could power-cycle the box or get a root
   console. Change it via IPMI → Configuration → Users and store it in a password
   manager.
2. **Export a TrueNAS config backup** (System Settings → General → Manage
   Configuration → Download) while the box is healthy, so a wedged config can be
   restored instead of hand-fixed.
3. **Give the IPMI a DHCP reservation** so `192.168.0.14` never changes — avoid
   having to rediscover it under pressure.

### Process changes
4. **Verify console/IPMI access before touching host networking** — as a
   precondition, not an afterthought. Don't make live changes to a host's
   management interface without confirmed out-of-band access first.
5. **Never touch the host's own management IP/interface** to solve a VM-side
   networking problem. If a VM needs to be on the LAN, solve it on the VM/bridge
   side using a bridge that never carries the host's existing IP.
6. **Stage multi-part network changes as one atomic commit**, not sequential
   `interface.commit()` calls — a failed checkin should roll back the whole
   change, not just the last step.
7. **Use a short checkin timeout with active reachability polling** during any
   interface commit, to catch a break within seconds instead of assuming success.

### Nice-to-have
8. Keep a short written runbook with: IPMI URL/credentials, the exact click path
   to the iKVM/HTML5 console, and the NIC/bridge recovery commands
   (`ip link set <nic> nomaster`, bridge delete) so recovery doesn't depend on
   rediscovering the UI each time.
9. Consider putting the IPMI on a separate management VLAN so it isn't exposed on
   the same broadcast domain as everything else (lower priority).
