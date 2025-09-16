# Policy for layer-core-api service
# Allows management of user AI API keys under secret/layer-core-api/

# Allow listing secrets under the layer-core-api path
path "secret/metadata/layer-core-api/*" {
  capabilities = ["list"]
}

# Allow full CRUD operations on user AI API keys
path "secret/data/layer-core-api/users/+/api-keys/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Allow reading metadata for user API keys
path "secret/metadata/layer-core-api/users/+/api-keys/*" {
  capabilities = ["read", "list"]
}

# Allow managing API key configurations
path "secret/data/layer-core-api/config/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Allow reading own token information
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Allow renewing own token
path "auth/token/renew-self" {
  capabilities = ["update"]
}
