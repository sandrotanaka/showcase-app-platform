# foundation/apps/

Child Argo CD `Application` manifests, one per foundation component. The root
App-of-Apps (`../gitops/bootstrap/root-app.yaml`) watches this directory, so
**adding a component = dropping its Application file here** — no edit to the root.

Each child Application points at its component's manifests elsewhere under
`foundation/` (e.g. `foundation/keycloak`) and carries an
`argocd.argoproj.io/sync-wave` annotation to enforce install order.

## Phase 1 (to be added next)

| File | Component | Wave | Points at |
|------|-----------|------|-----------|
| `keycloak-app.yaml` | Keycloak (RHBK) | 2 | `foundation/keycloak` |
| `developer-hub-app.yaml` | Developer Hub (RHDH) | 4 | `foundation/developer-hub` |

`keycloak-app.yaml` is present; `developer-hub-app.yaml` comes next. Until both exist, missing ones simply are not created, so the root app syncs
cleanly with nothing to create yet.
