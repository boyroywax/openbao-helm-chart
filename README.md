# OpenBao Vault Helm Chart

# OpenBao Helm Chart

A Helm chart for deploying OpenBao Vault server with NFS-backed storage on Kubernetes.

## Features

- Deploys OpenBao Vault server in a custom namespace
- Uses NFS server for persistent storage backed by DigitalOcean Block Storage
- Configurable ingress, service, and security policies
- Proper RBAC configuration
- Network policies for security

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- DigitalOcean Block Storage CSI driver (if using `do-block-storage`)

## Installation

### Basic Installation

```bash
# Install in the default openbao-vault namespace
helm install openbao-vault ./openbao-helm-chart

# Install with custom namespace
helm install openbao-vault ./openbao-helm-chart 
  --set namespace.name=my-vault-ns 
  --set namespace.create=true
```

### Configuration

The chart can be configured with the following values:

#### Namespace Configuration
```yaml
namespace:
  name: openbao-vault        # Namespace name
  create: true               # Whether to create the namespace
```

#### Vault Configuration
```yaml
image:
  repository: openbao/vault
  tag: latest
  pullPolicy: IfNotPresent

service:
  enabled: true
  type: ClusterIP
  port: 8200
  targetPort: 8200

vault:
  token: "myroot"           # Initial root token

vaultConfig: |             # Vault HCL configuration
  ui = true
  storage "file" {
    path = "/vault/file"
  }
  listener "tcp" {
    address = "0.0.0.0:8200"
    tls_disable = 1
  }
```

#### Storage Configuration
```yaml
persistence:
  enabled: true
  storageClass: "do-block-storage"
  accessModes:
    - ReadWriteMany
  size: 10Gi

# NFS Server subchart configuration
nfs-server:
  enabled: true
  storage:
    enabled: true
    storageClass: "do-block-storage"
    size: 10Gi
```

#### Ingress Configuration
```yaml
ingress:
  enabled: false
  host: vault.example.com
  path: /
  pathType: ImplementationSpecific
  tls:
    secretName: vault-tls
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

## Usage

### Access the Vault UI

After installation, you can access the Vault UI:

```bash
# Port forward to access locally
kubectl port-forward -n openbao-vault svc/openbao-vault-openbao 8200:8200

# Open in browser
open http://localhost:8200
```

### Initialize and Unseal Vault

```bash
# Get the pod name
POD_NAME=$(kubectl get pods -n openbao-vault -l "app.kubernetes.io/name=openbao" -o jsonpath="{.items[0].metadata.name}")

# Initialize the vault
kubectl exec -n openbao-vault -it $POD_NAME -- vault operator init

# Unseal the vault (repeat with different unseal keys)
kubectl exec -n openbao-vault -it $POD_NAME -- vault operator unseal <unseal-key-1>
kubectl exec -n openbao-vault -it $POD_NAME -- vault operator unseal <unseal-key-2>
kubectl exec -n openbao-vault -it $POD_NAME -- vault operator unseal <unseal-key-3>
```

### Using with Different Namespaces

You can deploy multiple Vault instances in different namespaces:

```bash
# Deploy production vault
helm install vault-prod ./openbao-helm-chart 
  --set namespace.name=vault-production 
  --set namespace.create=true 
  --set ingress.enabled=true 
  --set ingress.host=vault-prod.company.com

# Deploy development vault
helm install vault-dev ./openbao-helm-chart 
  --set namespace.name=vault-development 
  --set namespace.create=true 
  --set ingress.enabled=true 
  --set ingress.host=vault-dev.company.com
```

## Storage Architecture

This chart uses a two-tier storage approach:

1. **NFS Server**: Provides shared storage using DigitalOcean Block Storage
2. **Vault Storage**: Mounts the NFS share for persistent vault data

The NFS server is deployed as a subchart and automatically configured to work with the main OpenBao deployment.

## Security

- Vault runs as a non-root user
- RBAC policies are applied with minimal required permissions
- Network policies restrict traffic to necessary communications only
- Service accounts are created per deployment

## Troubleshooting

### Check deployment status
```bash
kubectl get all -n openbao-vault
```

### View logs
```bash
kubectl logs -n openbao-vault -l "app.kubernetes.io/name=openbao"
```

### Check persistent volumes
```bash
kubectl get pv,pvc -n openbao-vault
```

## Uninstallation

```bash
helm uninstall openbao-vault
```

Note: This will not automatically delete PVCs or the namespace. Delete them manually if needed:

```bash
kubectl delete pvc -n openbao-vault --all
kubectl delete namespace openbao-vault
``` 

## Prerequisites

- Kubernetes cluster (version 1.16 or later)
- Helm (version 3.0 or later)
- Access to DigitalOcean for block storage

## Installation

To install the OpenBao Vault server using this Helm chart, follow these steps:

1. **Clone the repository:**

   ```bash
   git clone https://github.com/your-repo/openbao-helm-chart.git
   cd openbao-helm-chart
   ```

2. **Configure your values:**

   Edit the `values.yaml` file to customize the deployment parameters, such as image repository, tag, service type, and storage settings.

3. **Install the chart:**

   ```bash
   helm install openbao ./openbao-helm-chart
   ```

4. **Verify the installation:**

   Check the status of the deployment:

   ```bash
   kubectl get pods
   ```

## Configuration

The following configuration options are available in the `values.yaml` file:

- `image.repository`: The container image repository for the OpenBao Vault server.
- `image.tag`: The container image tag.
- `service.type`: The type of service to create (e.g., ClusterIP, NodePort, LoadBalancer).
- `persistence.enabled`: Enable or disable persistent storage.
- `nfs.server`: The NFS server address.
- `nfs.path`: The path on the NFS server to use for storage.

## Usage

After installation, you can interact with the OpenBao Vault server using the provided scripts:

- `init-vault.sh`: Initializes the Vault server.
- `unseal-vault.sh`: Unseals the Vault server to access secrets.

## Notes

- Ensure that the NFS server is properly configured and accessible from your Kubernetes cluster.
- For more detailed configuration options, refer to the `values.yaml` file and the templates in the `templates` directory.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.