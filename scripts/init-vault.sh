#!/bin/bash

# This script initializes the OpenBao Vault server.

# Set the Vault address and token
export VAULT_ADDR='http://localhost:8200'
export VAULT_TOKEN='your-vault-token'

# Initialize the Vault server
echo "Initializing Vault..."
vault operator init -key-shares=5 -key-threshold=3 > /tmp/vault-init-output.txt

# Extract unseal keys and root token
echo "Extracting unseal keys and root token..."
UNSEAL_KEYS=$(grep 'Unseal Key' /tmp/vault-init-output.txt | awk '{print $NF}')
ROOT_TOKEN=$(grep 'Initial Root Token' /tmp/vault-init-output.txt | awk '{print $NF}')

# Unseal the Vault server
echo "Unsealing Vault..."
for key in $UNSEAL_KEYS; do
    vault operator unseal $key
done

# Store the root token securely (consider using a secret management solution)
echo "Root Token: $ROOT_TOKEN"
echo "Please store this root token securely!"

# Clean up
rm /tmp/vault-init-output.txt

echo "Vault initialization complete."