#!/bin/bash

# Script to create Docker Hub credentials secret
# Usage: ./create-docker-secret.sh <username> <password-or-token>

if [ $# -ne 2 ]; then
    echo "Usage: $0 <docker-username> <docker-password-or-token>"
    echo "Example: $0 boyroywax your-docker-hub-token"
    exit 1
fi

DOCKER_USERNAME=$1
DOCKER_PASSWORD=$2
NAMESPACE="openbao-vault-dedicated"

echo "🔐 Creating Docker Hub credentials secret..."

# Create the namespace first if it doesn't exist
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Delete existing secret if it exists
kubectl delete secret docker-registry-secret -n ${NAMESPACE} --ignore-not-found=true

# Create the Docker registry secret
kubectl create secret docker-registry docker-registry-secret \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username=${DOCKER_USERNAME} \
    --docker-password=${DOCKER_PASSWORD} \
    --namespace=${NAMESPACE}

if [ $? -eq 0 ]; then
    echo "✅ Docker registry secret created successfully in namespace '${NAMESPACE}'"
    echo "🔍 Verifying secret:"
    kubectl get secret docker-registry-secret -n ${NAMESPACE}
else
    echo "❌ Failed to create Docker registry secret"
    exit 1
fi

echo ""
echo "💡 You can now deploy your OpenBao vault with:"
echo "   helm upgrade openbao-vault-dedicated . -f values/openbao-vault-dedicated.yaml -n openbao-vault-dedicated"
