# Service Mesh (control plane)

Foundation component: Red Hat OpenShift Service Mesh 3 (Sail-based operator),
delivered by Argo CD as a child of the `showcase-root` App-of-Apps.

The child Application lives at `foundation/apps/service-mesh-app.yaml` (the root
watches `foundation/apps/`); the manifests it syncs live here under `manifests/`.

## What this installs

| Wave | Resource | Namespace | Purpose |
|------|----------|-----------|---------|
| 0 | `Subscription servicemeshoperator3` | `openshift-operators` | Operator, pinned to `v3.1.0`, Manual approval |
| 1 | `Namespace istio-cni` | — | Project for the CNI node DaemonSet |
| 1 | `Namespace istio-system` | — | Control plane project (istiod) |
| 2 | `IstioCNI/default` | `istio-cni` | CNI plugin |
| 2 | `Istio/default` | `istio-system` | Control plane |

Waves above order resources **within** this Application. At the foundation level
the Application itself is sync-wave `1` (shared network infra, ahead of
Keycloak's wave `2`).

This component provides **only** the shared mesh control plane. Demo workloads
and gateways are separate solutions that consume the mesh; they are not added
here (growth by addition).

## Scope boundary

The Istio resource is named `default`, so member namespaces opt in with the
`istio-injection=enabled` label. Exposure for future demos uses the **Gateway
API** (GatewayClass `openshift-default`), chosen to align with the planned
Connectivity Link / Kuadrant phase-2 layer, whose policies (AuthPolicy,
RateLimitPolicy) attach to Gateway API resources.

## First-sync note (Manual approval)

Because approval is Manual, the operator InstallPlan must be approved once
before the `Istio` / `IstioCNI` CRs can reconcile. Argo's retry backoff keeps
the child app pending until then. Approve with:

    oc -n openshift-operators get installplan
    oc -n openshift-operators patch installplan <name> --type merge -p '{"spec":{"approved":true}}'

Confirm health:

    oc get istio default
    oc get istiocni default
    oc -n istio-cni get daemonset istio-cni-node
