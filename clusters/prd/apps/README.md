# Workload Applications for prd (discovered by root alongside platform/).

| App | Path |
|-----|------|
| Homepage | `homepage/` |
| Authentik | `authentik/` — SSO IdP at `auth.lab`; CNPG Postgres + Helm |
| Transitional | `transitional/` — Envoy HTTPS → legacy jellyfin/*arr/HA/Pi-hole/scarif |

Each app: `application.yaml` + optional `values.yaml` / `resources.yaml` (HTTPRoutes, etc.).

**No app `install.sh`.** Argo owns workloads after platform handoff — [agents](../../../docs/architecture/agents.md#bootstrap-scripts-installsh-vs-argo).

**Authentik:** create Homelab 1Password items `prd Authentik secret key` + `prd Authentik Postgres`, merge Git, wait for sync. Initial admin: `https://auth.lab.jacobdrury.com/setup`.
