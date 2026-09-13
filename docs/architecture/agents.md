# Agent access

First-class requirement: AI agents (e.g. Cursor) can **operate and observe** the lab — not a bolt-on.

## Goal

From a Cursor session: `kubectl`, logs, Unraid/HA/Argo/Grafana APIs, and GitOps changes — without tribal SSH lore. Git remains source of truth.

```mermaid
flowchart LR
  Agent[Cursor_agent]
  TS[Tailscale]
  Kube[kubectl_helm]
  HTTP[lab_HTTPS]
  Git[GitHub_repo]
  OP[op_CLI]
  Agent --> TS
  Agent --> Kube
  Agent --> HTTP
  Agent --> Git
  Agent --> OP
```

## Reachability

| Path | Role |
|------|------|
| Tailscale on agent host | Primary remote path — **split DNS** for `lab.jacobdrury.com` + **subnet routes** to Homelab |
| `*.lab.jacobdrury.com` | Same URLs: LAN via Pi-hole → Cloudflare; away via split DNS → **Cloudflare direct** |
| **`connect/<cluster>/`** | In-repo kubeconfig + talosconfig — `cd connect/prd` (direnv) or `source connect/env.sh`; `moon run connect:sync` |
| `op` | Secrets — never in Git |
| MCP (optional) | k8s / HA structured tools when shell is painful |

Details: [networking](networking.md#tailscale) (split DNS, subnet router timeline, HTTPS) · [connect/README](../../connect/README.md).

## Operating model

1. **Prefer Git** — edit this repo → PR → Argo  
2. **Break-glass shell** — diagnose / restart; avoid permanent snowflake applies  
3. **In-repo agent docs** — `AGENTS.md` / `.agents/skills`: context, hostnames ([naming](naming.md)), “no secrets in Git”  
4. **Least privilege later** — optional agent Tailscale identity + limited RBAC  

## Buildout

| Phase | What |
|-------|------|
| **Now** | Tailscale IaC; **homelab02** interim subnet router; `http://*.lab` remote via split DNS → Cloudflare |
| **2 (done)** | **`connect/`**; CSI; Connect + ESO; **Argo CD**; **Envoy** + LE wildcard (`argocd.lab`) |
| **2 (next)** | Transitional HTTPRoutes; **Tailscale operator**; Homepage |
| **3+** | Remove homelab02 subnet routes before pc (black) retires; retire legacy `*.homelab.com` Pi-hole records |
| **5** | Agent RBAC, optional MCP, `AGENTS.md` / skills |

**Non-goal:** public kube API or Unraid for agents. Agents use the **tailnet**.
