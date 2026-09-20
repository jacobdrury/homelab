# Infrastructure as code

**Principle:** manage configuration in Git and apply with automation **as much as possible, where it makes sense**. The UI and SSH are for bootstrap, break-glass, and things that have no sensible API — not the steady-state workflow.

**GitOps first:** if Argo (or another in-cluster reconciler) can own it, prefer that over OpenTofu. OpenTofu is for **external** APIs with no GitOps-native path. Authentik apps/providers use **blueprints** in Git (mounted by the Helm chart), not `infrastructure/authentik/`. Agent rule: [agents](agents.md#gitops-first-opentofu-when-needed).

Locked leans: [decisions](../decisions.md). Apply tooling: [local-tools](../setup/local-tools.md), [infrastructure README](../../infrastructure/README.md).

## Source of truth

| Layer | Tool | Repo path | Applies with |
|-------|------|-----------|--------------|
| Public DNS (`jacobdrury.com`, `*.lab`) + R2 tofu state bucket | **OpenTofu** | `infrastructure/cloudflare/` | `moon run cloudflare:apply` |
| UniFi networks + firewall + selected switch ports | **OpenTofu** | `infrastructure/unifi/` | `moon run unifi:apply` |
| Pi-hole policy (lists, domains, upstreams, local DNS, zone forward) | **ConfigMaps** + sync sidecar | `clusters/prd/apps/pihole/` | Git push → Argo |
| Tailscale (policy, DNS, routes, keys, device settings) | **OpenTofu** | `infrastructure/tailscale/` | `moon run tailscale:apply` |
| Uptime Kuma monitors + Lab status page | **OpenTofu** | `infrastructure/uptime-kuma/` | `moon run uptime-kuma:apply` (port-forward; see README) |
| Talos machine / cluster config | **OpenTofu** (+ generated YAML) | `infrastructure/talos/prd/` | TBD at Phase 2 |
| Kubernetes platform + apps | **Helm** via **Argo CD** | `apps/`, `clusters/prd/` | Git push → sync |
| Authentik directory (OIDC apps, groups, …) | **Blueprints** via Authentik Helm | `clusters/prd/apps/authentik/` | Argo → worker applies |
| Dynamic app DNS (`jellyfin.lab`, …) | **external-dns** | Helm values in `clusters/prd/platform/` | Argo |
| TLS certificates | **cert-manager** | Helm | Argo |
| Runtime secrets | **1Password** + External Secrets | Not in Git | Connect / ESO |

**Do not** edit in a vendor UI what OpenTofu or Argo already owns — changes drift and get reverted on the next apply/sync.

## DNS split (example)

Avoid duplicating the same records in two IaC modules:

| Zone / names | Authoritative IaC | Pi-hole role |
|--------------|-------------------|--------------|
| `*.lab.jacobdrury.com` | `infrastructure/cloudflare/` (Cloudflare) | Forward zone to Cloudflare (ConfigMap dnsmasq) |
| `*.homelab.com` (LAN legacy, **retiring**) | `clusters/prd/apps/pihole/configmap-dnsmasq.yaml` | Local host-records |
| App hostnames (Phase 2+) | external-dns → Cloudflare | Resolved via forward (LAN) or Tailscale split DNS → Cloudflare (away) |

## What stays manual (for now)

| Task | Why |
|------|-----|
| Switch ports not yet in `unifi/devices.tf` | Provider replaces the whole `port_overrides` array per device — only manage switches we’ve declared completely |
| Moving a host to a new subnet (IP, fstab, cable) | Physical / OS steps outside API |
| One-time bootstrap (Talos first boot, Argo install, 1Password items) | Chicken-and-egg |
| BIOS, Proxmox VM create, disk attach | Hypervisor / hardware |
| `op signin` on the operator Mac | Session auth for secret injection — until Phase 2b CI |
| Tailscale **advertise-routes** on subnet router host | Device-local (`tailscale set` on homelab02; k8s operator Helm in Phase 2) — API only **enables** advertised routes |
| OpenTofu `plan` / `apply` | Prefer CI (`moon ci`); Mac `moon run …:apply` is break-glass — [opentofu-ci](../setup/opentofu-ci.md) |

Document one-off steps in phase checklists ([roadmap](../roadmap.md), [phase-1.5 preflight](../setup/phase-1.5-preflight.md)); promote to IaC once the API and workflow are stable.

## OpenTofu conventions

- **State:** Cloudflare R2 bucket `homelab-tofu-state` (`backend "s3"` + `use_lockfile`); AWS keys from 1Password via `moon.yml`. Local `*.tfstate` is legacy/gitignored.
- **Apply:** GitHub Actions `moon ci :apply` on `main`; Mac `moon run <project>:apply` is break-glass. See [opentofu-ci](../setup/opentofu-ci.md).
- **Secrets:** `TOFU_SECRET_*` in project `moon.yml` → `op read` via `.moon/scripts/tofu/env.sh` (skipped when the target env var is already set — CI path).
- **Vars:** committed `*.auto.tfvars` for project-specific state; **shared lab constants** in [`infrastructure/lab.yaml`](../../infrastructure/lab.yaml). New OpenTofu projects under `infrastructure/` get `lab_locals.tf` on `moon run <project>:init`.
- **Plan before apply:** `moon run <project>:apply` runs plan → apply; review `.tofu.plan` when unsure.

## CI (Phase 2b)

Thin GitHub Actions + **`moon ci`**. State on R2. LAN reachability via **Tailscale GitHub Action** (`tag:ci` + Homelab Connector) — **not** ARC. Setup: [opentofu-ci](../setup/opentofu-ci.md).

| Project | Runner | Path to API |
|---------|--------|-------------|
| `cloudflare`, `tailscale` | `ubuntu-latest` | Public APIs |
| `unifi`, `uptime-kuma` | `ubuntu-latest` + Tailscale | Homelab `192.168.5.0/24` (UniFi at `.1`, kube at `.11`) |

**Security (public repo):**

- Only one GitHub secret: `OP_SERVICE_ACCOUNT_TOKEN` (loads everything else from 1Password).
- **Plan on PR** from this repo only; **never** pass secrets to **fork PRs**.
- **`apply`** on push to `main` (solo lab — no environment approval gate).

Full checklist: [roadmap Phase 2b](../roadmap.md#phase-2b--opentofu-ci-github-actions).

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

1. Prefer GitOps (Helm/manifests/blueprints). Use OpenTofu only if there is no in-cluster reconciler.
2. Add `clusters/prd/...` + Argo, or `infrastructure/<name>/` + moon when OpenTofu is required.
3. Bootstrap: import or export once if state already exists, then **Git owns it**.
4. Document in this file and [decisions](../decisions.md).
