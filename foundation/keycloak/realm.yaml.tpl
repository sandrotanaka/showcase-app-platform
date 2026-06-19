# Realm + OIDC client + test users — TEMPLATE (processed by render script).
#
# This is a TEMPLATE, not a ready manifest. The ${VARS} below (test-user
# passwords only) are filled from a local, gitignored secret.env by
# scripts/render-keycloak-realm.sh, which then applies the result. The rendered
# manifest is NEVER committed — only this template (placeholders) lives in Git.
#
# CLIENT SECRET = FORM 2 (Keycloak-generated): the developer-hub client does NOT
# carry a secret here. With no `secret` field, Keycloak generates one itself and
# the operator exposes it as a Kubernetes Secret in showcase-keycloak. Developer
# Hub later reads that generated Secret. So the client secret never touches Git
# or your machine — only test-user passwords go through the template.
#
# ⚠️ VERSION-SENSITIVE (RHBK 26): confirm KeycloakRealmImport field names against
# your operator version.
#
# Variables required (see secret.env.example):
#   SHOWCASE_ADMIN_PASSWORD, SHOWCASE_USER_PASSWORD
apiVersion: k8s.keycloak.org/v2alpha1
kind: KeycloakRealmImport
metadata:
  name: showcase-realm
  namespace: showcase-keycloak
  annotations:
    argocd.argoproj.io/sync-wave: "1"
spec:
  keycloakCRName: showcase
  realm:
    realm: showcase
    enabled: true
    displayName: Showcase App Platform

    clients:
      - clientId: developer-hub
        name: Developer Hub
        enabled: true
        protocol: openid-connect
        publicClient: false
        standardFlowEnabled: true
        # Redirect URIs: RHDH host is known only after Developer Hub installs.
        # Broad wildcard for the showcase; tighten in production and record the
        # exact host in ENVIRONMENT.local §4.
        redirectUris:
          - "https://*/api/auth/oidc/handler/frame"
        webOrigins:
          - "+"
        # NO `secret` field on purpose (Form 2): Keycloak generates the client
        # secret. The operator publishes it as a Secret named
        # keycloak-client-secret-developer-hub in showcase-keycloak. Developer
        # Hub reads it from there. Confirm the generated Secret name on your
        # version with:
        #   oc get secret -n showcase-keycloak | grep developer-hub

    users:
      - username: showcase-admin
        enabled: true
        emailVerified: true
        firstName: Showcase
        lastName: Admin
        email: showcase-admin@example.com
        realmRoles:
          - default-roles-showcase
        credentials:
          - type: password
            value: "${SHOWCASE_ADMIN_PASSWORD}"
            temporary: false
      - username: showcase-user
        enabled: true
        emailVerified: true
        firstName: Showcase
        lastName: User
        email: showcase-user@example.com
        realmRoles:
          - default-roles-showcase
        credentials:
          - type: password
            value: "${SHOWCASE_USER_PASSWORD}"
            temporary: false
