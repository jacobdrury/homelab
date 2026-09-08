# Cilium (CNI)

eBPF CNI + kube-proxy replacement for Talos `prd`. Values follow [Cilium on Talos](https://docs.cilium.io/en/stable/installation/k8s-install-helm/#talos-linux) / [Sidero guide](https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium).

Talos already has `cluster.network.cni.name: none` and `cluster.proxy.disabled: true` in `infrastructure/talos/prd/patches/cluster.yaml`.

## Bootstrap (until Argo owns this)

```bash
export KUBECONFIG=~/.kube/homelab-prd.yaml
./install.sh
```

Pinned chart version is in `install.sh` (`CILIUM_VERSION`).

## GitOps (Phase 2+)

Argo Application under `clusters/prd/` will Helm-release this chart with `-f values.yaml`. Do not `helm upgrade` by hand once Argo syncs.
