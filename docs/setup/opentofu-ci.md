# OpenTofu CI (GitHub Actions)

Thin pipeline: `moon ci` on GitHub-hosted runners. Secrets stay in **1Password**; GitHub stores only a Service Account token. LAN apps (UniFi, Uptime Kuma) use the **Tailscale GitHub Action** + Homelab Connector (`192.168.5.0/24`) — not self-hosted runners.

Workflow: [`.github/workflows/tofu.yml`](../../.github/workflows/tofu.yml)

| Event | Command |
|-------|---------|
| Pull request (same-repo) | `moon ci :validate :plan` |
| Push to `main` | `moon ci :apply` |

## One-time setup

### 1. 1Password Service Account

1. [1Password Developer](https://developer.1password.com/docs/service-accounts/) → create a Service Account with **read** on the **Homelab** vault (items listed below).
2. GitHub repo → **Settings → Secrets and variables → Actions** → add `OP_SERVICE_ACCOUNT_TOKEN`.

### 2. Homelab vault items (must exist)

| Item | Fields used by CI |
|------|-------------------|
| Cloudflare Zone DNS API Token | `credential` |
| Homelab R2 tofu state | `access key id`, `secret access key` |
| UniFi API key (existing) | `credential` (item id in `unifi/moon.yml`) |
| Tailscale OAuth | `client id`, `credential` (OpenTofu provider) |
| **Tailscale CI OAuth** (new) | `client id`, `credential` |
| Uptime Kuma | `username`, `password` |
| **Homelab CI kubeconfig** (new) | `password` = full kubeconfig YAML |

### 3. Tailscale CI OAuth client

1. Tailscale admin → **Settings → OAuth clients** → create client.
2. Scopes: **Auth Keys** write (enough for ephemeral nodes).
3. Tags: **`tag:ci`** (must match ACL `tagOwners` in `infrastructure/tailscale/acl.tf`).
4. Store client id + secret in 1Password as **Tailscale CI OAuth**.

Apply the ACL (Mac or after this workflow lands) **before** expecting CI Tailscale joins to work:

```bash
moon run tailscale:apply
```

### 4. Homelab CI kubeconfig

Create a limited kubeconfig for CI (port-forward to Uptime Kuma). Until a dedicated ServiceAccount exists, a copy of `connect/prd` kubeconfig in 1Password **Homelab CI kubeconfig** (field `password`) is fine for a solo lab — tighten later.

```bash
# example: paste connect/prd/kubeconfig contents into the 1Password item
cd connect/prd && moon run connect:sync   # if needed
```

### 5. UniFi URL

OpenTofu talks to `https://192.168.5.1` (Homelab gateway). Confirm from a client with Homelab routes: `curl -skI https://192.168.5.1`.

## Local vs CI

| | Mac | GitHub Actions |
|--|-----|----------------|
| Secrets | `op signin` + `moon.yml` `TOFU_SECRET_*` | `load-secrets-action` → env; `env.sh` skips `op` when set |
| State | R2 (`homelab-tofu-state`) | same |
| UniFi / Kuma | LAN or Tailscale | Tailscale Action + `--accept-routes` |

## Break-glass

- Stuck state lock: `tofu force-unlock <id>` or delete `*.tflock` in the R2 bucket.
- Mac apply still works: `moon run <project>:apply`.
