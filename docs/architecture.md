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
  config via ConfigMaps, secrets applied idempotently (see below). See
  [ENVIRONMENT.example.md](ENVIRONMENT.example.md).
- **Portable.** No hardcoded Route hosts, no named StorageClass, public images.
- **Grows by addition.** New solutions copy `solutions/_template/` and declare
  their foundation integrations in a requisites contract.

## Idempotency (a hard requirement)

Every deployment step must be **idempotent**: running it once or many times
converges to the same result, with no "already exists" failures and no
duplicated or drifting state. GitOps gives us most of this for free (declarative,
`apply`-based, self-healing), but a few pieces of this stack are *not* idempotent
by default and are handled deliberately.

### Rules every component and solution follows

- **`apply`, never `create`, for manifests.** `oc apply` (server-side apply) is
  idempotent; `oc create` fails if the object exists. Manifests are always
  applied, never created.
- **Declarative CRs, not imperative scripts.** Identity (Keycloak realm/clients)
  and policies are expressed as operator CRs that reconcile, never as imperative
  `kcadm`/CLI scripts that error or duplicate on re-run.
- **Secrets applied idempotently.** Since the *values* are externalized (never in
  Git), the apply step uses the dry-run-piped-to-apply pattern so it can run any
  number of times:

  ```bash
  oc create secret generic <name> \
    --from-env-file=secret.env \
    --dry-run=client -o yaml | oc apply -f -
  ```

  The same pattern applies to ConfigMaps (`oc create configmap ... --dry-run=client -o yaml | oc apply -f -`).
- **Operators are version-pinned.** Subscriptions use
  `installPlanApproval: Manual` with a pinned `startingCSV`, so the same version
  installs on every run rather than drifting to "latest". Confirm the CSV exists
  on the target cluster's catalog (see [ENVIRONMENT.example.md](ENVIRONMENT.example.md) §2).
- **Namespaces created by Argo CD.** Applications use `CreateNamespace=true`
  rather than a separate manual namespace step.
- **Sync policy retries.** Because a CR may be reconciled before its CRD is
  established (despite sync waves), Applications set automated sync with
  `retry`/backoff so a later pass heals what an earlier pass could not — making
  the whole bootstrap re-runnable to convergence.

### The test

Re-applying the root App-of-Apps, re-running any solution's deploy commands, or
letting Argo CD reconcile repeatedly must never error and must always land on the
same state. If a step can fail on its second run, it is a bug to fix, not a step
to run carefully.

## Data classification

Nothing sensitive about the target environment is committed to Git. Every value
falls into one of three tiers, handled differently:

| Tier | Examples | Where it lives | In Git? |
|------|----------|----------------|---------|
| **Secret** | passwords, client secrets, tokens, kubeconfig, keys | local `secret.env` → `oc create secret ... --dry-run=client -o yaml \| oc apply -f -` | **Never** |
| **Sensitive identifier** | cluster API/apps hosts, route URLs, admin/user names, realm name, OIDC issuer, client IDs | local `docs/ENVIRONMENT.local.md` (gitignored); injected into the cluster via ConfigMap/Secret, referenced by manifests as parameters | **Never literally** — manifests use placeholders/refs, not the real value |
| **Non-sensitive** | OpenShift version, operator channels/CSV, replica counts, sync waves | versioned files (`ENVIRONMENT.example.md`, manifests) | Yes |

Practical rules:

- The versioned fact sheet is **`docs/ENVIRONMENT.example.md`** — placeholders
  only. Your real values go in **`docs/ENVIRONMENT.local.md`** (gitignored).
- Manifests **never hardcode** a sensitive identifier. A value the platform
  genuinely needs (e.g. the Keycloak issuer for RHDH) is supplied at deploy time
  from a ConfigMap/Secret created on the cluster, so the repo stays publishable
  without exposing the environment.
- When in doubt, treat it as at least a **sensitive identifier** and keep it out
  of Git.
