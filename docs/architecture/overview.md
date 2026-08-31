# Architecture overview

Ideal end state. Path: **Unraid first** → **VLAN + OpenTofu** → **bare-metal Talos on yavin** → **migrate apps (Pi-hole last)** → **expand to 3 CPs** + free pc (black). See [decisions](../decisions.md) · [roadmap](../roadmap.md).

## Design goals

- **Kubernetes** for app workloads (Talos Linux); single-node `prd` OK until mini PCs join
- **Steady cluster:** 3 control planes, workloads on all nodes
- **GitOps** — GitHub source of truth; Argo CD reconciles
- **Unraid** owns disks only (**NFS + iSCSI**); apps are not parked on Unraid Docker
- **Private access** — homelab VLAN + Tailscale; same **`*.lab` URLs** home and away ([networking](networking.md#same-urls-at-home-and-away)); LE HTTPS on Envoy; no public app ingress by default
- **Declarative** machines and apps (OpenTofu + Helm/Argo) — [iac](iac.md); minimize snowflakes / re-migrations
- **pc (white) = Unraid**; **pc (black) → gaming** after cutover (retained during transition)
- **Agent-operable** — Cursor/AI on the tailnet ([agents](agents.md))
- **`prd` first** — `stg` layout reserved for later

## Topology

```mermaid
flowchart TB
  subgraph access [Access]
    User[User_and_agents]
    TS[Tailscale]
  end

  subgraph lab [Homelab_VLAN]
    User --> TS
    TS --> CP[Talos_prd]
    TS --> Unraid[Unraid_NAS]
    CP --- Workers[Talos_workers]
    Workers --- Unraid
  end

  subgraph gitops [GitOps]
    GH[GitHub]
    Argo[Argo_CD]
    GH --> Argo
    Argo --> CP
  end
```

## Hardware end state

| Codename | Machine | Role |
|----------|---------|------|
| — | pc (black) | **Out of lab** — personal gaming (after Phase 3–4) |
| **scarif** | pc (white) | **Unraid** bare metal; **no dGPU**; 24TB via UD → NFS/iSCSI |
| **yavin** | Mac Mini | **Bare-metal Talos CP #1** (bootstrap single-node → expand to 3) |
| **hoth** · **endor** | Mini PCs (×2) | Bare-metal Talos **control planes** (#2 and #3) |
| — | Laptops | Precision optional; Inspiron out of lab plan |

Host naming: [naming](naming.md).

## Non-goals (for now)

- Public internet exposure of the media stack  
- Ceph/Longhorn as primary storage  
- Apps on Unraid Docker as a stepping stone to k8s  
- Dedicated worker-only nodes (all three CPs schedule pods)  
- Full Talos control plane on Unraid  
- Running `stg` until you explicitly want a second cluster  
- Dependabot version updates (Renovate later)  
- Buying a second large drive before Unraid is useful (UD path instead)  

## Related

- [Platform](platform.md) · [Storage](storage.md) · [Networking](networking.md) · [IaC](iac.md) · [GPU](gpu.md) · [Media](media.md) · [Secrets](secrets.md) · [Agents](agents.md)  
- [Roadmap](../roadmap.md) · [Inventory](../inventory.md)  
