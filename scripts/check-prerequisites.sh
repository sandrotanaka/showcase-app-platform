#!/usr/bin/env bash
#
# check-prerequisites.sh — read-only pre-install check for phase 1
# (GitOps + Keycloak + Developer Hub).
#
# Inspects the cluster and reports whether it is ready to receive the
# foundation. It NEVER installs or changes anything — safe to run repeatedly.
#
# Usage:
#   oc login ...
#   ./scripts/check-prerequisites.sh
#
# Exit code: 0 if all required checks pass, 1 if any required check fails.
# Pinned versions come from scripts/foundation-versions.env (single source).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERS_FILE="$SCRIPT_DIR/foundation-versions.env"

# --- output helpers -------------------------------------------------------
if [[ -t 1 ]]; then
  G=$'\e[32m'; R=$'\e[31m'; Y=$'\e[33m'; B=$'\e[1m'; N=$'\e[0m'
else
  G=""; R=""; Y=""; B=""; N=""
fi
FAILED=0
pass() { printf "  ${G}PASS${N}  %s\n" "$1"; }
fail() { printf "  ${R}FAIL${N}  %s\n" "$1"; [[ -n "${2:-}" ]] && printf "        ${Y}-> %s${N}\n" "$2"; FAILED=1; }
warn() { printf "  ${Y}WARN${N}  %s\n" "$1"; }
head() { printf "\n${B}%s${N}\n" "$1"; }

# --- load pinned versions -------------------------------------------------
if [[ ! -f "$VERS_FILE" ]]; then
  echo "Cannot find $VERS_FILE" >&2; exit 1
fi
# shellcheck disable=SC1090
source "$VERS_FILE"

printf "${B}Prerequisite check — showcase-app-platform (phase 1)${N}\n"
printf "GitOps + Keycloak + Developer Hub\n"

# --- §1 cluster basics ----------------------------------------------------
head "1. Cluster access & basics"

if ! command -v oc >/dev/null 2>&1; then
  fail "oc CLI not found in PATH" "Install the OpenShift CLI (oc)"
  echo; echo "Cannot continue without oc."; exit 1
fi
pass "oc CLI found"

if oc whoami >/dev/null 2>&1; then
  pass "Logged in to a cluster"
else
  fail "Not logged in" "Run 'oc login ...' first"
  echo; echo "Cannot continue without a session."; exit 1
fi

# OpenShift version >= MIN_OCP_MINOR (4.x)
OCP_VER="$(oc version -o json 2>/dev/null \
  | python3 -c 'import sys,json;print(json.load(sys.stdin).get("openshiftVersion",""))' 2>/dev/null)"
if [[ -n "$OCP_VER" ]]; then
  MINOR="$(echo "$OCP_VER" | cut -d. -f2)"
  if [[ "$MINOR" =~ ^[0-9]+$ ]] && (( MINOR >= MIN_OCP_MINOR )); then
    pass "OpenShift version $OCP_VER (>= 4.$MIN_OCP_MINOR)"
  else
    fail "OpenShift version $OCP_VER is below 4.$MIN_OCP_MINOR"
  fi
else
  warn "Could not determine OpenShift version (need python3, or check manually)"
fi

# Default StorageClass present
DEFAULT_SC="$(oc get storageclass -o jsonpath='{range .items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")]}{.metadata.name}{end}' 2>/dev/null)"
if [[ -n "$DEFAULT_SC" ]]; then
  pass "Default StorageClass: $DEFAULT_SC"
else
  fail "No default StorageClass found" "Set one as default, or solutions needing PVCs will fail"
fi

# cluster-admin (can create Subscriptions)
if oc auth can-i create subscriptions.operators.coreos.com -n openshift-operators >/dev/null 2>&1; then
  pass "Can create Subscriptions (operator install permitted)"
else
  fail "Insufficient permission to install operators" "Need cluster-admin for the foundation install"
fi

# --- §2 operator catalog: packages + pinned CSVs --------------------------
head "2. Operator catalog (pinned CSVs available)"

check_operator() {
  local label="$1" pkg="$2" chan="$3" csv="$4"
  if ! oc get packagemanifest "$pkg" >/dev/null 2>&1; then
    fail "$label: package '$pkg' not in catalog" "Confirm the catalog source is enabled on this cluster"
    return
  fi
  # channel exists?
  local channels
  channels="$(oc get packagemanifest "$pkg" -o jsonpath='{range .status.channels[*]}{.name}{"\n"}{end}' 2>/dev/null)"
  if ! grep -qx "$chan" <<<"$channels"; then
    fail "$label: channel '$chan' not found" "Available: $(echo "$channels" | tr '\n' ' ')"
    return
  fi
  # pinned CSV present as the channel's currentCSV?
  local current
  current="$(oc get packagemanifest "$pkg" -o jsonpath="{range .status.channels[?(@.name==\"$chan\")]}{.currentCSV}{end}" 2>/dev/null)"
  if [[ "$current" == "$csv" ]]; then
    pass "$label: $chan -> $csv"
  else
    warn "$label: channel '$chan' currentCSV is '$current', pinned is '$csv'"
    printf "        ${Y}-> the pinned CSV may not be the channel head; verify it still installs, or update the pin${N}\n"
  fi
}

check_operator "GitOps"        "$GITOPS_PACKAGE"   "$GITOPS_CHANNEL"   "$GITOPS_CSV"
check_operator "Keycloak (RHBK)" "$KEYCLOAK_PACKAGE" "$KEYCLOAK_CHANNEL" "$KEYCLOAK_CSV"
check_operator "Developer Hub" "$RHDH_PACKAGE"     "$RHDH_CHANNEL"     "$RHDH_CSV"

# --- summary --------------------------------------------------------------
head "Summary"
if (( FAILED == 0 )); then
  printf "  ${G}All required checks passed.${N} Cluster looks ready for phase 1.\n"
  exit 0
else
  printf "  ${R}One or more required checks failed.${N} Resolve the items above before installing.\n"
  exit 1
fi
