#!/usr/bin/env bash
#
# render-keycloak-realm.sh — render the realm template with local secrets and
# apply it idempotently. The rendered manifest is written to a gitignored temp
# file and never committed.
#
# Usage:
#   cp foundation/keycloak/secret.env.example foundation/keycloak/secret.env
#   # edit secret.env with real values
#   ./scripts/render-keycloak-realm.sh
#
# Re-runnable: uses `oc apply`, so running again converges (idempotent).

set -euo pipefail

KC_DIR="foundation/keycloak"
TPL="$KC_DIR/realm.yaml.tpl"
SECRET_ENV="$KC_DIR/secret.env"
RENDERED="$KC_DIR/.realm.rendered.yaml"   # gitignored

if [[ ! -f "$TPL" ]]; then
  echo "Template not found: $TPL (run from repo root)" >&2; exit 1
fi
if [[ ! -f "$SECRET_ENV" ]]; then
  echo "Missing $SECRET_ENV." >&2
  echo "Create it: cp $KC_DIR/secret.env.example $SECRET_ENV  (then edit)" >&2
  exit 1
fi

# Load the secret values
set -a
# shellcheck disable=SC1090
source "$SECRET_ENV"
set +a

# Fail early if any required var is empty
for v in SHOWCASE_ADMIN_PASSWORD SHOWCASE_USER_PASSWORD; do
  if [[ -z "${!v:-}" || "${!v}" == replace* ]]; then
    echo "Set a real value for $v in $SECRET_ENV" >&2; exit 1
  fi
done

# Render only the known vars. Prefer envsubst; fall back to sed if it's not
# installed (envsubst ships with gettext, which isn't always present on macOS).
export SHOWCASE_ADMIN_PASSWORD SHOWCASE_USER_PASSWORD
if command -v envsubst >/dev/null 2>&1; then
  envsubst '${SHOWCASE_ADMIN_PASSWORD} ${SHOWCASE_USER_PASSWORD}' \
    < "$TPL" > "$RENDERED"
else
  # Pure-sed fallback: substitute exactly the two known variables.
  esc() { printf '%s' "$1" | sed -e 's/[&/\]/\\&/g'; }
  sed \
    -e "s/\${SHOWCASE_ADMIN_PASSWORD}/$(esc "$SHOWCASE_ADMIN_PASSWORD")/g" \
    -e "s/\${SHOWCASE_USER_PASSWORD}/$(esc "$SHOWCASE_USER_PASSWORD")/g" \
    "$TPL" > "$RENDERED"
fi

echo "Rendered -> $RENDERED (gitignored)"
echo "Applying realm import..."
oc apply -f "$RENDERED"
echo "Done. The rendered file contains secrets; it stays local and gitignored."
