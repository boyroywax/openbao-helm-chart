# 🛡️ OpenBao Vault Helm Chart

A production-ready Helm chart for deploying OpenBao vault on Kubernetes with dedicated vault infrastructure, NFS persistent storage, and secure cluster-only access.

## 🎯 Features

- **Dedicated Vault Nodes**: Deploy vault on dedicated Kubernetes nodes with taints and node affinity
- **Persistent NFS Storage**: Secure data persistence usi# Test template rendering
helm template test-vault charts/openbao-vault \
  -f charts/openbao-vault/values/openbao-vault.yaml

# Dry run installation
helm install --dry-run test-release charts/openbao-vault \
  -f charts/openbao-vault/values/openbao-vault.yamlshared storage
- **Security-First**: Internal ClusterIP services with no external exposure by default
- **Production Ready**: Health checks, resource limits, and proper RBAC
- **High Availability**: Supports multi-node vault configurations
- **Kubernetes Native**: Designed specifically for Kubernetes environments

## 📋 Prerequisites

- Kubernetes cluster (1.19+)
- Helm 3.x
- StorageClass for dynamic provisioning (e.g., `do-block-storage` for DigitalOcean)
- kubectl configured with cluster access

## 🏗️ Node Setup and Labeling

### Dedicated Vault Node Configuration

For optimal security and performance, this chart supports dedicated nodes for vault deployment. Dedicated nodes prevent resource contention and provide better isolation for sensitive vault operations.

#### Step 1: Create or Label Nodes

**For DigitalOcean Kubernetes (DOKS):**
```bash
# Create a new node pool for vault
doctl kubernetes cluster node-pool create <cluster-name> \
  --name vault-nodes \
  --size s-4vcpu-8gb \
  --count 1 \
  --tag vault,secure

# Or label existing nodes
kubectl label node <node-name> node-role.kubernetes.io/vault=true
```

**For other Kubernetes platforms:**
```bash
# Label a node for vault deployment
kubectl label node <node-name> node-role.kubernetes.io/vault=true
```

#### Step 2: Add Node Taints (Recommended)

Taint nodes to ensure only vault workloads are scheduled:

```bash
# Taint nodes to dedicate them for vault workloads
kubectl taint node <vault-node> vault=dedicated:NoSchedule
```

#### Step 3: Verify Node Configuration

```bash
# Check node labels and taints
kubectl get nodes --show-labels
kubectl describe node <node-name>
```

### Supported Node Labels

The vault configuration expects specific node labels:

| Component | Node Label | Recommended Node Size |
|-----------|------------|----------------------|
| **OpenBao Vault** | `node-role.kubernetes.io/vault=true` | 4-8 CPU, 8-16GB RAM |

## 🚀 Quick Start

### 1. Deploy OpenBao Vault

Deploy the vault with dedicated configuration:

```bash
# Deploy OpenBao Vault
helm install openbao-vault ./charts/openbao-vault \
  --namespace openbao-vault \
  --values ./charts/openbao-vault/values/openbao-vault.yaml \
  --create-namespace
```

### 2. Check Deployment Status

```bash
# Check helm release
helm list --all-namespaces

# Monitor pod status
kubectl get pods -n openbao-vault

# Check services (note: ClusterIP only for security)
kubectl get svc -n openbao-vault
```

### 3. Access Your Vault (Internal Only)

The vault is configured for internal cluster access only:

```bash
# Port-forward to access vault locally
kubectl port-forward -n openbao-vault svc/openbao-vault 8200:8200

# Access vault at http://localhost:8200
# Use the vault CLI or web interface
```

### 4. Initialize and Unseal Vault

```bash
# Initialize the vault (first time only)
kubectl exec -n openbao-vault -it deployment/openbao-vault -- \
  bao operator init

# Unseal the vault (use keys from init output)
kubectl exec -n openbao-vault -it deployment/openbao-vault -- \
  bao operator unseal <unseal-key-1>

kubectl exec -n openbao-vault -it deployment/openbao-vault -- \
  bao operator unseal <unseal-key-2>

kubectl exec -n openbao-vault -it deployment/openbao-vault -- \
  bao operator unseal <unseal-key-3>
```

### 5. Test Your Deployment

