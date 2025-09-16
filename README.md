# 🦙 Ollama Model Helm Chart

A production-ready Helm chart for deploying Ollama AI models on Kubernetes with dedicated model infrastructure, NFS shared storage, and automatic TLS certificates.

## 🎯 Features

- **Dedicated Model Nodes**: Deploy models on dedicated Kubernetes nodes with taints and node affinity
- **Shared NFS Storage**: Efficient model sharing across pods using NFS persistent volumes
- **Automatic Model Download**: Pre-download models during deployment with validation
- **Production Ready**: Health checks, resource limits, and monitoring integration
- **TLS Security**: Automatic HTTPS certificates via cert-manager and Let's Encrypt
- **Multi-Model Support**: 8 pre-configured popular AI models ready to deploy

## 📋 Prerequisites

- Kubernetes cluster (1.19+)
- Helm 3.x
- StorageClass for dynamic provisioning (e.g., `do-block-storage` for DigitalOcean)
- nginx-ingress-controller installed
- cert-manager installed for TLS certificates
- kubectl configured with cluster access

## 🏗️ Node Setup and Labeling

### Dedicated Node Configuration

For optimal performance, this chart supports dedicated nodes for each model. Dedicated nodes prevent resource contention and allow for model-specific optimizations.

#### Step 1: Create or Label Nodes

**For DigitalOcean Kubernetes (DOKS):**
```bash
# Create a new node pool for a specific model (e.g., qwen25-05b)
doctl kubernetes cluster node-pool create <cluster-name> \
  --name ollama-qwen25-05b \
  --size s-4vcpu-8gb \
  --count 1 \
  --tag ollama,qwen25-05b

# Or label existing nodes
kubectl label node <node-name> node-role.kubernetes.io/qwen25-05b=true
```

**For other Kubernetes platforms:**
```bash
# Label a node for a specific model
kubectl label node <node-name> node-role.kubernetes.io/qwen25-05b=true
kubectl label node <node-name> node-role.kubernetes.io/llama32-1b=true
kubectl label node <node-name> node-role.kubernetes.io/phi3-38b=true
# ... etc for other models
```

#### Step 2: Add Node Taints (Recommended)

Taint nodes to ensure only ollama workloads are scheduled:

```bash
# Taint nodes to dedicate them for ollama workloads
kubectl taint node <qwen25-05b-node> ollama=dedicated:NoSchedule
kubectl taint node <llama32-1b-node> ollama=dedicated:NoSchedule
kubectl taint node <phi3-38b-node> ollama=dedicated:NoSchedule
```

#### Step 3: Verify Node Configuration

```bash
# Check node labels and taints
kubectl get nodes --show-labels
kubectl describe node <node-name>
```

### Supported Node Labels

Each model configuration expects specific node labels:

| Model | Node Label | Recommended Node Size |
|-------|------------|----------------------|
| **Qwen 2.5 0.5B** | `node-role.kubernetes.io/qwen25-05b=true` | 2-4 CPU, 4-8GB RAM |
| **Llama 3.2 1B** | `node-role.kubernetes.io/llama32-1b=true` | 2-4 CPU, 4-8GB RAM |
| **Phi3 3.8B** | `node-role.kubernetes.io/phi3-38b=true` | 4-8 CPU, 8-16GB RAM |
| **Gemma 2B** | `node-role.kubernetes.io/gemma-2b=true` | 2-4 CPU, 4-8GB RAM |
| **Mistral 7B** | `node-role.kubernetes.io/mistral-7b=true` | 4-8 CPU, 8-16GB RAM |
| **Llama 3.1 8B** | `node-role.kubernetes.io/llama31-8b=true` | 6-8 CPU, 12-16GB RAM |
| **Code Llama 7B** | `node-role.kubernetes.io/code-llama-7b=true` | 4-8 CPU, 8-16GB RAM |
| **Codestral** | `node-role.kubernetes.io/codestral=true` | 4-8 CPU, 8-16GB RAM | 
## 🚀 Quick Start

### 1. Deploy a Model

Choose from our pre-configured models and deploy:

