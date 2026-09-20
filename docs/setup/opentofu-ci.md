# OpenTofu CI (GitHub Actions)

**Status: live** (Sep 2026). Thin pipeline: `moon ci` on GitHub-hosted runners. Secrets stay in **1Password**; GitHub stores only a Service Account token.

| Reach | How |
|-------|-----|
| **UniFi** | Tailscale Action + Homelab subnet route → gateway from `lab.yaml` |
| **Uptime Kuma** | Tailscale **L7 Ingress** → `https://uptime-kuma.<tailnet>.ts.net` (Socket.IO; bypasses Authentik) |
| **cloudflare / tailscale** | Public APIs only (no lab network) |

Workflow: [`.github/workflows/tofu.yml`](../../.github/workflows/tofu.yml)

| Event | Command |
|-------|---------|
| Pull request (same-repo) | `moon ci :validate :plan` |
| Push to `main` | `moon ci :apply` |

`moon ci` runs only **affected** projects (`runInCI: true`). Shared `lab.yaml` is an implicit input — changing it affects all OpenTofu projects.

## One-time setup (completed)

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
| **Tailscale CI OAuth** | `client id`, `credential` |
| Uptime Kuma | `username`, `password` |

### 3. Tailscale CI OAuth client

1. Tailscale admin → **Settings → OAuth clients** → create client.
2. Scopes: **Auth Keys** write (enough for ephemeral nodes).
3. Tags: **`tag:ci`** (must match ACL `tagOwners` in `infrastructure/tailscale/acl.tf`).
4. Store client id + secret in 1Password as **Tailscale CI OAuth**.

### 4. Uptime Kuma API (Tailscale L7 Ingress)

GitOps Ingress `uptime-kuma-api` (`ingressClassName: tailscale`) uses **Tailscale Serve** (HTTPS `:443`) → ClusterIP `:3001`. Bypasses Authentik on `uptime.lab`.

- Tailnet **HTTPS** must be on — OpenTofu `https_enabled = true` in `infrastructure/tailscale/tailnet_settings.tf`.
- Endpoint: `lab.yaml` → `services.uptime_kuma.api_endpoint` (moon + CI).

```bash
curl -sf -o /dev/null https://uptime-kuma.ibex-ladon.ts.net/
```

**Why L7 (not L3) for Kuma:** HTTP/Socket.IO needs TLS and path-based proxying; L7 matches that. L3 (`tailscale.com/expose`) is for raw TCP/UDP (e.g. Minecraft). Cilium must use `socketLB.hostNamespaceOnly` for L3 DNAT — already set in `clusters/prd/platform/cilium/values.yaml`.

### 5. UniFi URL

OpenTofu talks to the Homelab gateway from `lab.yaml` (`networks.homelab.gateway_cidr`). Confirm: `curl -skI https://192.168.5.1` (LAN or Tailscale `--accept-routes`).

## Local vs CI

| | Mac | GitHub Actions |
|--|-----|----------------|
| Secrets | `op signin` + `moon.yml` `TOFU_SECRET_*` | `load-secrets-action` → env; `env.sh` skips `op` when set |
| State | R2 (`homelab-tofu-state`) | same |
| UniFi | LAN or Tailscale `--accept-routes` | Tailscale Action + `--accept-routes` |
| Kuma API | Tailscale L7 Ingress (on tailnet) | Action `targets:` wait + moon |

## Break-glass

- Stuck state lock: `tofu force-unlock <id>` or delete `*.tflock` in the R2 bucket.
- Mac apply: `moon run <project>:apply` (prefer CI for steady state).
