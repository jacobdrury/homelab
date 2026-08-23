# GPU (Jellyfin)

Jellyfin stays **in-cluster**. Give it a GPU via **passthrough into one Talos worker** (not the whole cluster on Unraid).

## Sources

| Source | How | Notes |
|--------|-----|--------|
| **Mac Mini iGPU** | Proxmox passthrough → Talos worker VM | **Try first** — Quick Sync, efficient |
| **PC #2 dGPU** | Unraid VM passthrough → Talos worker | If Mini isn’t enough |
| **Quadro laptop** | Same idea if docked 24/7 | NVENC; heavier NVIDIA+Talos story |

```mermaid
flowchart TB
  subgraph mini [Mac_Mini]
    iGPU[Intel_iGPU]
    W1[Talos_worker_VM]
    iGPU -->|passthrough| W1
  end

  subgraph unraid [PC2_Unraid]
    Disks[NFS]
    dGPU[dGPU]
    W2[Talos_worker_VM]
    dGPU -->|passthrough| W2
  end

  CP[Control_plane]
  W1 --> CP
  W2 --> CP
  W1 -->|NFS| Disks
  W2 -->|NFS| Disks
```

## Talos / Jellyfin bits (Intel)

- Talos extensions: `i915` (+ intel-ucode as needed)  
- Device plugin or `/dev/dri` → Jellyfin uses `/dev/dri/renderD128`  
- Full iGPU passthrough: that VM **owns** the iGPU (fine on a headless Mini)  

## Avoid

Running the **full** Talos control plane on Unraid only to expose a GPU.
