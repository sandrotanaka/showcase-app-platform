# foundation/

Shared platform services, **installed once per cluster** and delivered by GitOps.
Solutions in `../solutions/` are built on top of these.

This initial repo contains only the **skeleton and notes** for each foundation
component — the manifests are added in a later phase. Each folder's README
states what will live there, its **sync wave** (install order), and which
[ENVIRONMENT.md](../docs/ENVIRONMENT.md) values it will consume.

## Components and install order

| Wave | Component | Folder | Role |
|------|-----------|--------|------|
| 0 | Operators (all) | each folder's `*/operator/` | Subscriptions; CRDs must exist before CRs |
| 2 | Keycloak | [`keycloak/`](keycloak/) | identity anchor: realm + OIDC clients |
| 3 | Connectivity Link | [`connectivity-link/`](connectivity-link/) | shared Gateway + AuthPolicy → Keycloak |
| 4 | Developer Hub | [`developer-hub/`](developer-hub/) | catalog/portal, OIDC via Keycloak |

> GitOps itself (`gitops/`) is wave -1 / prerequisite: the operator and the Argo
> CD instance must exist before anything here is reconciled.

The ordering is enforced later with Argo CD `argocd.argoproj.io/sync-wave`
annotations. See [../docs/architecture.md](../docs/architecture.md).

> **Idempotency:** every component installs via `apply` (never `create`), uses
> version-pinned Subscriptions (`installPlanApproval: Manual`), and is delivered
> by Argo CD with `CreateNamespace=true` and sync retries — so the whole
> bootstrap is re-runnable to convergence. See the idempotency rules in
> [../docs/architecture.md](../docs/architecture.md#idempotency-a-hard-requirement).
