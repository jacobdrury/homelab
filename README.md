# Homelab

GitOps-managed home Kubernetes lab: **Talos** nodes, **Unraid** storage, **Tailscale** access, **Argo CD** + GitHub.

## Current vs future

| | Today | Target |
|---|--------|--------|
| Compute | Proxmox on Mac Mini + Gaming PC #1 | Talos on mini PCs (interim: Talos VMs on Mac Mini) |
| Storage | 24TB in Gaming PC #1; unused 2TB | Unraid on **PC #2**: 24TB data first, **parity ≥24TB later**; 2TB ≠ parity |
| Gaming PC #1 | Lab Proxmox + media disk | **Personal gaming PC** (out of lab) |
| Gaming PC #2 | Idle | Unraid NAS; GPU available for lab if needed |
| Apps | Pi-hole, HA, Jellyfin, *arr, qBittorrent | Same workloads on k8s (HA maybe stays VM) |
| Access | TBD | Tailscale; **HTTPS** — prd `*.lab.jacobdrury.com` (no env prefix), stg `*.stg.lab.jacobdrury.com` |
| Delivery | Manual / snowflake guests | Argo CD reconciles this repo |
| Secrets | Ad hoc / in guests | **1Password** → Connect → External Secrets |
| Ingress | TBD | **Envoy Gateway** (Gateway API) |

## Docs

- [Current state](docs/current-state.md) — hardware & services inventory
- [Target architecture](docs/target-architecture.md) — platform & tooling
- [Migration roadmap](docs/migration-roadmap.md) — phased path current → target

## Status

Early planning. Repo will grow `infrastructure/`, `bootstrap/`, `apps/`, and `clusters/{stg,prd}/` as Phase 2 starts.
