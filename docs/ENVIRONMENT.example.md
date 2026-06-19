# Environment Fact Sheet (template)

> **This is the versioned template — placeholders only, no real values.**
> Copy it to your local, gitignored fact sheet and fill that one in:
>
> ```bash
> cp docs/ENVIRONMENT.example.md docs/ENVIRONMENT.local.md
> ```
>
> `ENVIRONMENT.local.md` is in `.gitignore` and never leaves your machine. It
> holds **sensitive-but-not-secret identifiers** (hosts, URLs, admin user names,
> realm, client IDs). True secrets (passwords, client secrets, tokens) do not go
> even there — they go in a local `secret.env` and are applied via
> `oc create secret ... --dry-run=client -o yaml | oc apply -f -`.
>
> See the data-classification rules in
> [architecture.md](architecture.md#data-classification).

This is the **single place to record the concrete details of your target
environment** as you discover them. Fill it in incrementally. The foundation
manifests (added in a later phase) will consume these values, so capturing them
accurately here first keeps everything consistent.

> Rule: this file holds **identifiers and non-secret facts** (versions, domains,
> namespaces, realm names, client IDs). It must **never** hold passwords, client
> secrets, or tokens — those are applied on the cluster via `oc create secret ... --dry-run=client -o yaml | oc apply -f -` (idempotent)
> and listed by key only in the relevant `*.env.example` files.

Replace every `TODO` / `<...>` as you confirm the value on your cluster.

---

## 1. Cluster

| Item | Value | How to find it |
|------|-------|----------------|
| OpenShift version | `TODO` | `oc version` |
| Cluster API URL | `<https://api.cluster.example.com:6443>` | `oc whoami --show-server` |
| Apps wildcard domain | `<apps.cluster.example.com>` | `oc get ingresses.config/cluster -o jsonpath='{.spec.domain}'` |
| Default StorageClass | `TODO` | `oc get storageclass` (look for `(default)`) |
| Cluster admin available? | `yes / no` | needed to install operators |

## 2. Operators (confirm channel/version on YOUR cluster)

Channels and CSV versions vary by what is published in your cluster's
OperatorHub. Confirm each before pinning it in a Subscription.

| Operator | Namespace | Channel | Confirmed CSV | How to find it |
|----------|-----------|---------|---------------|----------------|
| Red Hat OpenShift GitOps | `openshift-gitops-operator` | `TODO` | `TODO` | `oc get packagemanifest openshift-gitops-operator -o jsonpath='{.status.channels[*].name}'` |
| Red Hat build of Keycloak | `TODO` | `TODO` | `TODO` | `oc get packagemanifest rhbk-operator -o jsonpath='{.status.channels[*].name}'` |
| Connectivity Link (Kuadrant) | `TODO` | `TODO` | `TODO` | `oc get packagemanifest` \| grep -i connectivity/kuadrant |
| Red Hat Developer Hub | `TODO` | `TODO` | `TODO` | `oc get packagemanifest rhdh -o jsonpath='{.status.channels[*].name}'` |

> The exact packagemanifest names depend on your catalog source; the commands
> above are starting points. Record what you actually find.
>
> **Idempotency:** Subscriptions will use `installPlanApproval: Manual` with a
> pinned `startingCSV` (the "Confirmed CSV" column above), so the same version
> installs on every run. Confirm each pinned CSV actually exists in your
> cluster's catalog before committing it.

## 3. Namespaces

| Purpose | Namespace | Notes |
|---------|-----------|-------|
| Argo CD / GitOps | `openshift-gitops` | created by the GitOps operator |
| Keycloak | `<showcase-keycloak>` | TODO confirm |
| Connectivity Link | `<showcase-connectivity>` | TODO confirm |
| Developer Hub | `<showcase-devhub>` | TODO confirm |
| Solutions deploy into | `showcase-*` | one per solution |

## 4. Identity — Keycloak

| Item | Value | Notes |
|------|-------|-------|
| Keycloak route/host | `<keycloak.apps.cluster.example.com>` | assigned after install |
| Realm name | `<showcase>` | base realm for the platform |
| Admin user | `<admin>` | password via Secret, NOT here |
| OIDC issuer URL | `<https://keycloak.../realms/showcase>` | used by RHDH + Connectivity Link |

### OIDC clients (IDs only — secrets applied idempotently, never here)

| Client ID | Used by | Type | Redirect URIs |
|-----------|---------|------|---------------|
| `<developer-hub>` | Developer Hub login | confidential | `<https://devhub.apps.../api/auth/oidc/handler/frame>` |
| `<connectivity-link>` | API auth policies | confidential / bearer | n/a |

## 5. API exposure — Connectivity Link

| Item | Value | Notes |
|------|-------|-------|
| GatewayClass | `TODO` | `oc get gatewayclass` |
| Shared Gateway name | `<showcase-gateway>` | namespace + listeners TODO |
| Gateway listener host | `<*.apps.cluster.example.com>` | wildcard or per-API |
| AuthPolicy → Keycloak issuer | (see OIDC issuer above) | how APIs validate tokens |

## 6. Catalog — Developer Hub

| Item | Value | Notes |
|------|-------|-------|
| Developer Hub route/host | `<devhub.apps.cluster.example.com>` | assigned after install |
| Catalog discovery method | `catalog-info.yaml` per solution | Backstage-native |
| Auth provider | Keycloak (OIDC) | uses the `developer-hub` client above |

## 7. Git

| Item | Value | Notes |
|------|-------|-------|
| This repo URL | `<https://github.com/YOUR_USERNAME/showcase-app-platform.git>` | Argo CD root app sources this |
| Default branch | `main` | targetRevision |

---

## Open decisions / notes

Use this space to jot decisions made while exploring the environment
(e.g. "chose channel X because Y", "cluster lacks default StorageClass, using Z").

- TODO
