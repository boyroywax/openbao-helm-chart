# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-01-XX

### Added
- Initial release of OpenBao Vault Helm Chart
- Support for OpenBao vault deployment on dedicated Kubernetes nodes
- NFS persistent storage integration using boyroywax/nfs-server
- Security-first design with internal ClusterIP services only
- Dedicated vault node scheduling with taints and tolerations
- RBAC configuration with minimal required permissions
- Health checks and probes for vault services
- Configurable resource limits and requests
- Isolated namespace deployment (openbao-vault-dedicated)
- Production-ready vault configuration

### Features
- **Security-First**: Internal-only access with no external ingress by default
- **Persistent Storage**: NFS-based persistent storage for vault data
- **Dedicated Nodes**: Deploy on dedicated, tainted Kubernetes nodes
- **High Availability**: Supports multi-node vault configurations
- **RBAC**: Proper ServiceAccount, ClusterRole, and ClusterRoleBinding
- **Monitoring**: Built-in health checks and logging capabilities
- **Scalability**: Configurable resource allocations for different workloads

### Configuration
- Pre-configured values file for dedicated vault deployment
- Customizable resource allocations for vault and NFS components  
- Configurable storage sizes based on vault data requirements
- Flexible node selection and scheduling options
- Internal networking with ClusterIP services

### Components
- OpenBao vault using openbao/openbao:latest (v2.4.1)
- NFS server using boyroywax/nfs-server:1.0.0
- Kubernetes RBAC resources
- ConfigMaps for configuration management
- PersistentVolumes and PersistentVolumeClaims for data persistence

[Unreleased]: https://github.com/yourusername/openbao-helm-chart/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/openbao-helm-chart/releases/tag/v1.0.0
