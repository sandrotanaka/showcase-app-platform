# foundation/keycloak/

**Role:** identity anchor. Red Hat build of Keycloak (RHBK) provides the realm,
OIDC clients, and test users that Developer Hub (and later Connectivity Link)
integrate with.

**Sync waves:** 0 (operator) -> 1 (instance + realm). The child Application
(`../apps/keycloak-app.yaml`) is wave 2 in the foundation order.

## Design decisions

- **Ephemeral database (no PVC).** Identity is defined as code (realm/client/
  users via CR), so the meaningful state is reconciled from Git on every boot. A
  restart loses only manual-console state and sessions, which we don't keep. To
  make it persistent later: add Postgres + set the `db` block in `instance.yaml`.
- **Edge TLS via OpenShift Route.** Simplest portable exposure; no hardcoded
  host (the cluster assigns it).
- **Secrets handled two ways.** The OIDC **client secret is Keycloak-generated
  (Form 2)**: the realm registers `developer-hub` with no secret, Keycloak
  generates one, and the operator publishes it as a Secret in `showcase-keycloak`
  — it never touches Git or your machine. Only the **test-user passwords** go
  through the template + local `secret.env`.

## Files

| File | What | Synced by Argo CD? |
|------|------|--------------------|
| `operator/subscription.yaml` | RHBK operator (pinned, Manual) + OperatorGroup | yes (wave 0) |
| `instance.yaml` | `Keycloak` CR — ephemeral, edge route | yes (wave 1) |
| `realm.yaml.tpl` | `KeycloakRealmImport` TEMPLATE (realm + client + users) | **no — applied by hand** |
| `secret.env.example` | keys for the template (no real values) | yes |

## Why the realm is applied by hand

Argo CD syncs static manifests; it does not run envsubst. The realm template
carries secrets and needs substitution, so it is applied out-of-band via the
render script — the same principle as the private-repo Secret: **secrets never
flow through Git/Argo CD.**

## Seed the realm (after the instance is up)

```bash
cp foundation/keycloak/secret.env.example foundation/keycloak/secret.env
# edit secret.env: set the two test-user passwords
./scripts/render-keycloak-realm.sh
```

The script renders `realm.yaml.tpl` with your local passwords and applies it
idempotently. The rendered file is gitignored.

### Get the Keycloak-generated client secret (Form 2)

After the realm import reconciles, Keycloak generates the `developer-hub` client
secret and the operator publishes it as a Secret. Find and read it:

```bash
oc get secret -n showcase-keycloak | grep developer-hub
# then (name may vary by version):
oc get secret keycloak-client-secret-developer-hub -n showcase-keycloak \
  -o jsonpath='{.data.CLIENT_SECRET}' | base64 -d; echo
```

Developer Hub (phase 1, next) will consume this Secret directly — the value
never needs to be copied into Git.

## Environment values

Consumed/produced (see `../../docs/ENVIRONMENT.example.md` §4):
- Realm name `showcase`, client `developer-hub` (decided).
- Keycloak host + OIDC issuer URL — known only AFTER install; record then.

## Version note

RHBK 26 manifests use `k8s.keycloak.org/v2beta1` (confirmed against the installed
CRD on OpenShift). The ephemeral DB is set via `additionalOptions: db=dev-file`
(v2beta1 has no `db.vendor: dev-file`). If you run a different RHBK version,
check `oc explain keycloak.spec --api-version=k8s.keycloak.org/v2beta1`.
