# showcase-app-platform

A GitOps-delivered platform on OpenShift that **installs a shared foundation
from scratch** — Keycloak, Connectivity Link, and Developer Hub — and then
incorporates solutions on top of it, with the structure to keep growing.

> **Status: initial repository.** This phase captures the environment and the
> design. It contains documentation and the skeleton; the foundation manifests
> and the worked example solution are added in later phases.

## The ideal scenario

| Layer | Component | Role |
|-------|-----------|------|
| Platform | **OpenShift** | the cluster (assumed present) |
| Delivery | **GitOps** (OpenShift GitOps / Argo CD) | reconciles everything from Git |
| Identity | **Keycloak** (RHBK) | realm + OIDC clients; the auth anchor |
| API exposure | **Connectivity Link** (Kuadrant) | shared Gateway + AuthPolicy |
| Catalog | **Developer Hub** (RHDH) | portal where solutions register |
| On top | **Solutions** | incorporated on the foundation; grows over time |

See [docs/architecture.md](docs/architecture.md) for the layered diagram and the
install-ordering (sync waves) rationale.

## Start here

1. **Record your environment.** Copy the template to a local, gitignored fact
   sheet and fill *that* in — never the template:
   `cp docs/ENVIRONMENT.example.md docs/ENVIRONMENT.local.md`. It holds your
   cluster's identifiers (hosts, namespaces, realm, client IDs); true secrets go
   in a local `secret.env`, not even there. Nothing sensitive is committed —
   see [data classification](docs/architecture.md#data-classification).
2. **Read the design.** [docs/architecture.md](docs/architecture.md).
3. **Browse the skeleton.** [foundation/](foundation/) (one folder per component,
   each with a README describing what it will contain and its sync wave) and
   [solutions/](solutions/) (the `_template/` future solutions copy).

## Layout

```
showcase-app-platform/
├── README.md
├── LICENSE
├── .gitignore                     # blocks real .env/secret values; keeps *.example
├── docs/
│   ├── ENVIRONMENT.example.md      # versioned template (placeholders only)
│   ├── ENVIRONMENT.local.md        # YOUR real values (gitignored, never pushed)
│   └── architecture.md            # layered design + install ordering
├── foundation/                    # shared services, installed once (skeleton for now)
│   ├── README.md
│   ├── gitops/                    # delivery mechanism (Argo CD)
│   ├── keycloak/                  # identity (wave 2)
│   ├── connectivity-link/         # API exposure/auth (wave 3)
│   └── developer-hub/             # catalog/portal (wave 4)
└── solutions/                     # incorporated on top of the foundation
    ├── README.md
    └── _template/                 # copy to start a new solution
```

## Principles

- **GitOps-delivered** - Git is the source of truth; the root app is applied once.
- **Externalize everything** - no environment-specific values or secrets in Git;
  config via ConfigMaps, secrets applied idempotently (dry-run | apply). Deployment is idempotent — see docs/architecture.md.
- **Portable** - no hardcoded Route hosts, no named StorageClass, public images.
- **Grows by addition** - new solutions copy `_template/` and declare their
  foundation integrations in a requisites contract.

## License

MIT - see [LICENSE](LICENSE).
