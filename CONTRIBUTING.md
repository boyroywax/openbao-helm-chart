# Contributing to Ollama Helm Charts

Thank you for your interest in contributing to the Ollama Helm Charts project! We welcome contributions of all kinds.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a new branch for your changes
4. Make your changes
5. Test your changes
6. Submit a pull request

## Types of Contributions

### Adding New Models

To add support for a new AI model:

1. Create a new values file in `charts/ollama-model/values/` following the naming convention: `{model-name}-values.yaml`
2. Configure the model parameters:
   - `model.name`: Unique identifier for the model
   - `model.fullName`: Full Ollama model name (e.g., "llama3.2:1b")
   - `model.displayName`: Human-readable name
   - `model.size`: Model download size
3. Adjust resource requirements based on model size and performance needs
4. Test the deployment thoroughly

### Improving Templates

When modifying Kubernetes templates:

1. Ensure backward compatibility
2. Follow Kubernetes best practices
3. Test with multiple value configurations
4. Update documentation as needed

### Documentation Updates

- Keep README.md current with new features
- Add examples for new configurations
- Update troubleshooting guides

## Testing Guidelines

Before submitting a pull request:

### 1. Chart Validation
```bash
helm lint charts/ollama-model
```

### 2. Template Rendering Test
```bash
helm template test-release charts/ollama-model -f charts/ollama-model/values/llama32-1b-values.yaml
```

### 3. Dry Run Installation
```bash
helm install --dry-run test-release charts/ollama-model -f charts/ollama-model/values/llama32-1b-values.yaml
```

### 4. Multiple Model Configurations
Test with different model values files to ensure compatibility.

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

## Pull Request Process

1. **Title**: Use a clear, descriptive title
2. **Description**: Explain what changes you made and why
3. **Testing**: Describe how you tested your changes
4. **Documentation**: Update relevant documentation
5. **Breaking Changes**: Clearly mark any breaking changes

## Model Configuration Guidelines

When adding new models, consider:

### Resource Requirements
- **Memory**: Base requirement + model size + overhead
- **CPU**: Adjust based on model complexity
- **Storage**: Model size + working space

### Model-Specific Settings
- Download timeout based on model size
- Health check parameters
- Security contexts if needed

### Naming Conventions
- Model names should be lowercase with hyphens
- Use descriptive but concise names
- Follow pattern: `{family}{version}-{size}` (e.g., `llama32-1b`)

## Reporting Issues

When reporting bugs or requesting features:

1. Check existing issues first
2. Use issue templates when available
3. Provide clear reproduction steps
4. Include relevant logs and configuration
5. Specify Kubernetes and Helm versions

## Questions?

- **GitHub Discussions**: For general questions and community support
- **GitHub Issues**: For bug reports and feature requests
- **Documentation**: Check existing docs in the repository

Thank you for contributing! 🚀
