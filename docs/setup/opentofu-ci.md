# OpenTofu CI (GitHub Actions)

Thin pipeline: `moon ci` on GitHub-hosted runners. Secrets stay in **1Password**; GitHub stores only a Service Account token.

- **UniFi:** Tailscale Action + Homelab subnet route → gateway from `lab.yaml`
- **Uptime Kuma:** Tailscale **L7 Ingress** → `https://uptime-kuma.<tailnet>.ts.net` (no kubeconfig)

Workflow: [`.github/workflows/tofu.yml`](../../.github/workflows/tofu.yml)

| Event | Command |
|-------|---------|
| Pull request (same-repo) | `moon ci :validate :plan` |
| Push to `main` | `moon ci :apply` |

## One-time setup

### 1. 1Password Service Account

```bash
# Requires op signin (desktop app integration). Token is shown once.
TOKEN=$(op service-account create "Homelab CI" --vault "Homelab:read_items" --raw)
op item create --vault Homelab --category "API Credential" \
  --title "Homelab CI OP Service Account" "credential=${TOKEN}" "username=Homelab CI"
printf '%s' "$TOKEN" | gh secret set OP_SERVICE_ACCOUNT_TOKEN
unset TOKEN
```

Or via [1Password Developer](https://developer.1password.com/docs/service-accounts/) UI → **read** on **Homelab**, then set GitHub secret `OP_SERVICE_ACCOUNT_TOKEN`.

### 2. Homelab vault items (must exist)

| Item | Fields used by CI |
|------|-------------------|
| Cloudflare Zone DNS API Token | `credential` |
| Homelab R2 tofu state | `access key id`, `secret access key` |
| UniFi API key (existing) | `credential` (item id in `unifi/moon.yml`) |
| Tailscale OAuth | `client id`, `credential` (OpenTofu provider) |
| **Tailscale CI OAuth** (new) | `client id`, `credential` |
| Uptime Kuma | `username`, `password` |

### 3. Tailscale CI OAuth client

1. Tailscale admin → **Settings → OAuth clients** → create client.
2. Scopes: **Auth Keys** write (enough for ephemeral nodes).
3. Tags: **`tag:ci`** (must match ACL `tagOwners` in `infrastructure/tailscale/acl.tf`).
4. Store client id + secret in 1Password as **Tailscale CI OAuth**.

### 4. Uptime Kuma API (Tailscale L7 Ingress)

GitOps Ingress `uptime-kuma-api` uses Tailscale Serve and bypasses Authentik. Tailnet HTTPS must be enabled (`tailnet_settings.tf`). After Argo syncs:

```bash
curl -sf -o /dev/null https://uptime-kuma.ibex-ladon.ts.net/
```

Endpoint is in `lab.yaml` → `services.uptime_kuma.api_endpoint` (moon + CI).

### 5. UniFi URL

OpenTofu talks to the Homelab gateway from `lab.yaml` (`networks.homelab.gateway_cidr`). Confirm: `curl -skI https://192.168.5.1`.

## Local vs CI

| | Mac | GitHub Actions |
|--|-----|----------------|
| Secrets | `op signin` + `moon.yml` `TOFU_SECRET_*` | `load-secrets-action` → env; `env.sh` skips `op` when set |
| State | R2 (`homelab-tofu-state`) | same |
| UniFi | LAN or Tailscale `--accept-routes` | Tailscale Action + `--accept-routes` |
| Kuma API | Tailscale L7 Ingress | same |

## Break-glass

- Stuck state lock: `tofu force-unlock <id>` or delete `*.tflock` in the R2 bucket.
- Mac apply still works: `moon run <project>:apply`.
