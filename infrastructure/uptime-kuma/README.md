# Uptime Kuma (OpenTofu)

Manages **HTTP monitors** and the public **Lab** status page (`/status/default`) via the [breml/uptimekuma](https://registry.terraform.io/providers/breml/uptimekuma) provider.

Kuma itself (Helm, MariaDB, Authentik proxy, API L7 Ingress) stays under GitOps: `clusters/prd/apps/uptime-kuma/`.

## Why OpenTofu

There is no in-cluster reconciler for Kuma monitors. Same pattern as UniFi: external API owned under `infrastructure/`.

## Auth / network

`https://uptime.lab.jacobdrury.com` is Authentik-proxied (browser UI). OpenTofu uses a **Tailscale L7 Ingress** instead (bypasses Authentik):

`https://uptime-kuma.ibex-ladon.ts.net` (`lab.yaml` → `services.uptime_kuma.api_endpoint`)

You must be on the tailnet. No `kubectl`, kubeconfig, port-forward, or subnet route is needed for Kuma.

Credentials: 1Password **`Uptime Kuma`** (`username` / `password`). Native UI auth can stay disabled; API login still works.

```bash
op signin
# Tailscale connected
moon run uptime-kuma:apply
```

### Existing UI status page

The provider does **not** support import. If slug `default` already exists from the UI, delete that status page in Kuma (or via the Socket.IO `deleteStatusPage` API) once, then `moon run uptime-kuma:apply` to recreate it from Git.

## Adding a service

1. Homepage tile (`clusters/prd/apps/homepage/values.yaml`)
2. Monitor entry in `monitors.tf` (+ `monitor_order` for the status page)
3. `moon run uptime-kuma:apply` (or CI on merge)

For **Authentik-proxied** apps, do **not** probe `/` (that only checks the Authentik login redirect). Use a `skip_path_regex` URL that reaches the backend — see comments in `monitors.tf` (media *arr `/api` → 401; qBit version API → 200).
