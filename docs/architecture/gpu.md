# GPU (Jellyfin)

Jellyfin stays **in-cluster**. **GPU is optional** — typical 720/1080 anime direct play needs no hardware encode. Add a GPU later only if clients start forcing transcodes.

If needed: pass a GPU into **one Talos worker** (not the whole cluster on Unraid).

## Sources (when you care)

| Source | How | Notes |
|--------|-----|--------|
| **Mac Mini iGPU** | Talos CP **yavin** with `i915` extension | Quick Sync (QSV); only if transcodes appear |
| **pc (white) dGPU** | — | GTX 780 **removed** (Unraid headless; saved idle power) |
| **Quadro laptop** | Docked 24/7 | NVENC; only if Mini isn’t enough |

```mermaid
flowchart TB
  subgraph yavin [yavin_Mac_Mini]
    iGPU[Intel_iGPU]
    CP[Talos_CP]
    iGPU --> CP
  end

  scarif[scarif_NFS]
  CP -->|NFS| scarif
```

## Talos / Jellyfin bits (Intel)

- Talos extensions: `i915` + `intel-ucode` on **yavin**  
- Device plugin or `/dev/dri` → Jellyfin uses `/dev/dri/renderD128`  
- iGPU on the CP node is fine with **`allowSchedulingOnControlPlanes: true`**

## Avoid

Running the **full** Talos control plane on Unraid only to expose a GPU.
