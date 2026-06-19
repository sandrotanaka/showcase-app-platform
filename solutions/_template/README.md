# <solution-name>

> Copy this folder to start a solution: `cp -r solutions/_template solutions/<name>`,
> replace every `<placeholder>`, and delete this quote block.

One paragraph: **what this solution demonstrates** and the concept a reader
should walk away understanding.

## Requisites

### Config (non-secret) — via ConfigMap

| Key | Purpose | Required | Default | Example |
|-----|---------|----------|---------|---------|
| `<KEY>` | ... | no | `...` | `...` |

### Secrets — via `oc create secret`, never in Git

| Key | Purpose | How to provide |
|-----|---------|----------------|
| `<KEY>` | ... | `oc create secret generic ...` |

### Cluster prerequisites

| Prerequisite | Why | How to install |
|--------------|-----|----------------|
| _(none beyond the foundation)_ | — | — |

### Foundation integrations

How this solution plugs into the platform. This is the part unique to `showcase`.

| Foundation service | How this solution uses it | Values needed |
|--------------------|---------------------------|---------------|
| **Keycloak** | e.g. authenticates users via realm `showcase`, client `<client-id>` | issuer URL, client ID (ENVIRONMENT 4) |
| **Connectivity Link** | e.g. API exposed via shared Gateway, protected by an AuthPolicy | Gateway name, listener host (ENVIRONMENT 5) |
| **Developer Hub** | registered in the catalog via `catalog-info.yaml` | RHDH host (ENVIRONMENT 6) |

### Depends on other solutions

| Solution | Why | Setup order |
|----------|-----|-------------|
| _(none)_ | — | — |

## Catalog entry

This solution includes a `catalog-info.yaml` so it appears in Developer Hub.

## Deploy

> Finalized once the GitOps delivery mechanism is in place. Sketch:

```bash
oc new-project showcase-<name>
# supply externalized config/secrets
oc apply -k kustomize/         # or via the GitOps Application
oc get route -n showcase-<name>
```
