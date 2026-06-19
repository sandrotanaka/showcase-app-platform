# GitOps bootstrap (phase 1)

The minimal set of things applied **by hand, once**, to start the platform.
After this, Argo CD manages everything from Git. Every step uses `apply` and is
**idempotent** — safe to re-run.

> Prerequisite: run `./scripts/check-prerequisites.sh` first — it must report
> "Cluster looks ready for phase 1".

## Order matters

```
1. Install GitOps operator         -> creates the Argo CD instance
2. Approve the install plan        -> because installPlanApproval: Manual
3. Create the AppProject           -> scope/guardrails
4. Create the repo-access Secret   -> Argo CD can read this private repo
5. Apply the root App-of-Apps      -> Argo CD takes over from here
```

## 1. Install the GitOps operator (pinned, Manual)

```bash
oc apply -f foundation/gitops/operator/subscription.yaml
```

## 2. Approve the install plan

Because `installPlanApproval: Manual`, the operator waits for approval. Approve
the pending plan:

```bash
# watch until an InstallPlan appears, then approve it
oc get installplan -n openshift-operators
oc patch installplan -n openshift-operators \
  "$(oc get installplan -n openshift-operators \
       -o jsonpath='{.items[?(@.spec.approved==false)].metadata.name}')" \
  --type merge -p '{"spec":{"approved":true}}'

# wait for the operator CSV to reach Succeeded
oc get csv -n openshift-operators | grep gitops
```

Wait until the `openshift-gitops` namespace exists and its Argo CD pods are
Running:

```bash
oc get pods -n openshift-gitops
```

## 3. Create the AppProject

```bash
oc apply -f foundation/gitops/project.yaml
```

## 4. Create the repo-access Secret

This is the credential Argo CD uses to read this **private** repo. It is a
secret, so it is applied here (never committed). Follow
[REPO-ACCESS.md](REPO-ACCESS.md) — current method is an HTTPS PAT:

```bash
oc create secret generic showcase-repo \
  --from-env-file=foundation/gitops/repo-secret.env \
  -n openshift-gitops \
  --dry-run=client -o yaml | \
oc label -f - --local -o yaml \
  argocd.argoproj.io/secret-type=repository | \
oc apply -f -
```

## 5. Apply the root App-of-Apps

```bash
oc apply -f foundation/gitops/bootstrap/root-app.yaml
```

From here Argo CD watches `foundation/apps/` and reconciles whatever child
Applications live there. In phase 1 that becomes Keycloak (wave 2) and Developer
Hub (wave 4); until those files exist, the root app syncs cleanly with nothing
to deploy.

## Watch it reconcile

```bash
oc get applications -n openshift-gitops
```

Argo CD UI route + admin password:

```bash
oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}{"\n"}'
oc get secret openshift-gitops-cluster -n openshift-gitops \
  -o jsonpath='{.data.admin\.password}' | base64 -d; echo
```

## Re-running / idempotency

Every step is `apply`-based and can be re-run. The repo Secret step updates in
place. The root app is reconciled continuously once applied.
