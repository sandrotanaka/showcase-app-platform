# foundation/connectivity-link/

**Role:** API exposure, auth, and traffic policy. Connectivity Link (built on
Kuadrant + Gateway API) provides the shared Gateway and the AuthPolicy /
RateLimitPolicy that protect solution APIs, validating tokens against Keycloak.

**Sync wave:** 0 (operator) → 3 (Gateway + policies, after Keycloak exists).

## Will contain (later phase)

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
