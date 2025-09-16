# Contributing to OpenBao Vault Helm Chart

Thank you for your interest in contributing to the OpenBao Vault Helm Chart project! We welcome contributions of all kinds.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a new branch for your changes
4. Make your changes
5. Test your changes
6. Submit a pull request

## Types of Contributions

### Vault Configuration Improvements

To enhance vault deployment configurations:

1. Modify values files in `charts/openbao-vault/values/` 
2. Configure vault parameters:
   - `vault.image`: OpenBao container image and version
   - `vault.resources`: CPU/memory limits and requests
   - `vault.config`: Vault configuration parameters
   - `nfs.storage.size`: Storage requirements
3. Test deployment thoroughly with different scenarios
4. Ensure security best practices are maintained

### Security Enhancements

When improving security features:

1. Follow security-first principles (internal-only by default)
2. Implement proper RBAC configurations
3. Use minimal required permissions
4. Document security considerations
5. Test with security scanners when possible

### Improving Templates

When modifying Kubernetes templates:

1. Ensure backward compatibility
2. Follow Kubernetes best practices
3. Test with multiple value configurations
4. Update documentation as needed
5. Maintain security-focused approach

### Documentation Updates

- Keep README.md current with new features
- Add examples for new configurations
- Update troubleshooting guides
- Document security considerations

## Testing Guidelines

Before submitting a pull request:

### 1. Chart Validation
```bash
helm lint charts/openbao-vault
```

### 2. Template Rendering Test
```bash
helm template test-release charts/openbao-vault \
  -f charts/openbao-vault/values/openbao-vault-dedicated.yaml
```

### 3. Dry Run Installation
```bash
helm install --dry-run test-release charts/openbao-vault \
  -f charts/openbao-vault/values/openbao-vault-dedicated.yaml
```

### 4. Security Testing
- Verify no external ingress by default
- Test RBAC permissions are minimal
- Confirm vault runs on dedicated nodes
- Validate NFS storage security

### 5. Integration Testing
Test with actual Kubernetes cluster:
```bash
# Deploy to test namespace
helm install test-vault charts/openbao-vault \
  -f charts/openbao-vault/values/openbao-vault-dedicated.yaml \
  -n vault-test --create-namespace

# Verify vault functionality
kubectl exec -n vault-test -it deployment/openbao-vault -- bao status
```

## Code Style

### YAML Files
- Use 2 spaces for indentation
- Keep lines under 120 characters
- Use meaningful variable names
- Include comments for complex configurations

### Templates
- Follow Helm template best practices
- Use consistent naming conventions
- Include resource limits and requests
- Implement proper health checks
- Prioritize security in all configurations

## Pull Request Process

1. **Title**: Use a clear, descriptive title
2. **Description**: Explain what changes you made and why
3. **Security Impact**: Describe any security implications
4. **Testing**: Describe how you tested your changes
5. **Documentation**: Update relevant documentation
6. **Breaking Changes**: Clearly mark any breaking changes

## Vault Configuration Guidelines

When modifying vault configurations, consider:

### Security Requirements
- **Access Control**: Ensure internal-only access by default
- **RBAC**: Use minimal required permissions
- **Storage**: Secure data persistence with proper volume permissions
- **Network**: No external ingress unless explicitly configured

### Resource Requirements
- **Memory**: Base requirement + vault overhead + storage caching
- **CPU**: Adjust based on expected vault operations
- **Storage**: Vault data + logs + backup space
- **Network**: Consider NFS traffic between pods

### High Availability Settings
- Multiple vault instances (when supported)
- Proper health checks and readiness probes
- Graceful shutdown handling
- Backup and recovery procedures

### Naming Conventions
- Use descriptive, security-focused names
- Follow pattern: `openbao-vault-{purpose}` (e.g., `openbao-vault-dedicated`)
- Consistent labeling for monitoring

## Security Guidelines

### Default Security Posture
- **No External Access**: ClusterIP services only by default
- **Dedicated Nodes**: Deploy on tainted, dedicated nodes
- **Minimal RBAC**: Only required permissions
- **Secure Defaults**: Conservative security settings

### Security Testing
- Verify no unintended external exposure
- Test RBAC permission boundaries
- Validate storage security
- Check for security misconfigurations

## Reporting Issues

When reporting bugs or requesting features:

1. Check existing issues first
2. Use issue templates when available
3. Provide clear reproduction steps
4. Include relevant logs and configuration
5. Specify Kubernetes, Helm, and OpenBao versions
6. Describe security context if applicable

## Documentation Standards

- **Security**: Document all security considerations
- **Configuration**: Explain configuration options clearly
- **Troubleshooting**: Provide actionable troubleshooting steps
- **Examples**: Include practical examples
- **Best Practices**: Share operational wisdom

## Questions?

- **GitHub Discussions**: For general questions and community support
- **GitHub Issues**: For bug reports and feature requests
- **Documentation**: Check existing docs in the repository
- **Security**: Use private disclosure for security-related issues

## Security Disclosure

For security vulnerabilities:
1. **DO NOT** open public GitHub issues
2. Contact maintainers privately
3. Allow reasonable time for fixes
4. Coordinate responsible disclosure

Thank you for contributing to OpenBao Vault security! �️