```bash
# Deploy Qwen 2.5 0.5B (lightweight model)
helm install qwen25-05b ./charts/ollama-model \
  --namespace qwen25-05b \
  --values ./charts/ollama-model/values/qwen25-05b.yaml \
  --create-namespace

# Deploy Llama 3.2 1B 
helm install llama32-1b ./charts/ollama-model \
  --namespace llama32-1b \
  --values ./charts/ollama-model/values/llama32-1b.yaml \
  --create-namespace

# Deploy Phi3 3.8B
helm install phi3-38b ./charts/ollama-model \
  --namespace phi3-38b \
  --values ./charts/ollama-model/values/phi3-38b.yaml \
  --create-namespace
```

### 2. Check Deployment Status

```bash
# Check all helm releases
helm list --all-namespaces

# Monitor pod status
kubectl get pods -n qwen25-05b
kubectl get pods -n llama32-1b

# Check ingress and TLS certificates
kubectl get ingress -A
kubectl get certificates -A
```

### 3. Access Your Model

Once deployed, your models will be available at:

- **Qwen 2.5 0.5B**: `https://qwen25-05b.ollama.ai.layerwork.space`
- **Llama 3.2 1B**: `https://llama32-1b.ollama.ai.layerwork.space`
- **Phi3 3.8B**: `https://phi3-38b.ollama.ai.layerwork.space`

### 4. Test Your Deployment

```bash
# Test API endpoint
curl -X POST https://qwen25-05b.ollama.ai.layerwork.space/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:0.5b",
    "prompt": "Hello, how are you?",
    "stream": false
  }'

# Or use kubectl port-forward for local testing
kubectl port-forward -n qwen25-05b svc/ollama-qwen25-05b 11434:11434
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:0.5b",
    "prompt": "Hello, how are you?",
    "stream": false
  }'
```

## 📚 Supported Models

### Lightweight Models (< 2GB)
| Model | Size | Command | Best For |
|-------|------|---------|----------|
| **Qwen 2.5 0.5B** | 394MB | `helm install qwen25-05b` | Testing, development |
| **Llama 3.2 1B** | 1.3GB | `helm install llama32-1b` | General conversation |
| **Google Gemma 2B** | 1.4GB | `helm install gemma-2b` | Efficient language tasks |

### Medium Models (2-10GB)
| Model | Size | Command | Best For |
|-------|------|---------|----------|
| **Phi3 3.8B** | 2.2GB | `helm install phi3-38b` | Balanced performance |
| **Mistral 7B** | 4.1GB | `helm install mistral-7b` | General purpose AI |
| **Llama 3.1 8B** | 4.7GB | `helm install llama31-8b` | Advanced reasoning |
| **Code Llama 7B** | 3.8GB | `helm install code-llama-7b` | Code generation |

### Large Models (> 10GB)
| Model | Size | Command | Best For |
|-------|------|---------|----------|
| **Codestral** | 12GB | `helm install codestral` | Advanced coding tasks |

## 🛠️ Troubleshooting

### Common Issues

#### 1. Pods Stuck in Pending State

**Symptoms:** Pods show `Pending` status
```bash
kubectl get pods -n qwen25-05b
# NAME                                     READY   STATUS    RESTARTS   AGE
# download-qwen25-05b-xsllq                0/1     Pending   0          5m
```

**Diagnosis:**
```bash
kubectl describe pod -n qwen25-05b <pod-name>
```

**Common Causes & Solutions:**

**a) Node Taint Issues**
```bash
# Error: "0/5 nodes are available: 2 node(s) had untolerated taint {ollama: dedicated}"
# Solution: Ensure your values file has proper tolerations:
tolerations:
  - key: "ollama"
    operator: "Equal"
    value: "dedicated"
    effect: "NoSchedule"
```

**b) PVC Binding Issues**
```bash
# Error: "pod has unbound immediate PersistentVolumeClaims"
# Check PVC status
kubectl get pvc -n qwen25-05b

# If PVC is stuck, delete and recreate deployment
kubectl delete namespace qwen25-05b
helm install qwen25-05b ./charts/ollama-model -n qwen25-05b --values ./charts/ollama-model/values/qwen25-05b.yaml --create-namespace
```

**c) Resource Constraints**
```bash
# Error: "Insufficient cpu" or "Insufficient memory"
# Check node resources
kubectl describe node <node-name>

# Scale up your cluster or reduce resource requests
```
- `gemma-2b.yaml` - Google Gemma 2B configuration

