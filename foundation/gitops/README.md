# foundation/gitops/

**Role:** the delivery mechanism. Red Hat OpenShift GitOps (Argo CD) is what
reconciles the whole platform from Git.

**Sync wave:** prerequisite (must exist before any Application is reconciled).

## Contents (phase 1)

- `operator/subscription.yaml` — Subscription for the OpenShift GitOps operator,
  pinned: channel `gitops-1.20`, `startingCSV: openshift-gitops-operator.v1.20.4`,
  `installPlanApproval: Manual`. Installed **by hand** (the operator can't be
  installed by the Argo CD it creates — see the bootstrap decision in
  [../../docs/architecture.md](../../docs/architecture.md)).
- `project.yaml` — Argo CD `AppProject` "showcase": allowed source repos and
  destinations (`showcase-*` + foundation namespaces + `openshift-operators`).
- `bootstrap/root-app.yaml` — the App-of-Apps root Application, **applied by hand
  once**, watching `foundation/apps/`.
- `bootstrap/README.md` — the exact, idempotent manual bootstrap sequence.
- `../apps/` — directory of child Applications the root watches (phase 1 adds
  Keycloak + Developer Hub here).

## Bootstrap

The minimal by-hand steps (operator → approve → AppProject → repo Secret → root
app) are in **[bootstrap/README.md](bootstrap/README.md)**. Run
`./scripts/check-prerequisites.sh` first.

## Repository access (private repo)

Argo CD needs a credential to read this private repo. **Current choice: HTTPS
PAT.** Full step-by-step for both PAT and SSH deploy key (with security rules
and rotation) is in **[REPO-ACCESS.md](REPO-ACCESS.md)**. The credential is a
Secret applied by hand (never in Git) — it, plus the root Application, is the
minimal manual bootstrap.

## Environment values consumed

From [../../docs/ENVIRONMENT.example.md](../../docs/ENVIRONMENT.example.md):
- GitOps operator channel + CSV (§2) — pinned `gitops-1.20` / `v1.20.4`
- This repo URL + default branch (§7)
- Namespaces (§3)

## Notes

- GitOps operator version confirmed on the cluster and pinned (see above).
- Repo access via HTTPS PAT for now; SSH deploy key documented as the
  least-privilege alternative in REPO-ACCESS.md.
