# Infrastructure as code

**Principle:** manage configuration in Git and apply with automation **as much as possible, where it makes sense**. The UI and SSH are for bootstrap, break-glass, and things that have no sensible API — not the steady-state workflow.

Locked leans: [decisions](../decisions.md). Apply tooling: [local-tools](../setup/local-tools.md), [infrastructure README](../../infrastructure/README.md).

## Source of truth

| Layer | Tool | Repo path | Applies with |
|-------|------|-----------|--------------|
| Public DNS (`jacobdrury.com`, `*.lab`) | **OpenTofu** | `infrastructure/dns/` | `moon run dns:apply` |
| UniFi networks + firewall | **OpenTofu** | `infrastructure/unifi/` | `moon run unifi:apply` |
| Pi-hole policy (lists, domains, upstreams, local `*.homelab.com`, zone forward) | **OpenTofu** | `infrastructure/pihole/` | `moon run pihole:apply` |
| Talos machine / cluster config | **OpenTofu** (+ generated YAML) | `infrastructure/prd/` | TBD at Phase 2 |
| Kubernetes platform + apps | **Helm** via **Argo CD** | `apps/`, `clusters/prd/` | Git push → sync |
| Dynamic app DNS (`jellyfin.lab`, …) | **external-dns** | Helm values in `apps/system/` | Argo |
| TLS certificates | **cert-manager** | Helm | Argo |
| Runtime secrets | **1Password** + External Secrets | Not in Git | Connect / ESO |

**Do not** edit in a vendor UI what OpenTofu or Argo already owns — changes drift and get reverted on the next apply/sync.

## DNS split (example)

Avoid duplicating the same records in two IaC modules:

| Zone / names | Authoritative IaC | Pi-hole role |
|--------------|-------------------|--------------|
| `*.lab.jacobdrury.com` | `infrastructure/dns/` (Cloudflare) | Forward zone to Cloudflare (`dns_forward.tf`) |
| `*.homelab.com` (LAN legacy) | `infrastructure/pihole/local_dns.auto.tfvars` | Local A records |
| App hostnames (Phase 2+) | external-dns → Cloudflare | Resolved via forward — no Pi-hole copy |

## What stays manual (for now)

| Task | Why |
|------|-----|
| Switch port VLAN assignment | No UniFi provider coverage for port profiles yet |
| Moving a host to a new subnet (IP, fstab, cable) | Physical / OS steps outside API |
| One-time bootstrap (Talos first boot, Argo install, 1Password items) | Chicken-and-egg |
| BIOS, Proxmox VM create, disk attach | Hypervisor / hardware |
| `op signin` on the operator Mac | Session auth for secret injection |

Document one-off steps in phase checklists ([roadmap](../roadmap.md), [phase-1.5 preflight](../setup/phase-1.5-preflight.md)); promote to IaC once the API and workflow are stable.

## OpenTofu conventions

- **State:** local on the operator Mac (gitignored) until a remote backend is worth it.
- **Secrets:** `TOFU_SECRET_*` in project `moon.yml` → `op read` via `.moon/scripts/tofu/env.sh` — never commit credentials.
- **Vars:** committed `*.auto.tfvars` for non-secret desired state (Pi-hole lists, domains, etc.).
- **Plan before apply:** `moon run <project>:apply` runs plan → apply; review `.tofu.plan` when unsure.

## Kubernetes / GitOps conventions

- **Helm charts** (or Kustomize overlays) under `apps/<category>/<app>/`.
- **Argo CD** `Application` manifests under `clusters/prd/` — app-of-apps pattern.
- **No `kubectl edit`** for steady state; patch Git and let Argo reconcile.
- **Secrets:** External Secrets Operator pulling from 1Password — not SealedSecrets/plaintext in repo.

## When *not* to force IaC

- **Exploratory** changes (try in UI once, then codify or discard).
- **No provider / no API** and low churn (not worth the glue).
- **Generated or ephemeral** data (query logs, cert-manager TXT challenges, Terraform state).
- **Third-party SaaS** without a maintained provider — use a thin script or manual until volume justifies it.

## Adding a new managed surface

1. Pick the tool: OpenTofu (API-backed infra/DNS/firewall), Helm (in-cluster), or both.
2. Add `infrastructure/<name>/` or `apps/...` + moon/Argo wiring.
3. Bootstrap: import or export once if state already exists, then **Git owns it**.
4. Document in this file and [decisions](../decisions.md).
