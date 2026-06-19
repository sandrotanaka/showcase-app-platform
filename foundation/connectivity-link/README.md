# foundation/connectivity-link/

**Role:** API exposure, auth, and traffic policy. Connectivity Link (built on
Kuadrant + Gateway API) provides the shared Gateway and the AuthPolicy /
RateLimitPolicy that protect solution APIs, validating tokens against Keycloak.

**Sync wave:** 0 (operator) → 3 (Gateway + policies, after Keycloak exists).

## Status: deferred to phase 2

Phase 1 of `showcase-app-platform` brings up GitOps + Keycloak + Developer Hub.
This component is intentionally deferred, for a concrete reason found on the
target cluster:

- The Red Hat **Connectivity Link** product operator is **not** in this
  cluster's catalog.
- Only the upstream **Kuadrant community** operator is available
  (`kuadrant-operator`, channel `stable`, `v0.11.1` — a pre-1.0 release).

When this phase is built, the choice is: use Kuadrant community here (documenting
that it is upstream, not the supported product), or add the Connectivity Link
catalog source on a cluster that has the entitlement. The CR names and API
versions differ between the two, so the manifests are written against whichever
is actually installed.

## Will contain (phase 2)

- `operator/` — Subscription for the Connectivity Link / Kuadrant operator (wave 0).
- `gateway.yaml` — a shared `Gateway` (Gateway API) with listeners (wave 3).
- `authpolicy-example.yaml` — an `AuthPolicy` referencing the Keycloak OIDC
  issuer, as the extension point solutions copy.

## Environment values consumed

From [../../docs/ENVIRONMENT.example.md](../../docs/ENVIRONMENT.example.md):
- Connectivity Link operator channel (§2)
- GatewayClass, shared Gateway name, listener host (§5)
- Keycloak OIDC issuer URL (§4) — for AuthPolicy

## Notes

- TODO: confirm the operator package name and channel (Kuadrant / Connectivity
  Link naming varies by catalog).
- TODO: confirm a compatible `GatewayClass` exists (`oc get gatewayclass`).
- ⚠️ This is the most version-sensitive component: the AuthPolicy ↔ Keycloak
  OIDC wiring may need adjustment for your installed version. Treat the example
  policy as a starting point, not a guaranteed-final spec.
