# solutions/

Solutions incorporated **on top of the foundation**. Each is self-contained,
delivered by GitOps, and declares how it integrates with the foundation
(Keycloak for identity, Connectivity Link for exposure, Developer Hub for the
catalog).

This initial repo ships only the **`_template/`** that future solutions copy.
Real solutions (and the worked example) are added once the foundation manifests
exist.

## Adding a solution (once the platform is up)

1. `cp -r solutions/_template solutions/<name>`
2. Fill in its README requisites contract — including the **foundation
   integrations** (which realm/client, which Gateway/AuthPolicy, catalog entry).
3. Add its manifests + `catalog-info.yaml`.
4. Register it for delivery (GitOps) — mechanism finalized in a later phase.

Every solution starts from the same template, so the repo stays uniform as it
grows.
