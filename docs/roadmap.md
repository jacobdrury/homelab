# Roadmap

Phased path from [inventory](inventory.md) → target. Principles and checklists only; leans live in [decisions](decisions.md).

## Current status (2026-08-30)

| Phase | State | Notes |
|-------|--------|--------|
| **0** Docs & inventory | **Done** | |
| **1** Unraid NAS | **Done** (Aug 2025) | scarif · 24TB UD · NFS |
| **1.5** VLAN + IaC | **Done** (Aug 2026) | scarif `192.168.5.10`; DNS/UniFi/Pi-hole in Git |
| **1.5+** Remote access | **Done** (Aug 2026) | Tailscale IaC; `http://scarif.lab` works home + away |
| **2** Talos on yavin | **Next** | Blocked on Mac Mini access — boot-test USB first |
| **3–5** | Not started | |

**IaC live today:** `infrastructure/dns/`, `unifi/`, `pihole/`, **`tailscale/`** — `moon run <project>:apply` on your Mac (**manual until [Phase 2b](#phase-2b--opentofu-ci-github-actions)**). Policy: [iac](architecture/iac.md).

**DNS:** `*.lab.jacobdrury.com` in Cloudflare (`infrastructure/dns/`). LAN: Pi-hole forwards `*.lab` → Cloudflare. Away: Tailscale split DNS → Cloudflare (no per-record Tailscale changes).

**Remote access (verified):** split DNS + homelab02 subnet router (`192.168.1.0/24`, `192.168.5.0/24`) · policy/keys in `infrastructure/tailscale/`.

## What's next — Phase 2

**Gate:** physical access to **yavin** (Mac Mini). Nothing else blocks bootstrap.

| Step | Action |
|------|--------|
| **1** | Boot-test **Talos 1.12.7** metal-amd64 USB on Mac Mini (1.13+ hangs on 2018 Apple EFI) |
| **2** | Custom image: extensions `intel-ucode`, `i915`; machine config — USB 2.5G primary, onboard 1G secondary, homelab VLAN, `192.168.5.11` |
| **3** | `infrastructure/prd/` — cluster secrets, Talos configs; `talosctl bootstrap` → **`k8s.lab.jacobdrury.com`** |
| **4** | Platform: Cilium, Argo CD, NFS CSI → scarif, Envoy + cert-manager, **Tailscale operator** (take over subnet router from homelab02) |
| **5** | 1Password Connect + ESO; throwaway app; confirm GitOps + `https://*.lab` on LAN and tailnet |

Optional anytime: SSD `appdata` pool on scarif; array/parity ([Phase 1b](#phase-1b--array--parity-when-you-can)).

Tools ready: `proto install talosctl` (1.12.7) · k8s operator preauth key in tfstate → copy to 1Password — [tailscale README](../infrastructure/tailscale/README.md).

## Sequence (locked)

1. **NAS first** — Unraid on pc (white); 24TB exposed via Unassigned Devices (no new large drive)  
2. **Network + IaC** — homelab VLAN (OpenTofu) + Cloudflare DNS (OpenTofu) **before** Talos  
3. **Cluster** — **bare-metal Talos** on Mac Mini (**yavin**) → single-node `prd`  
4. **Migrate once** — apps to GitOps on `prd` (**Pi-hole last**)  
5. **Expand later** — join **hoth** + **endor** as CPs (**1→3**); free pc (black) → gaming

pc (black) **stays in lab during transition** — arr serves media from **scarif NFS** until Phase 3 k8s cutover.

```mermaid
flowchart LR
  P0[P0_Docs]
  P1[P1_Unraid_NAS]
  P15[P1.5_VLAN_and_IaC]
  P2[P2_Talos_prd]
  P3[P3_Migrate_apps]
  P4[P4_Expand_to_3CP]
  P5[P5_Hardening]
  P0 --> P1 --> P15 --> P2 --> P3 --> P4 --> P5
```

## Principles

1. **Unraid = storage only** — NFS/iSCSI to the cluster; apps land on k8s once (minimize redo)  
2. Media on **scarif NFS**; arr VM on pc (black) until `prd` cutover  
3. GitOps as soon as `prd` exists  
4. **Bare-metal Talos on yavin first** — retire Mac Mini Proxmox; expand to **3 CPs** when mini PCs arrive  
5. Single-node `prd` OK at bootstrap; steady = **3 control planes**, all schedule workloads  
6. **Expand cluster in place** (shared secrets + stable API endpoint from day one) — not a full rebuild  
7. Media stays on **scarif NFS**; cluster holds apps only  
8. **No HA** until 3 CPs; planned downtime is acceptable  
9. **Homelab VLAN + OpenTofu before Talos** — no bare-metal bootstrap on flat LAN  
10. **Pi-hole last** — stays on pc (black) through Phase 2–3 until k8s cutover  
11. Tailscale + HTTPS via `lab.jacobdrury.com` — split DNS, subnet router on **k8s operator** (homelab02 interim); LE DNS-01 on Envoy  
12. **Agent-operable** — [agents](architecture/agents.md)  
13. **OpenTofu apply manual until cluster CI** — `moon run …:apply` from Mac through Phase 1.5–2; shift to GitHub Actions + in-cluster runners in Phase 2b  

## Phase 0 — Docs & inventory

- [x] Architecture / decisions / this roadmap  
- [x] proto + moon in repo  
- [x] [Inventory](inventory.md) specs + VM/LXC map  
- [x] Evacuation checklist known (VM 101 `arr`, VM 105 HA on pc black)  

**Exit:** Plan and inventory current.

## Phase 1 — Unraid owns the HDD

Details: [storage](architecture/storage.md) · [networking](architecture/networking.md).

**Goal:** NAS up; 24TB reachable over the network. pc (black) arr mounts NFS until Phase 3.

- [x] USB boot stick; Unraid license  
- [x] Wipe / install Unraid bare metal on **pc (white)**; hostname **`scarif`** ([naming](architecture/naming.md))  
- [x] Remove GTX 780 (unused; saves idle power)  
- [x] Unraid **static IP** outside DHCP pool (`192.168.5.10` on Homelab VLAN)  
- [ ] SSD pool for `appdata` on 500 GB NVMe (optional now — **no array required**)  
- [x] Move **24TB** from pc (black) into pc (white) — **Unassigned Devices**, keep XFS, **not** in array  
- [x] NFS export UD mount (`/mnt/disks/ZXA0VZBA`)  
- [x] Smoke-test: arr VM + LAN mount; library readable  
- [ ] iSCSI target plugin + SSD/pool LUNs (can wait until cluster needs block PVCs)  

**Exit:** ~~Unraid is the NAS; 24TB exported.~~ **Done Aug 2025.** arr VM on NFS; black PC no longer holds the disk.

### Phase 1.5 — Homelab VLAN + OpenTofu (gate before Talos)

Details: [networking](architecture/networking.md) · [preflight](setup/phase-1.5-preflight.md) · [iac](architecture/iac.md). **Exit criteria for Phase 2.**

- [x] OpenTofu: **`infrastructure/dns/`** — GitHub Pages (import) + infra `*.lab` records (applied 2026-08-29)
- [x] OpenTofu: **`infrastructure/unifi/`** — **Homelab** VLAN 5 + firewall (applied 2026-08-29)
- [x] OpenTofu: **`infrastructure/pihole/`** — lists, domains, upstreams, `*.homelab.com` local DNS, `*.lab` zone forward to Cloudflare (applied 2026-08-29)
- [x] Cloudflare active; API token in 1Password
- [x] UniFi API key in 1Password
- [x] Pi-hole API app-password + `app_sudo` in 1Password / UI
- [x] Switch: assign scarif port to **Homelab** VLAN 5 (Aggregation **SFP+ 2**; applied 2026-08-30)
- [x] Migrate **scarif** to `192.168.5.10` (**eth1** 10G; bonding/bridging off); arr VM NFS fstab → `scarif.lab.jacobdrury.com` (`_netdev,nofail` — no automount with Docker)
- [x] Re-validate NFS: arr VM → scarif export over homelab VLAN; Jellyfin playback OK
- [x] OpenTofu: **`infrastructure/tailscale/`** — split DNS → Cloudflare, ACL, homelab02 routes, k8s operator preauth key (applied 2026-08-30)
- [x] homelab02 **advertise-routes**; remote `http://scarif.lab.jacobdrury.com` verified on tailnet

**Exit:** ~~Lab hosts on homelab VLAN; DNS, network, and Pi-hole policy in Git.~~ **Done Aug 2026.** scarif live on `.5.10`; `*.lab` resolves on LAN and away; interim remote access via homelab02 subnet router.

### Phase 1b — Array / parity (when you can)

Buy **data** drive(s) first; **24TB becomes parity** after library is copied off UD (assigning parity **wipes** the disk).

- [ ] Add **~12 TB** data drive (comfortable for **~8.7 TB** used today + growth; copy is **not** compressed)  
- [ ] Copy library UD → array share; validate playback  
- [ ] Remove 24TB from UD; assign as **parity** (≥ largest data disk)  
- [ ] Wait for parity sync if enabled  

### Phase 1c — Backups

- [ ] Choose approach after Unraid is stable  
- [ ] Document a restore drill  

## Phase 2 — Bare-metal Talos `prd` on **yavin** (Mac Mini)

**Prerequisite:** Phase **1.5** complete (homelab VLAN + OpenTofu DNS/UniFi/Pi-hole + scarif on VLAN 5).

**Proxmox prep (done Aug 2026):** **homelab03** removed from cluster (`pvecm delnode`); **homelab02** single-node (`pvecm expected 1`); stale `corosync.conf` nodelist trimmed. Mac Mini can be wiped without affecting black’s guests.

Wipe Proxmox → Talos bare metal. **Mac Mini has no guests** (evacuated to homelab02) — wipe does not affect Pi-hole, discord bots, arr, or HA. Bootstrap **single-node `prd`** designed to **expand to 3 CPs** later.

- [x] Proxmox: **homelab03** delnode'd; **homelab02** standalone single-node (Aug 2026)
- [ ] Boot-test Talos metal-amd64 USB on Mac Mini (before wipe)  
- [ ] Custom Talos ISO / image: extensions **`intel-ucode`**, **`i915`** (+ `realtek-firmware` optional)  
- [ ] Machine config: **USB 2.5G primary** (`enx6c1ff721c616` / RTL8156BG), **onboard 1G secondary** (`enp4s0`); pin by MAC; **homelab VLAN**  
- [ ] API endpoint: **`k8s.lab.jacobdrury.com`** (OpenTofu record → yavin)  
- [ ] Generate cluster secrets once; store in `infrastructure/prd/` for join configs  
- [ ] `talosctl bootstrap` on yavin; **`allowSchedulingOnControlPlanes: true`**  
- [ ] etcd snapshot cadence (single-node DR until expansion)  
- [ ] `infrastructure/prd` + Argo → `clusters/prd`  
- [ ] Cilium, NFS CSI (→ scarif), iSCSI CSI when needed, Envoy, cert-manager  
- [ ] **Tailscale operator** on `prd` — subnet router `192.168.5.0/24`; retire homelab02 routes when stable  
- [ ] 1Password Connect + ESO; seed once  
- [ ] LE for `*.lab.jacobdrury.com` (cert-manager + DNS-01); optional Envoy route **`scarif.lab`** → Unraid HTTP  
- [ ] Deploy a throwaway app; confirm GitOps + NFS; test **`https://`** on LAN and away via Tailscale  

**Exit:** `prd` GitOps-reachable on Tailscale + VLAN; **`https://*.lab`** works home and away; NFS CSI talks to scarif; cluster ready to accept CP joins.

### Phase 2b — OpenTofu CI (GitHub Actions)

**Prerequisite:** Phase **2** cluster + Argo + **1Password Connect / ESO** (secrets in-cluster). Until this phase completes, keep applying OpenTofu from your Mac with `moon run <project>:apply`.

**Goal:** `plan` on PRs; controlled `apply` from pipelines. Replace local `*.tfstate` with a **remote backend**.

**Repo is public** — treat self-hosted runners as **trusted compute with LAN access**. Do not run workflows that use secrets on **fork PRs**; restrict `apply` to `main` (or `workflow_dispatch` + environment approval).

```mermaid
flowchart LR
  subgraph pr [Pull request]
    PlanDNS[dns plan - github-hosted]
    PlanLAN[unifi + pihole plan - ARC]
  end
  subgraph main [main branch]
    Apply[apply - environment approval]
  end
  PlanDNS --> CF[Cloudflare API]
  PlanLAN --> UDM[UniFi LAN]
  PlanLAN --> PH[Pi-hole LAN]
  Apply --> State[(remote state)]
```

#### Bootstrap (manual, now → Phase 2b)

- [x] OpenTofu modules in Git; apply from Mac (`moon`)  
- [ ] Remote state backend (OTF Cloud or S3-compatible) + migrate state per project  
- [ ] Cluster up (Phase 2) before LAN-dependent CI  

#### In-cluster runners (ARC)

- [ ] Deploy **Actions Runner Controller** (or official scale-set chart) via Argo — `apps/system/`  
- [ ] Runner image with **OpenTofu 1.9.x** (+ `git`)  
- [ ] Runner scale set labeled **`homelab`** — ephemeral pod per job  
- [ ] **NetworkPolicy:** egress to Cloudflare API, `192.168.1.1` (UniFi), `192.168.1.11` (Pi-hole → cluster later), state backend  
- [ ] Confirm **Homelab → Drury** (or routes) so pods reach UniFi + Pi-hole on VLAN 1  

#### Secrets & workflows

- [ ] GitHub **Environments** (e.g. `homelab-production`) — required reviewers for `apply`  
- [ ] Tokens via **ESO + 1Password** (preferred) or GitHub Actions secrets — never in repo  
- [ ] Workflow: **`dns/`** — `runs-on: ubuntu-latest` (public API only)  
- [ ] Workflow: **`unifi/`**, **`pihole/`** — `runs-on: [self-hosted, homelab]`  
- [ ] PR: **plan only**; post plan summary (comment or artifact)  
- [ ] `main`: **apply** after approval (or manual `workflow_dispatch` for UniFi/Pi-hole at first)  
- [ ] **No** `pull_request` workflows with secrets from forks — `pull_request` from same repo only, or `push` to `main`  

#### Cutover

- [ ] Migrate `dns`, `unifi`, `pihole` state to remote backend  
- [ ] First pipeline apply matches Mac-applied infra (no drift)  
- [ ] Document: Mac `moon run …:apply` becomes break-glass only  

**Exit:** All three OpenTofu projects plan on PR; apply via pipeline; local state retired.

## Phase 3 — Migrate workloads (once stable)

Cut over workloads → GitOps on `prd`. All Proxmox guests now on **pc (black)**. **One landing** on k8s (not Unraid Docker first). **Pi-hole** stays on pc (black) LXC until step 5 (last).

1. *arr + qBittorrent (Mullvad peers; UI at `qbittorrent.lab.jacobdrury.com`)  
2. Jellyfin (library on **scarif NFS**; GPU/QSV **optional** — not needed for typical 720/1080 direct play)  
3. Homepage  
4. Home Assistant (downtime OK)  
5. Discord bots (optional — or leave on Proxmox until black PC retires)  
6. **Pi-hole** — final cutover from pc (black) LXC → k8s; point LAN at cluster Pi-hole  

Each: `apps/` → Argo → `*.lab.jacobdrury.com` → retire old guest.

pc (black) retained until these are validated; then idle.

**Exit:** All listed apps on `prd`; old guests retired.

## Phase 4 — Expand to 3 CPs + free pc (black)

Target: **yavin + hoth + endor**, all Talos **control planes**, all schedule pods. **Join** the existing cluster (**1→3**, not 1→2). Details: [platform](architecture/platform.md#node-layout).

- [ ] Two mini PCs on hand; homelab VLAN + static/DHCP reservations  
- [ ] Same Talos version + extensions on all nodes  
- [ ] Boot Talos on **hoth** / **endor** → apply `controlplane` join configs (shared secrets + API endpoint)  
- [ ] `allowSchedulingOnControlPlanes: true` on all three  
- [ ] Talos machine configs in `infrastructure/prd/` per node  
- [ ] API endpoint: DNS or VIP survives expansion (no kubeconfig IP churn)  
- [ ] Validate etcd health + rolling workload placement across CPs  
- [ ] Wipe pc (black) → personal gaming  

**Exit:** 3 Ready CPs; same cluster + GitOps; black out of lab.

## Phase 5 — Hardening

- [ ] Prometheus, Grafana, Uptime Kuma → Discord  
- [ ] Agent workstation Tailscale + kubecontext docs / Cursor rules  
- [ ] Agent API tokens in 1Password  
- [ ] Optional MCP  
- [ ] Renovate when ready  
- [ ] Restore / node-replace docs  
- [ ] Public HTTPS only if needed  