```bash
# Check vault status
kubectl exec -n openbao-vault -it deployment/openbao-vault -- \
  bao status

# Or via port-forward and HTTP API
curl -s http://localhost:8200/v1/sys/health | jq
```

## 🔧 Configuration

### Available Values Files

The chart includes pre-configured values for different deployment scenarios:

**Vault Deployment:**
- `openbao-vault.yaml` - Production vault on vault nodes with security hardening

### Customization

You can override any values by creating your own values file or using `--set` flags:

```bash
helm install my-vault ./charts/openbao-vault \
  -f ./charts/openbao-vault/values/openbao-vault.yaml \
  --set vault.resources.limits.memory=16Gi \
  --set nfs.storage.size=50Gi
```

### Key Configuration Options

- **Node Selection**: Configure in `nodeSelector` and `tolerations`
- **Resource Limits**: Configure CPU/memory in `vault.resources` and `nfs.resources`
- **Storage Size**: Adjust `nfs.storage.size` based on vault data requirements
- **Security**: All services use ClusterIP for internal-only access
- **Namespace**: Configurable namespace for deployment isolation

## 🏗️ Architecture

Each deployment includes:

- **Namespace**: Isolated environment for vault deployment (`openbao-vault`)
- **NFS Server**: Persistent storage for vault data using `boyroywax/nfs-server:1.0.0`
- **OpenBao Vault**: Main vault service using `openbao/openbao:latest` (v2.4.1)
- **RBAC**: Proper ServiceAccount, ClusterRole, and ClusterRoleBinding for security
- **Services**: Internal ClusterIP services only (no external exposure)
- **ConfigMaps**: Configuration management for vault and NFS

## 📁 Project Structure

```
openbao-helm-chart/
├── README.md                           # This file - comprehensive documentation
├── CHANGELOG.md                        # Version history and release notes
├── CONTRIBUTING.md                     # Contribution guidelines
├── LICENSE                            # MIT license
├── create-docker-secret.sh            # Helper script for Docker registry secrets
├── .gitignore                         # Git ignore rules
└── charts/
    └── openbao-vault/                 # Main Helm chart
        ├── Chart.yaml                 # Chart metadata and version info
        ├── values.yaml                # Default values
        ├── .helmignore               # Helm ignore rules
        ├── values/
        │   └── openbao-vault-dedicated.yaml  # Production values for dedicated deployment
        └── templates/
            ├── _helpers.tpl           # Template helpers and functions
            ├── namespace.yaml         # Namespace creation
            ├── pv-creator-rbac.yaml   # RBAC for PV management
            ├── nfs-pv-creator.yaml    # Job to create NFS PersistentVolume
            ├── nfs-server.yaml        # NFS server deployment and service
            ├── storage.yaml           # PVC for vault data
            ├── deployment.yaml        # Main vault deployment and service
            ├── vault-init-job.yaml    # Optional vault initialization job
            └── ingress.yaml           # Ingress (disabled by default)
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. Pods Stuck in Pending State

**Symptoms:** Pods show `Pending` status
```bash
kubectl get pods -n openbao-vault
# NAME                                     READY   STATUS    RESTARTS   AGE
# openbao-vault-xxx                        0/1     Pending   0          5m
```

**Diagnosis:**
```bash
kubectl describe pod -n openbao-vault <pod-name>
```

**Common Causes & Solutions:**

**a) Node Taint Issues**
```bash
# Error: "0/5 nodes are available: 2 node(s) had untolerated taint {vault: dedicated}"
# Solution: Ensure your values file has proper tolerations:
tolerations:
  - key: "vault"
    operator: "Equal"
    value: "dedicated"
    effect: "NoSchedule"
```

**b) PVC Binding Issues**
```bash
# Error: "pod has unbound immediate PersistentVolumeClaims"
# Check PVC status
kubectl get pvc -n openbao-vault

# Check NFS server status
kubectl logs -n openbao-vault deployment/openbao-vault-nfs-server
```

**c) Resource Constraints**
```bash
# Error: "Insufficient cpu" or "Insufficient memory"
# Check node resources
kubectl describe node <vault-node>

# Scale up your cluster or reduce resource requests
```

#### 2. Vault Initialization Issues

**Symptoms:** Vault shows as sealed or uninitialized
```bash
kubectl exec -n openbao-vault -it deployment/openbao-vault -- bao status
# Error: Vault is sealed
```

**Solutions:**
```bash
# Initialize vault if not done yet
kubectl exec -n openbao-vault -it deployment/openbao-vault -- \
  bao operator init

