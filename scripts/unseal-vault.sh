#!/bin/bash

# This script unseals the OpenBao Vault server.

# Check if the required environment variables are set
if [[ -z "$VAULT_ADDR" || -z "$VAULT_UNSEAL_KEY" ]]; then
  echo "Error: VAULT_ADDR and VAULT_UNSEAL_KEY must be set."
  exit 1
fi

# Unseal the Vault server
echo "Unsealing the Vault server at $VAULT_ADDR..."
vault operator unseal "$VAULT_UNSEAL_KEY"

if [ $? -eq 0 ]; then
  echo "Vault server unsealed successfully."
else
  echo "Failed to unseal the Vault server."
  exit 1
fi