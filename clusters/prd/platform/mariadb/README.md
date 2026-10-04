# Shared MariaDB

Official **`docker.io/library/mariadb`** (tag + digest). Not Bitnami.

| Piece | Choice |
|-------|--------|
| Image | `mariadb:13.0.2@sha256:…` — keep Job pin in `resources.yaml` in sync |
| Storage | Existing PVC `data-mariadb-0` (`scarif-iscsi`); Bitnami datadir at `subPath: data` → `/var/lib/mysql` |
| Secrets | ExternalSecret → Homelab **`prd MariaDB`** (`mariadb-root-password`, `mariadb-password`) |
| Consumers | Uptime Kuma (`mariadb.mariadb.svc.cluster.local`) |

`values.yaml` (Bitnami Helm) was removed with the chart.