# Design notes

## Why a hand-rolled chart instead of the argo upstream chart or DandyDeveloper redis-ha?

The argo-cd Helm chart ([argoproj/argo-helm/charts/argo-cd](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd)) ships an embedded single-instance Redis whose templates handle password bootstrap (`lookup + randAlphaNum`) and a conditional dependency on [DandyDeveloper redis-ha](https://github.com/DandyDeveloper/charts/tree/master/charts/redis-ha) for HA topology. Either chart would have saved us rolling our own; both were considered. Reasons we shipped a hand-rolled wrapper:

- **The argo-cd chart isn't separable.** The embedded Redis templates assume they're being consumed by `argocd-server` over its in-cluster Service name and that auth is wired into `argocd-secret`. There's no `helm install` invocation that gives you just the Redis bits without also rendering controller / server / repo-server / applicationset-controller. Using it standalone would mean installing an `argo-cd`-named release with everything else disabled, which is confusing as a worked example.
- **DandyDeveloper redis-ha is HA-by-default.** Three Redis pods + three Sentinel pods + auto-failover. Reasonable for production, heavyweight for a starter "deploy Redis on NKS" example whose explicit scope is single-replica. The HA shape would also push worker count up (anti-affinity spread) and make the connection story Sentinel-aware.

The trade-off cost: we re-implement password bootstrap ourselves. The PreSync hook in `redis/templates/auth-bootstrap-hook.yaml` covers it — dual-annotated for ArgoCD (`argocd.argoproj.io/hook: PreSync`) and Helm (`helm.sh/hook: pre-install`) so the same template works under direct `helm install`, `terraform apply` via `helm_release`, and ArgoCD-managed sync.

If this starter ever shifts posture toward "production-shaped HA" — analogous to how mongo-on-nks defaulted to a 3-member operator-managed replica set — DandyDeveloper's redis-ha is the right swap target: it's what argo upstream uses for HA, it handles bootstrap natively, and it's the vendor-idiomatic path. The hand-rolled shape stays as long as the example is anchored to "minimal single-instance Redis on NKS."
