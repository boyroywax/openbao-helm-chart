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
TOKEN_TTL="30m"
VALUES_FILES=()
VAULT_ADDR_OVERRIDE="${VAULT_ADDR:-http://openbao-vault-service:8200}"
JOB_VAULT_ADDR=""
CLEANUP_SECRET=false
KEEP_TOKEN=false

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [options]

Creates a short-lived Vault token with permissions to disable the userpass auth
method, stores it in a Kubernetes secret, renders the userpass-disable Helm Job,
executes it, and waits for completion.

Required environment:
  VAULT_TOKEN or VAULT_ROOT_TOKEN   Privileged token capable of managing auth methods
  VAULT_ADDR                        (optional) Vault address; overridable via --vault-addr

Options:
  -n, --namespace <name>        Kubernetes namespace (default: openbao-vault)
  -r, --release <name>          Helm release name (default: openbao-vault)
  -c, --chart <path>            Path to Helm chart (default: ../charts/openbao-vault)
  -m, --mount-path <path>       Auth mount path to disable (default: userpass)
  -s, --secret-name <name>      Kubernetes secret name for the bootstrap token (default: vault-bootstrap-token)
      --vault-addr <addr>       Vault address for policy/token creation (default: env VAULT_ADDR or http://openbao-vault-service:8200)
      --job-vault-addr <addr>   Vault address for the disable job (default: same as --vault-addr)
      --token-ttl <ttl>         TTL for generated token (default: 30m)
      --wait <seconds>          Timeout (seconds) when waiting for the job to finish (default: 600)
  -f, --values <file>           Additional Helm values file (can be supplied multiple times)
      --cleanup-secret          Delete the Kubernetes secret after the job finishes
      --keep-token              Do NOT revoke the generated token after the job
  -h, --help                    Show this help message

Example:
  export VAULT_ROOT_TOKEN=...
  ./scripts/run-userpass-disable.sh \
    --mount-path userpass-admin \
    --cleanup-secret
EOF
}

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
    --wait)
      [[ $# -lt 2 ]] && { echo "error: missing value for $1" >&2; exit 1; }
      WAIT_TIMEOUT="$2"; shift 2 ;;
    -f|--values)
      [[ $# -lt 2 ]] && { echo "error: missing value for $1" >&2; exit 1; }
      VALUES_FILES+=("$2"); shift 2 ;;
    --cleanup-secret)
      CLEANUP_SECRET=true; shift ;;
    --keep-token)
      KEEP_TOKEN=true; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "error: unknown option $1" >&2
      usage
      exit 1 ;;
  esac
done

for cmd in vault kubectl helm jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command '$cmd' not found in PATH" >&2
    exit 1
  fi
done

export VAULT_ADDR="$VAULT_ADDR_OVERRIDE"
if [[ -n "${VAULT_ROOT_TOKEN:-}" ]]; then
  export VAULT_TOKEN="$VAULT_ROOT_TOKEN"
elif [[ -z "${VAULT_TOKEN:-}" ]]; then
  echo "error: set VAULT_ROOT_TOKEN or VAULT_TOKEN with sufficient privileges" >&2
  exit 1
fi

JOB_VAULT_ADDR=${JOB_VAULT_ADDR:-$VAULT_ADDR}

echo "▶ Checking Vault connectivity at $VAULT_ADDR"
vault status >/dev/null 2>&1 || { echo "error: unable to reach Vault" >&2; exit 1; }

SANITIZED_MOUNT=${MOUNT_PATH////-}
POLICY_NAME="userpass-disable-${SANITIZED_MOUNT}"
POLICY_FILE=$(mktemp)
VALUES_TMP=$(mktemp)
JOB_MANIFEST=$(mktemp)
CURRENT_VALUES=""

cleanup() {
  rm -f "$POLICY_FILE" "$VALUES_TMP" "$JOB_MANIFEST"
  [[ -n "$CURRENT_VALUES" ]] && rm -f "$CURRENT_VALUES"
}
trap cleanup EXIT

cat <<EOF > "$POLICY_FILE"
path "sys/auth" {
  capabilities = ["read", "list"]
}
path "sys/auth/${MOUNT_PATH}" {
  capabilities = ["read", "update", "delete", "sudo"]
}
path "sys/auth/${MOUNT_PATH}/*" {
  capabilities = ["read", "update", "delete", "sudo"]
}
EOF

echo "▶ Writing policy '$POLICY_NAME'"
vault policy write "$POLICY_NAME" "$POLICY_FILE"

echo "▶ Minting disable token (ttl=${TOKEN_TTL})"
TOKEN_JSON=$(vault token create -policy="$POLICY_NAME" -orphan=true -ttl="$TOKEN_TTL" -format=json)
DISABLE_TOKEN=$(echo "$TOKEN_JSON" | jq -r '.auth.client_token')

if [[ -z "$DISABLE_TOKEN" || "$DISABLE_TOKEN" == "null" ]]; then
  echo "error: failed to create disable token" >&2
  exit 1
fi

echo "▶ Creating/updating secret '$SECRET_NAME' in namespace '$NAMESPACE'"
kubectl -n "$NAMESPACE" create secret generic "$SECRET_NAME" \
  --from-literal=token="$DISABLE_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

{
  echo "userpassDisable:"
  echo "  enabled: true"
  echo "  mountPath: ${MOUNT_PATH}"
  echo "  vaultAddr: \"${JOB_VAULT_ADDR}\""
  echo "  waitTimeoutSeconds: ${WAIT_TIMEOUT}"
  echo "  tokenSecret:"
  echo "    name: ${SECRET_NAME}"
  echo "    key: token"
} > "$VALUES_TMP"

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

HELM_ARGS=(helm template "$RELEASE" "$CHART_PATH" -n "$NAMESPACE" --show-only templates/userpass-disable-job.yaml)
if [[ -n "$CURRENT_VALUES" ]]; then
  HELM_ARGS+=(-f "$CURRENT_VALUES")
fi
for values_file in "${VALUES_FILES[@]}"; do
  HELM_ARGS+=(-f "$values_file")
done
HELM_ARGS+=(-f "$VALUES_TMP")

"${HELM_ARGS[@]}" > "$JOB_MANIFEST"

if [[ ! -s "$JOB_MANIFEST" ]]; then
  echo "error: rendered job manifest is empty" >&2
  exit 1
fi

echo "▶ Applying userpass disable job"
APPLY_OUTPUT=$(kubectl apply -f "$JOB_MANIFEST" -o name)
JOB_NAME=${APPLY_OUTPUT##*/}
[[ -z "$JOB_NAME" ]] && JOB_NAME="userpass-disable-${VAULT_NAME}"

set +e
kubectl -n "$NAMESPACE" wait --for=condition=complete "job/${JOB_NAME}" --timeout="${WAIT_TIMEOUT}s"
WAIT_STATUS=$?
set -e

kubectl -n "$NAMESPACE" logs "job/${JOB_NAME}" -c userpass-disable --tail=-1 || true

if [[ $WAIT_STATUS -ne 0 ]]; then
  echo "error: disable job '${JOB_NAME}' did not complete successfully" >&2
  kubectl -n "$NAMESPACE" describe job "$JOB_NAME" >&2 || true
  if ! $KEEP_TOKEN; then
    vault token revoke "$DISABLE_TOKEN" >/dev/null 2>&1 || true
  fi
  exit $WAIT_STATUS
fi

echo "✅ Userpass disable job completed"

if $CLEANUP_SECRET; then
  echo "🧹 Deleting secret '${SECRET_NAME}'"
  kubectl -n "$NAMESPACE" delete secret "$SECRET_NAME" --ignore-not-found
fi

if ! $KEEP_TOKEN; then
  echo "🔁 Revoking bootstrap token"
  vault token revoke "$DISABLE_TOKEN" >/dev/null 2>&1 || echo "warning: failed to revoke token" >&2
fi

echo "Vault policy: ${POLICY_NAME}"

echo "⚠️  Consider removing userpassDisable.enabled from your values to prevent future runs."
