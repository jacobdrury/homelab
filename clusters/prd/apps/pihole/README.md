# Pi-hole (prd)

Stateless DNS / ad blocking. Parallel to LXC until DHCP cutover — [docs/architecture/pihole.md](../../../../docs/architecture/pihole.md).

| Resource | Role |
|----------|------|
| `Deployment/pihole` | 2 replicas, soft anti-affinity, `emptyDir` |
| `pihole-settings` | `FTLCONF_*` env |
| `pihole-policy` | Block/allow lists + domains (JSON) |
| `pihole-dnsmasq` | `*.lab` forward + local hosts |
| `pihole-sync` | Sidecar reconciles policy via v6 API |
| `Service/pihole-dns` | LoadBalancer **`192.168.5.22`** :53 TCP/UDP |
| `Service/pihole` | ClusterIP :80 → Authentik / HTTPRoute |

Edit `configmap-policy.yaml` / `configmap-dnsmasq.yaml` in Git. Settings ConfigMap changes need a Deployment rollout.
