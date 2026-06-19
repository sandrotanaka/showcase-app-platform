# foundation/keycloak/

**Role:** identity anchor. Red Hat build of Keycloak (RHBK) provides the realm,
users, and OIDC clients that Connectivity Link and Developer Hub integrate with.

**Sync wave:** 0 (operator) → 2 (instance + realm + clients).

## Will contain (later phase)

- `operator/` — Subscription for the RHBK operator (wave 0).
- `instance.yaml` — a `Keycloak` CR (wave 2).
- `realm.yaml` — the `showcase` realm (wave 2).
- `clients.yaml` — OIDC clients for Developer Hub and Connectivity Link.
- `secret.env.example` — **keys only** for client secrets / admin password;
  real values applied on the cluster via `oc create secret ... --dry-run=client -o yaml | oc apply -f -` (idempotent). Never in Git.

## Environment values consumed

From [../../docs/ENVIRONMENT.example.md](../../docs/ENVIRONMENT.example.md):
- Keycloak operator channel (§2)
- Keycloak namespace (§3)
- Realm name, OIDC issuer URL, client IDs (§4)

## Provides to the rest of the foundation

- **OIDC issuer URL** → consumed by Developer Hub (login) and Connectivity Link
  (AuthPolicy token validation).
- **Client IDs** `developer-hub` and `connectivity-link` (secrets out-of-band).

## Notes

- TODO: confirm RHBK operator channel.
- TODO: decide realm provisioning approach (realm import CR vs. manual).
- Security: client secrets and admin password are **externalized** — only their
  keys are documented; values are supplied per-cluster.
