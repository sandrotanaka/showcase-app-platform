# foundation/

Shared platform services, **installed once per cluster** and delivered by GitOps.
Solutions in `../solutions/` are built on top of these.

This initial repo contains only the **skeleton and notes** for each foundation
component — the manifests are added in a later phase. Each folder's README
states what will live there, its **sync wave** (install order), and which
[ENVIRONMENT.example.md](../docs/ENVIRONMENT.example.md) values it will consume.

## Components and install order

| Wave | Component | Folder | Role | Status |
|------|-----------|--------|------|--------|
| 0 | Operators | each folder's `*/operator/` | Subscriptions; CRDs must exist before CRs | phase 1 |
| 2 | Keycloak | [`keycloak/`](keycloak/) | identity anchor: realm + OIDC clients | phase 1 |
| 4 | Developer Hub | [`developer-hub/`](developer-hub/) | catalog/portal, OIDC via Keycloak | phase 1 |
| 3 | Connectivity Link | [`connectivity-link/`](connectivity-link/) | shared Gateway + AuthPolicy → Keycloak | **deferred (phase 2)** |

> **Phasing.** Phase 1 brings up GitOps + Keycloak + Developer Hub — the stable
> core. Connectivity Link is deferred to phase 2: on this workshop cluster only
> the **Kuadrant community** operator (`v0.11.x`, pre-1.0) is available, which is
> upstream — not the Red Hat Connectivity Link product. Its wave number stays 3
> so it slots in ahead of Developer Hub's dependents when added on a cluster that
> has the product (or where Kuadrant community is acceptable). See
> [connectivity-link/README.md](connectivity-link/README.md).

> GitOps itself (`gitops/`) is wave -1 / prerequisite: the operator and the Argo
> CD instance must exist before anything here is reconciled.

The ordering is enforced later with Argo CD `argocd.argoproj.io/sync-wave`
annotations. See [../docs/architecture.md](../docs/architecture.md).

> **Idempotency:** every component installs via `apply` (never `create`), uses
> version-pinned Subscriptions (`installPlanApproval: Manual`), and is delivered
> by Argo CD with `CreateNamespace=true` and sync retries — so the whole
> bootstrap is re-runnable to convergence. See the idempotency rules in
> [../docs/architecture.md](../docs/architecture.md#idempotency-a-hard-requirement).
