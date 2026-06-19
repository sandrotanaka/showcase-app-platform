# Architecture

## Target scenario (the "ideal" environment)

The `showcase` provisions a complete platform foundation on OpenShift and then
incorporates solutions on top of it. The foundation is **demonstrated and
installed from scratch**; solutions plug into it.

```
                         ┌───────────────────────────────────────────┐
                         │                OpenShift                   │  (the floor)
                         └───────────────────────────────────────────┘
                                            │
                         ┌───────────────────────────────────────────┐
   Delivery mechanism →  │   GitOps (OpenShift GitOps / Argo CD)      │
                         │   App-of-Apps, sync waves orchestrate order│
                         └───────────────────────────────────────────┘
                                            │ reconciles, in order (sync waves)
        ┌───────────────────────────────────┼───────────────────────────────────┐
        ▼                                   ▼                                   ▼
┌───────────────┐                 ┌───────────────────┐               ┌────────────────────┐
│   Keycloak    │  identity for   │ Connectivity Link │  exposure/auth │   Developer Hub    │
│   (RHBK)      │ ───────────────▶│   (Kuadrant)      │◀───────────────│   (RHDH) = catalog │
│ realm+clients │                 │ Gateway+AuthPolicy│   for APIs      │  OIDC via Keycloak │
└───────────────┘                 └───────────────────┘               └────────────────────┘
        ▲                                   ▲                                   ▲
        │ authenticate                      │ expose + protect                  │ appear in catalog
        └───────────────────────┬───────────┴───────────────────────────────────┘
                                │
                    ┌───────────────────────┐
                    │      Solutions         │  incorporated ON TOP of the foundation
                    │  (showcase-*, growing) │  each declares how it uses Keycloak,
                    └───────────────────────┘  Connectivity Link, and Developer Hub
```

## Foundation vs. solutions

The five pieces are **not** peers:

- **OpenShift** — the platform/floor (assumed present).
- **GitOps** — the *delivery mechanism*. One root App-of-Apps is applied by hand;
  Argo CD reconciles everything else from Git.
- **Keycloak, Connectivity Link, Developer Hub** — the **foundation**: shared
  platform services installed once per cluster. Solutions *consume* them.
- **Solutions** — demos incorporated on top. Each one authenticates via Keycloak,
  is exposed/protected via Connectivity Link, and registers in the Developer Hub
  catalog.

## Ordering is a real dependency (why sync waves)

Things must come up in order, and Argo CD must be told the order explicitly:

1. **Operators** (Subscriptions) install first — nothing using their CRDs can be
   applied until the CRDs are established.
2. **Keycloak** instance + realm + OIDC clients come up next — it is the identity
   anchor the other two integrate with.
3. **Connectivity Link** (shared Gateway + AuthPolicy referencing Keycloak's
   issuer) comes after identity exists.
4. **Developer Hub** comes up pointing at Keycloak as its OIDC provider.
5. **Solutions** deploy last, on top of the ready foundation.

This is implemented with Argo CD `sync-wave` annotations in a later phase. This
initial repo documents the design and captures the environment; the manifests
follow.

## Principles carried over

- **GitOps-delivered.** Git is the source of truth; apply the root once.
- **Externalize everything.** No environment-specific values or secrets in Git —
  config via ConfigMaps, secrets via `oc create secret`. See
  [ENVIRONMENT.md](ENVIRONMENT.md).
- **Portable.** No hardcoded Route hosts, no named StorageClass, public images.
- **Grows by addition.** New solutions copy `solutions/_template/` and declare
  their foundation integrations in a requisites contract.
