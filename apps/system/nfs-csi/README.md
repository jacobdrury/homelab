# NFS CSI → scarif

Dynamic **RWX** volumes on Unraid NFS (`192.168.5.10:/mnt/disks/ZXA0VZBA`).

| | |
|--|--|
| Driver | `nfs.csi.k8s.io` (Helm `csi-driver-nfs`) |
| StorageClass | `scarif-nfs` |
| UID/GID | Pods must run as **`99:100`** — [storage NFS perms](../../../docs/architecture/storage.md#nfs-permissions-uid--squash) |

## Install (pre-Argo)

```bash
cd connect/prd   # or: source connect/env.sh
bash apps/system/nfs-csi/install.sh
```

## Smoke test

```bash
kubectl apply -f apps/system/nfs-csi/smoke-test.yaml
kubectl -n nfs-smoke wait --for=condition=Ready pod/nfs-smoke --timeout=120s
kubectl -n nfs-smoke exec nfs-smoke -- sh -c 'touch /data/.k8s-nfs-ok && ls -la /data/.k8s-nfs-ok'
kubectl delete -f apps/system/nfs-csi/smoke-test.yaml
```

If `touch` fails with Permission denied, fix ownership on scarif (`nobody:users` on the media tree) before apps.
