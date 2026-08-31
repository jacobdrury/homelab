# Local workstation setup

Tools for operating the homelab from your Mac. Pins for CLI versions live in [`.prototools`](../../.prototools); install via [proto](https://moonrepo.dev/docs/proto) + [moon](https://moonrepo.dev).

## Homebrew

```bash
# Homebrew (if needed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Required

```bash
# 1Password CLI — secrets for OpenTofu / break-glass (vault: Homelab)
brew install --cask 1password-cli

# proto — installs moon, OpenTofu, kubectl, helm per .prototools
bash <(curl -fsSL https://moonrepo.dev/install/proto.sh)
export PATH="$HOME/.proto/bin:$PATH"
echo 'export PATH="$HOME/.proto/bin:$PATH"' >> ~/.zshrc

proto install
```

Sign in to 1Password:

```bash
op signin
op vault list   # expect Homelab
```

Moon tasks load secrets from each OpenTofu project's `moon.yml` (`TOFU_SECRET_*` → `op read`, `TOFU_ENV_*` → literal). See [infrastructure/README.md](../../infrastructure/README.md).

OpenTofu projects (Phase 1.5):

```bash
op signin
moon run dns:apply
moon run unifi:apply
moon run pihole:apply
```

IaC policy: [architecture/iac.md](../architecture/iac.md).

## UniFi API key (Phase 1.5)

On the **UDM Pro** (local UI — `https://192.168.1.1`), not unifi.ui.com Site Manager:

1. Open **Settings** (gear).
2. Go to **Control Plane** → **Integrations** (on some firmware it is top-level **Integrations**).
3. **Create new API key**.
4. Name: `opentofu-homelab`.
5. Expiration: pick the longest option (or none, if offered).
6. **Create** → copy the key once (shown only once).
7. Save in 1Password **Homelab** vault as **`Unifi API Key (opentofu-homelab)`**.

Use a **local** console key. A **Site Manager** key from unifi.ui.com only works with the remote API — wrong for `tofu apply` from your Mac on LAN.

**Fallback (older providers):** local admin — **Settings → Admins & Users → Add admin** → local username/password, **Site Admin** for Network only, disable remote/cloud for that account. Prefer the API key when available.

## Phase 2+ (Talos / cluster)

`talosctl` is pinned in [`.prototools`](../../.prototools) (plugin: [`.moon/proto-plugin/talosctl.toml`](../../.moon/proto-plugin/talosctl.toml)). Use **1.12.7** for the Mac Mini 2018 boot image (1.13+ hangs on Apple EFI).

```bash
proto install talosctl
talosctl version --client
```

**Tailscale (remote `*.lab`):** `moon run tailscale:apply` — see [infrastructure/tailscale/README.md](../../infrastructure/tailscale/README.md). macOS CLI:

```bash
/Applications/Tailscale.app/Contents/MacOS/Tailscale status
```

`kubectl` and `helm` are already via `proto install`.

## Verify

```bash
op whoami
tofu version    # 1.9.x
kubectl version --client
talosctl version
moon --version
```

## Related

- [Networking](../architecture/networking.md) — DNS, VLAN, firewall  
- [Secrets](../architecture/secrets.md) — 1Password → cluster  
- [Agents](../architecture/agents.md) — tailnet + kubeconfig  
