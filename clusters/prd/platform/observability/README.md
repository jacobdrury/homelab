# Observability (prd)

LGTM-style stack under one domain folder; separate Argo Applications per chart.

| App | Role |
|-----|------|
| `resources/` | Namespace + CNPG `observability-pg` (Grafana Postgres) |
| `loki/` | Log store (SingleBinary / filesystem on `scarif-iscsi`) |
| `tempo/` | Trace store (monolithic / local PVC) |
| `kube-prometheus-stack/` | Prometheus, Alertmanager → Discord, Grafana (OIDC + Postgres) |
| `alloy/` | DaemonSet: pod logs → Loki, OTLP → Tempo |

UI: `https://grafana.lab.jacobdrury.com` (Authentik OIDC). Prometheus / Loki / Tempo stay in-cluster only.

**1Password (Homelab) before first sync:**

| Item | Fields | Used by |
|------|--------|---------|
| `prd Observability Postgres` | `password` (DB user is fixed `grafana`) | CNPG owner + Grafana DB |
| `prd Grafana OIDC` | `password` (client secret) | Authentik blueprint + Grafana OAuth |
| `prd Grafana admin` | `password` | Grafana break-glass admin |
| `prd Discord Lab Alerts` | `password` (webhook URL) | Alertmanager (existing Kuma item) |

After merge: create those items (except Discord), add yourself to Authentik group **Grafana Admins**, then let Argo sync. DNS: `grafana` in `infrastructure/lab.yaml` → `moon run cloudflare:apply`. Kuma: `moon run uptime-kuma:apply`.

Docs: [observability](../../../../docs/architecture/observability.md).
