# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-09-11

### Added
- Initial release of Ollama Helm Chart
- Support for multiple AI models with dedicated configurations
- NFS persistent storage integration
- Automatic TLS certificate management with Let's Encrypt
- Model-specific resource optimization
- Isolated namespace deployments
- Support for Llama 3.2 1B model
- Support for Qwen 2.5 0.5B model
- Automatic model downloading via Kubernetes jobs
- Ingress configuration with nginx-ingress support
- Health checks and probes for services
- Configurable tolerations for dedicated node scheduling

### Features
- **Multi-Model Support**: Deploy different AI models with optimized configurations
- **Persistent Storage**: NFS-based persistent storage for model files
- **Security**: TLS encryption and configurable security contexts
- **Monitoring**: Built-in health checks and logging
- **Scalability**: Resource limits and requests for efficient cluster usage
- **Isolation**: Each model runs in its own namespace

### Configuration
- Model-specific values files in `values/` directory
- Customizable resource allocations per model
- Configurable storage sizes based on model requirements
- Flexible ingress and networking options

[Unreleased]: https://github.com/yourusername/ollama-helm-charts/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/ollama-helm-charts/releases/tag/v1.0.0
