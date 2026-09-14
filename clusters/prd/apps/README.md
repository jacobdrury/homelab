# Workload Applications for prd (discovered by root alongside platform/).

| App | Path |
|-----|------|
| Homepage | `homepage/` |
| Authentik | `authentik/` — SSO IdP at `auth.lab`; CNPG Postgres + Helm; **blueprints** for OIDC apps |
| Uptime Kuma | `uptime-kuma/` — `uptime.lab` via Authentik Proxy; DB on **shared MariaDB** |
| Transitional | `transitional/` — Envoy HTTPS → legacy jellyfin/*arr/HA/Pi-hole/scarif |

Each app: `application.yaml` + optional `values.yaml` / `resources.yaml` (HTTPRoutes, etc.).

**No app `install.sh`.** Argo owns workloads after platform handoff — [agents](../../../docs/architecture/agents.md#bootstrap-scripts-installsh-vs-argo).

**Authentik:** create Homelab 1Password items `prd Authentik secret key`, `prd Authentik Postgres`, and (for Argo SSO) `prd Argo CD OIDC` (password = client secret). Directory config is **blueprints** under this app (not OpenTofu). Merge Git, wait for sync. Initial admin: `https://auth.lab.jacobdrury.com/setup`. Add your user to Authentik group **Argo CD Admins** for Argo SSO.

**Uptime Kuma:** `https://uptime.lab.jacobdrury.com` is Authentik Proxy (Envoy → authentik-server → Kuma). DB on **shared MariaDB** (`mariadb.mariadb.svc`). After first setup, **Settings → Security → Disable Auth**. 1Password: `prd Uptime Kuma MariaDB` (DB), `Uptime Kuma` (admin API for OpenTofu). Monitors + Lab status page: `infrastructure/uptime-kuma/` → `moon run uptime-kuma:apply`.
