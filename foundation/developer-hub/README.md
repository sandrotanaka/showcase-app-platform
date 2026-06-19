# foundation/developer-hub/

**Role:** the catalog/portal. Red Hat Developer Hub (RHDH, based on Backstage)
is where solutions register and become discoverable. It authenticates users via
Keycloak (OIDC).

**Sync wave:** 0 (operator) → 4 (instance, after Keycloak exists).

## Will contain (later phase)

- `operator/` — Subscription for the RHDH operator (wave 0).
- `instance.yaml` — a `Backstage` CR for the Developer Hub instance (wave 4).
- `app-config.yaml` (as ConfigMap) — RHDH config: OIDC provider = Keycloak,
  catalog discovery via per-solution `catalog-info.yaml`.
- `secret.env.example` — keys only for the OIDC client secret; value via
  `oc create secret ... --dry-run=client -o yaml | oc apply -f -` (idempotent).

## Environment values consumed

From [../../docs/ENVIRONMENT.example.md](../../docs/ENVIRONMENT.example.md):
- RHDH operator channel (§2)
- Developer Hub namespace (§3)
- Developer Hub route/host, auth provider (§6)
- Keycloak issuer URL + `developer-hub` client ID (§4)

## Catalog model

Each solution carries a `catalog-info.yaml` (Backstage-native). RHDH discovers
these so a new solution appears in the portal automatically — this is the
"presentation" half of registering a solution (the GitOps Application is the
"delivery" half).

## Notes

- TODO: confirm RHDH operator channel.
- TODO: confirm the exact OIDC redirect URI RHDH expects (record in ENVIRONMENT §4).
