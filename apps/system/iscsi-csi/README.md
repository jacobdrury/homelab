# iSCSI CSI → scarif (democratic-csi)

Dynamic **RWO** block volumes via ZFS zvols on Unraid pool **`scarif-ssd`**, exported with **targetcli** (iSCSI Target plugin).

| | |
|--|--|
| Driver | `org.democratic-csi.iscsi` (`zfs-generic-iscsi`) |
| StorageClass | `scarif-iscsi` |
| Backend | `192.168.5.10` · ZFS `scarif-ssd/k8s/vols` (+ snaps sibling) |

## Prerequisites

1. Unraid pool `scarif-ssd` + datasets `k8s/vols`, `k8s/snaps`
2. **iSCSI Target** plugin installed (targetcli) — leave targets empty; CSI creates them
3. Talos nodes have extension **`siderolabs/iscsi-tools`** (schematic `b61bec70…`)
4. SSH key: CSI controller → `root@192.168.5.10` (public key in scarif `authorized_keys`)
5. Namespace labeled for privileged PSA (install.sh does this)

**SSH key vs TLS:** this is an SSH private key for ZFS/targetcli, **not** a cert-manager certificate. Store the private key in **1Password** + gitignored `secrets/`; later **ESO** can inject it. cert-manager only covers HTTPS for `*.lab`.

## Install (pre-Argo)

```bash
# 1) Generate key once (gitignore the private key)
mkdir -p apps/system/iscsi-csi/secrets
ssh-keygen -t ed25519 -f apps/system/iscsi-csi/secrets/scarif-csi -N '' -C 'democratic-csi@prd'
# install public key on scarif:
#   cat apps/system/iscsi-csi/secrets/scarif-csi.pub >> /root/.ssh/authorized_keys

# 2) Create k8s secret + helm
cd connect/prd   # or: source connect/env.sh
bash apps/system/iscsi-csi/install.sh
```

## Smoke test

```bash
kubectl apply -f apps/system/iscsi-csi/smoke-test.yaml
kubectl -n iscsi-smoke wait --for=condition=Ready pod/iscsi-smoke --timeout=180s
kubectl -n iscsi-smoke exec iscsi-smoke -- sh -c 'echo ok > /data/hello && cat /data/hello'
kubectl delete -f apps/system/iscsi-csi/smoke-test.yaml
```
