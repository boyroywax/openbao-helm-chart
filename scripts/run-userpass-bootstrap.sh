#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEFAULT_CHART_PATH="${SCRIPT_DIR}/../charts/openbao-vault"
SCRIPT_NAME=$(basename "$0")

NAMESPACE="openbao-vault"
RELEASE="openbao-vault"
CHART_PATH="$DEFAULT_CHART_PATH"
MOUNT_PATH="userpass"
SECRET_NAME="vault-bootstrap-token"
WAIT_TIMEOUT="600"
TOKEN_TTL="1h"
USERS_FILE=""
VALUES_FILES=()
VAULT_ADDR_OVERRIDE="${VAULT_ADDR:-http://openbao-vault-service:8200}"
JOB_VAULT_ADDR=""

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [options]

This script mints a limited-privilege token for bootstrapping the userpass auth method,
stores it in a Kubernetes Secret, and executes the userpass bootstrap Job from the
openbao-vault Helm chart.

Required environment:
  VAULT_TOKEN or VAULT_ROOT_TOKEN   Privileged token with capability to manage auth methods
  VAULT_ADDR                        (optional) Vault address; can also be supplied with --vault-addr

Options:
  -n, --namespace <name>        Kubernetes namespace (default: openbao-vault)
  -r, --release <name>          Helm release name (default: openbao-vault)
  -c, --chart <path>            Path to Helm chart (default: ../charts/openbao-vault)
  -m, --mount-path <path>       Auth mount path to enable (default: userpass)
  -s, --secret-name <name>      Kubernetes secret name for the bootstrap token (default: vault-bootstrap-token)
      --vault-addr <addr>       Vault address for policy/token creation (default: env VAULT_ADDR or http://openbao-vault-service:8200)
      --job-vault-addr <addr>   Vault address the bootstrap job should use (default: same as --vault-addr)
      --token-ttl <ttl>         TTL for generated bootstrap token (default: 1h)
      --users-file <path>       YAML file containing a list of users to seed (list items, no "users:" key)
    --wait <seconds>          Timeout (seconds) when waiting for the job to finish (default: 600)
  -f, --values <file>           Additional Helm values file (can be specified multiple times)
  -h, --help                    Show this help message

Examples:
  export VAULT_ROOT_TOKEN=... ; \
  ${SCRIPT_NAME} --release openbao-vault --namespace openbao-vault \
    --mount-path userpass-admin --users-file ./bootstrap-users.yaml

EOF
}

