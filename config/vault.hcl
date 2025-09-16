# Configuration for OpenBao Vault Server

# Storage backend configuration
storage "file" {
  path = "/vault/data"
}

# Listener configuration
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

# Enable the UI
ui = true

# Default lease and renewal settings
default_lease_ttl = "1h"
max_lease_ttl = "24h"

# Enable audit logging
audit {
  type = "file"
  options = {
    path = "/vault/logs/audit.log"
    log_raw = true
  }
}

# Enable the secret engine
secrets "kv" {
  path = "secret"
}