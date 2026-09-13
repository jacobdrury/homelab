# Apps

Kubernetes workloads managed by Argo CD (once Phase 2 GitOps is live). Until then, bootstrap install scripts under each app (e.g. `system/cilium/install.sh`).

| Path | Role |
|------|------|
| `system/cilium/` | CNI + kube-proxy replacement |
| `system/nfs-csi/` | RWX media on scarif NFS |
| `system/iscsi-csi/` | RWO block on scarif ZFS/iSCSI |
| `system/` (later) | cert-manager, Envoy, Tailscale, ESO, … |
| `media/`, `home/`, `games/`, `network/` | Workloads (Phase 3+) |
