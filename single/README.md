# DevOps Ninja Multi-Cluster Manifests Example


```sh
$ kubectl -n schulz run cockroachdb -it \
  --image=cockroachdb/cockroach:v20.2.4 \
  --rm \
  --restart=Never \
  -- sql \
  --insecure \
  --host=cockroachdb.schulz.svc.cluster.local
```