**Medium Models:**
- `phi3-38b.yaml` - Microsoft Phi-3 3.8B configuration (flexible scheduling)
- `code-llama-7b.yaml` - Code Llama 7B configuration
- `mistral-7b.yaml` - Mistral 7B configuration
- `llama31-8b.yaml` - Llama 3.1 8B configuration

**Large Models:**
- `codestral.yaml` - Codestral configuration

### Customization

You can override any values by creating your own values file or using `--set` flags:

```bash
helm install my-model ./charts/ollama-model 
  -f ./charts/ollama-model/values/llama32-1b-values.yaml 
  --set ingress.host=my-custom-domain.com 
  --set ollama.resources.limits.memory=8Gi
```

### Key Configuration Options

- **Model Selection**: Set in `model.name` and `model.fullName`
- **Resource Limits**: Configure CPU/memory in `ollama.resources` and `nfs.resources`
- **Storage Size**: Adjust `nfs.storage.size` based on model requirements
- **Ingress**: Enable/disable and configure hostname in `ingress` section
- **Namespace**: Auto-generated as `ollama-{model.name}` or set custom name

## Architecture

Each deployment includes:

- **Namespace**: Isolated environment for the model
- **NFS Server**: Persistent storage for model files
- **Ollama Service**: AI inference service
- **Model Download Job**: Automatic model downloading and setup
- **Ingress**: HTTPS access with automatic TLS certificates
- **ConfigMaps**: Configuration management

## Monitoring & Troubleshooting

### Check deployment status:
```bash
# List all Ollama deployments
helm list --all-namespaces | grep ollama

# Check specific deployment
helm status llama32-1b -n ollama-llama32-1b

# View pods
kubectl get pods -n ollama-llama32-1b
```

### Access logs:
```bash
# Ollama service logs
kubectl logs -n ollama-llama32-1b deployment/llama32-1b-ollama

# NFS server logs  
kubectl logs -n ollama-llama32-1b deployment/llama32-1b-nfs-server

# Model download job logs
kubectl logs -n ollama-llama32-1b job/llama32-1b-download-model
```

### NFS Troubleshooting

If pods are stuck in `Pending` state with "unbound immediate PersistentVolumeClaims" errors:

```bash
# Check if NFS server is running
kubectl get pods -n <model-namespace> | grep nfs-server

# Check NFS server logs
kubectl logs -n <model-namespace> deployment/<model-name>-nfs-server

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
  }' -- /bin/sh

# Check persistent volumes
kubectl get pv | grep <model-name>
kubectl describe pv <model-name>-nfs-pv
```

**Common NFS Issues:**
- **Missing NFS client tools**: Some Kubernetes distributions may not have NFS client packages installed
- **Network policies**: Ensure NFS traffic (ports 2049, 111, 20048) is allowed between pods
- **Storage class conflicts**: Make sure the NFS server's backend storage is properly provisioned

## Adding New Models

To add a new model:

1. Create a new values file in `charts/ollama-model/values/` (e.g., `my-model-values.yaml`)
2. Configure the model parameters:
   ```yaml
   model:
     name: "my-model"
     fullName: "my-model:latest"  
     displayName: "My Custom Model"
     size: "2GB"
   ```
3. Adjust resource requirements based on model size
4. Deploy using the new values file

## Development

### Testing locally:
```bash
# Validate chart syntax
helm lint charts/ollama-model

# Test template rendering
helm template test-release charts/ollama-model -f charts/ollama-model/values/llama32-1b-values.yaml

# Dry run installation
helm install --dry-run test-release charts/ollama-model -f charts/ollama-model/values/llama32-1b-values.yaml
```

### Template debugging:
```bash
# Debug specific template
helm template test-release charts/ollama-model -f charts/ollama-model/values/llama32-1b-values.yaml --debug
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add your changes
4. Test with `helm lint` and `helm template`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

- **Documentation**: See `docs/` directory for detailed guides
- **Issues**: Report bugs via GitHub Issues  
- **Discussions**: Use GitHub Discussions for questions

## Related Projects

- [Ollama](https://ollama.ai/) - Run AI models locally
- [boyroywax/nfs-server](https://github.com/boyroywax/nfs-server) - Custom NFS server for Kubernetes