# foundation/gitops/

**Role:** the delivery mechanism. Red Hat OpenShift GitOps (Argo CD) is what
reconciles the whole platform from Git.

**Sync wave:** prerequisite (must exist before any Application is reconciled).

## Will contain (later phase)

- `operator/` — Subscription for the OpenShift GitOps operator.
- `project.yaml` — Argo CD `AppProject` "showcase" (allowed source repos and
  destinations: `showcase-*` plus the foundation namespaces).
- `root-app.yaml` — the App-of-Apps root Application, **applied by hand once**,
  which then manages the foundation and the solutions.

## Environment values consumed

From [../../docs/ENVIRONMENT.md](../../docs/ENVIRONMENT.md):
- GitOps operator channel (§2)
- This repo URL + default branch (§7)
- Namespaces (§3)

## Notes

- TODO: confirm the GitOps operator channel available on the cluster.