# Argument parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--namespace)
      [[ $# -lt 2 ]] && { echo "error: missing value for $1" >&2; exit 1; }
      NAMESPACE="$2"; shift 2 ;;
    -r|--release)
      [[ $# -lt 2 ]] && { echo "error: missing value for $1" >&2; exit 1; }
      RELEASE="$2"; shift 2 ;;
    -c|--chart)
      [[ $# -lt 2 ]] && { echo "error: missing value for $1" >&2; exit 1; }
      CHART_PATH="$2"; shift 2 ;;
    -m|--mount-path)
      [[ $# -lt 2 ]] && { echo "error: missing value for $1" >&2; exit 1; }
      MOUNT_PATH="$2"; shift 2 ;;
    -s|--secret-name)
      [[ $# -lt 2 ]] && { echo "error: missing value for $1" >&2; exit 1; }
      SECRET_NAME="$2"; shift 2 ;;
    --vault-addr)
      [[ $# -lt 2 ]] && { echo "error: missing value for $1" >&2; exit 1; }
      VAULT_ADDR_OVERRIDE="$2"; shift 2 ;;
    --job-vault-addr)
      [[ $# -lt 2 ]] && { echo "error: missing value for $1" >&2; exit 1; }
      JOB_VAULT_ADDR="$2"; shift 2 ;;
    --token-ttl)
      [[ $# -lt 2 ]] && { echo "error: missing value for $1" >&2; exit 1; }
      TOKEN_TTL="$2"; shift 2 ;;
    --users-file)
      [[ $# -lt 2 ]] && { echo "error: missing value for $1" >&2; exit 1; }
      USERS_FILE="$2"; shift 2 ;;
    --wait)
      [[ $# -lt 2 ]] && { echo "error: missing value for $1" >&2; exit 1; }
      WAIT_TIMEOUT="$2"; shift 2 ;;
    -f|--values)
      [[ $# -lt 2 ]] && { echo "error: missing value for $1" >&2; exit 1; }
      VALUES_FILES+=("$2"); shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "error: unknown option $1" >&2
      usage
      exit 1 ;;
  esac
done

# Dependency checks
for cmd in vault kubectl helm jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command '$cmd' not found in PATH" >&2
    exit 1
  fi
done

if [[ -n "$USERS_FILE" && ! -f "$USERS_FILE" ]]; then
  echo "error: users file '$USERS_FILE' not found" >&2
  exit 1
fi

export VAULT_ADDR="$VAULT_ADDR_OVERRIDE"
if [[ -n "${VAULT_ROOT_TOKEN:-}" ]]; then
  export VAULT_TOKEN="$VAULT_ROOT_TOKEN"
elif [[ -z "${VAULT_TOKEN:-}" ]]; then
  echo "error: set VAULT_ROOT_TOKEN or VAULT_TOKEN with sufficient privileges" >&2
  exit 1
fi

JOB_VAULT_ADDR=${JOB_VAULT_ADDR:-$VAULT_ADDR}

echo "▶ Checking Vault connectivity at $VAULT_ADDR"
vault status >/dev/null 2>&1 || { echo "error: unable to reach Vault at $VAULT_ADDR" >&2; exit 1; }

SANITIZED_MOUNT=${MOUNT_PATH////-}
POLICY_NAME="userpass-bootstrap-${SANITIZED_MOUNT}"
POLICY_FILE=$(mktemp)
BOOTSTRAP_VALUES=$(mktemp)
JOB_MANIFEST=$(mktemp)
CURRENT_VALUES=""

cleanup() {
  rm -f "$POLICY_FILE" "$BOOTSTRAP_VALUES" "$JOB_MANIFEST"
  [[ -n "$CURRENT_VALUES" ]] && rm -f "$CURRENT_VALUES"
}
trap cleanup EXIT

cat <<EOF > "$POLICY_FILE"
path "sys/auth/${MOUNT_PATH}" {
  capabilities = ["create", "update", "delete", "sudo"]
}
path "sys/auth/${MOUNT_PATH}/*" {
  capabilities = ["create", "update", "delete", "sudo"]
}
path "auth/${MOUNT_PATH}/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF

echo "▶ Writing policy '$POLICY_NAME'"
vault policy write "$POLICY_NAME" "$POLICY_FILE"

echo "▶ Minting bootstrap token (ttl=${TOKEN_TTL})"
TOKEN_JSON=$(vault token create -policy="$POLICY_NAME" -orphan=true -ttl="$TOKEN_TTL" -format=json)
BOOTSTRAP_TOKEN=$(echo "$TOKEN_JSON" | jq -r '.auth.client_token')

if [[ -z "$BOOTSTRAP_TOKEN" || "$BOOTSTRAP_TOKEN" == "null" ]]; then
  echo "error: failed to create bootstrap token" >&2
  exit 1
fi

echo "▶ Creating/updating secret '$SECRET_NAME' in namespace '$NAMESPACE'"
kubectl -n "$NAMESPACE" create secret generic "$SECRET_NAME" \
  --from-literal=token="$BOOTSTRAP_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

{
  echo "userpassBootstrap:"
  echo "  enabled: true"
  echo "  mountPath: ${MOUNT_PATH}"
  echo "  vaultAddr: \"${JOB_VAULT_ADDR}\""
  echo "  waitTimeoutSeconds: ${WAIT_TIMEOUT}"
  echo "  tokenSecret:"
  echo "    name: ${SECRET_NAME}"
  echo "    key: token"
  if [[ -n "$USERS_FILE" ]]; then
    echo "  users:"
    sed 's/^/    /' "$USERS_FILE"
  else
    echo "  users: []"
  fi
} > "$BOOTSTRAP_VALUES"

VAULT_NAME="openbao"
if helm status "$RELEASE" -n "$NAMESPACE" >/dev/null 2>&1; then
  CURRENT_VALUES=$(mktemp)
  helm get values "$RELEASE" -n "$NAMESPACE" -o yaml > "$CURRENT_VALUES"
  VAULT_NAME=$(helm get values "$RELEASE" -n "$NAMESPACE" -o json | jq -r '.vault.name // "openbao" // empty')
  [[ -z "$VAULT_NAME" ]] && VAULT_NAME="openbao"
else
  echo "warning: Helm release '$RELEASE' not found. Using chart defaults." >&2
  FALLBACK_NAME=$(helm show values "$CHART_PATH" | awk '/^vault:/ {flag=1; next} flag && /^  name:/ {print $2; exit}')
  [[ -n "$FALLBACK_NAME" ]] && VAULT_NAME="$FALLBACK_NAME"
fi

HELM_ARGS=(helm template "$RELEASE" "$CHART_PATH" -n "$NAMESPACE" --show-only templates/userpass-bootstrap-job.yaml)
if [[ -n "$CURRENT_VALUES" ]]; then
  HELM_ARGS+=(-f "$CURRENT_VALUES")
fi
for values_file in "${VALUES_FILES[@]}"; do
  HELM_ARGS+=(-f "$values_file")
done
HELM_ARGS+=(-f "$BOOTSTRAP_VALUES")

"${HELM_ARGS[@]}" > "$JOB_MANIFEST"

if [[ ! -s "$JOB_MANIFEST" ]]; then
  echo "error: rendered job manifest is empty" >&2
  exit 1
fi

echo "▶ Applying userpass bootstrap job"
APPLY_OUTPUT=$(kubectl apply -f "$JOB_MANIFEST" -o name)
JOB_NAME=${APPLY_OUTPUT##*/}
[[ -z "$JOB_NAME" ]] && JOB_NAME="userpass-bootstrap-${VAULT_NAME}"

set +e
kubectl -n "$NAMESPACE" wait --for=condition=complete "job/${JOB_NAME}" --timeout="${WAIT_TIMEOUT}s"
WAIT_STATUS=$?
set -e

kubectl -n "$NAMESPACE" logs "job/${JOB_NAME}" -c userpass-bootstrap --tail=-1 || true

if [[ $WAIT_STATUS -ne 0 ]]; then
  echo "error: bootstrap job '${JOB_NAME}' did not complete successfully" >&2
  kubectl -n "$NAMESPACE" describe job "$JOB_NAME" >&2 || true
  exit $WAIT_STATUS
fi

echo "✅ Userpass bootstrap job completed successfully"
echo "Token TTL: ${TOKEN_TTL} (stored in secret ${SECRET_NAME})"
echo "Vault policy: ${POLICY_NAME}"

echo "⚠️  Remember to rotate or revoke the bootstrap token and disable the job in Helm values once finished."
