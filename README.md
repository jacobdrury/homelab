# Homelab

GitOps-managed home Kubernetes lab: **Talos** nodes, **Unraid** storage, **Tailscale** access, **Argo CD** + GitHub.

## Current vs future

| | Today | Target |
|---|--------|--------|
| Compute | Proxmox on Mac Mini + Gaming PC #1 | Talos on mini PCs (interim: Talos VMs on Mac Mini) |
| Storage | 24TB in Gaming PC #1 | Unraid on **PC #2**: 24TB data + SSD appdata; **parity ≥24TB later** |
| Gaming PC #1 | Lab Proxmox + media disk | **Personal gaming PC** (out of lab) |
| Gaming PC #2 | Idle | Unraid NAS; GPU available for lab if needed |
| Apps | Pi-hole, HA, Jellyfin, *arr, qBittorrent | Same on k8s + **Homepage**; HA after media stack |
| Access | UniFi + Tailscale TBD | Homelab **VLAN**; Tailscale; HTTPS `*.lab`; **AI agents on the tailnet** |
| Delivery | Manual / snowflake guests | Argo CD reconciles this repo |
| Secrets | Ad hoc / in guests | **1Password** → Connect → External Secrets |
| Ingress | TBD | **Envoy Gateway** (Gateway API) |

## Docs

- [Current state](docs/current-state.md) — hardware & services inventory
- [Target architecture](docs/target-architecture.md) — platform & tooling
- [Migration roadmap](docs/migration-roadmap.md) — phased path current → target

## Tooling (moon + proto)

This repo uses [moonrepo](https://moonrepo.dev/) — **proto** for pinned CLIs, **moon** for tasks.

```bash
# once per machine
bash <(curl -fsSL https://moonrepo.dev/install/proto.sh)
export PATH="$HOME/.proto/bin:$PATH"   # add to your shell profile

# in this repo
proto install          # or: moon run root:tools-install
moon run root:check
```

Pinned tools live in [`.prototools`](.prototools) (moon, OpenTofu, kubectl, helm). More tasks will land as `infrastructure/dns` and clusters appear.

**Dependency updates (planned):** [Renovate](https://moonrepo.dev/docs/guides/renovate) later — covers `.prototools`, GitHub Actions, and OpenTofu when present. No Dependabot version updates; optional GitHub security alerts only.

## Status

Early planning. Repo will grow `infrastructure/`, `bootstrap/`, `apps/`, `clusters/{stg,prd}/`, and moon tasks as Phase 2 starts.