# Unseal vault with keys from initialization
kubectl exec -n openbao-vault -it deployment/openbao-vault -- \
  bao operator unseal <key>
```

### NFS Troubleshooting

If pods are stuck with PVC binding issues:

```bash
# Check if NFS server is running
kubectl get pods -n openbao-vault | grep nfs-server

# Check NFS server logs
kubectl logs -n openbao-vault deployment/openbao-vault-nfs-server

# Test NFS mount manually
kubectl run nfs-test --image=busybox --rm -it --restart=Never \
  --overrides='{
    "spec": {
      "containers": [{
        "name": "nfs-test",
        "image": "busybox", 
        "command": ["/bin/sh", "-c", "mount -t nfs <nfs-server-ip>:/nfsshare/data /mnt && ls -la /mnt"],
        "volumeMounts": [{"name": "nfs-test", "mountPath": "/mnt"}]
      }],
      "volumes": [{"name": "nfs-test", "nfs": {"server": "<nfs-server-ip>", "path": "/nfsshare/data"}}]
    }
  }' -n openbao-vault -- /bin/sh

# Check persistent volumes
kubectl get pv | grep openbao-vault
kubectl describe pv openbao-vault-nfs-pv
```

**Common NFS Issues:**
- **NFS server startup**: The vault pod depends on NFS server being ready
- **Network policies**: Ensure NFS traffic (ports 2049, 111, 20048) is allowed
- **Storage class**: Verify the NFS server's backend storage is properly provisioned

## 📊 Monitoring & Maintenance

### Check deployment status:
```bash
# List vault deployment
helm list --all-namespaces | grep openbao

# Check specific deployment
helm status openbao-vault -n openbao-vault

# View all pods
kubectl get pods -n openbao-vault -o wide
```

### Access logs:
```bash
# Vault service logs
kubectl logs -n openbao-vault deployment/openbao-vault

# NFS server logs  
kubectl logs -n openbao-vault deployment/openbao-vault-nfs-server

# Get vault status
kubectl exec -n openbao-vault -it deployment/openbao-vault -- bao status
```

### Backup and Recovery:
```bash
# Create a backup (vault must be unsealed)
kubectl exec -n openbao-vault -it deployment/openbao-vault -- \
  bao operator raft snapshot save backup.snap

# Copy backup out of pod
kubectl cp openbao-vault/openbao-vault-xxx:/backup.snap ./vault-backup.snap
```

## 🔒 Security Considerations

### Default Security Configuration

- **Internal Only**: All services use ClusterIP (no external exposure)
- **Dedicated Nodes**: Vault runs on dedicated, tainted nodes
- **RBAC**: Minimal required permissions via ServiceAccount
- **Network Policies**: Consider implementing network policies for additional security
- **TLS**: Configure TLS certificates for production deployments

### Recommended Security Enhancements

1. **Enable TLS**: Configure TLS certificates for vault API
2. **Network Policies**: Restrict pod-to-pod communication
3. **Sealed Secrets**: Use sealed-secrets or external secret management
4. **Audit Logging**: Enable vault audit logging
5. **Backup Encryption**: Encrypt vault snapshots

## 🚀 Development

### Testing locally:
```bash
# Validate chart syntax
helm lint charts/openbao-vault

# Test template rendering
helm template test-release charts/openbao-vault \
  -f charts/openbao-vault/values/openbao-vault-dedicated.yaml

# Dry run installation
helm install --dry-run test-release charts/openbao-vault \
  -f charts/openbao-vault/values/openbao-vault-dedicated.yaml
```

### Template debugging:
```bash
# Debug specific template
helm template test-release charts/openbao-vault \
  -f charts/openbao-vault/values/openbao-vault.yaml --debug
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add your changes
4. Test with `helm lint` and `helm template`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- **Documentation**: See `docs/` directory for detailed guides
- **Issues**: Report bugs via GitHub Issues  
- **Discussions**: Use GitHub Discussions for questions

## 🔗 Related Projects

- [OpenBao](https://openbao.org/) - Open source fork of HashiCorp Vault
- [boyroywax/nfs-server](https://github.com/boyroywax/nfs-server) - Custom NFS server for Kubernetes