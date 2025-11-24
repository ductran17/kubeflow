# Jupyter Root Image

This is a variant of the Jupyter notebook base image that runs as root user.

## Key Differences from Standard Image

- **User**: Runs as `root` user instead of `jovyan` (UID 1000)
- **Permissions**: All files and directories are owned by `root:root`
- **Use Case**: Base image for creating specialized notebook servers that require root privileges

## Security Considerations

⚠️ **WARNING**: Running containers as root user should be done with caution:

1. **Elevated Privileges**: The container has full root access to the container filesystem
2. **Security Risk**: Potential security vulnerabilities have higher impact
3. **Recommended Use**: Only use when absolutely necessary for your workloads

## Software Versions

- **JupyterLab**: 4.3.5
- **Jupyter Notebook**: 7.3.2
- **Python**: 3.11.11
- **Conda**: Miniforge3 24.11.3-0
- **Node.js**: 20.x
- **pip**: 24.3.1

## Features

- JupyterLab and Jupyter Notebook with root support enabled
- Conda package manager for Python environment management
- Node.js for JupyterLab extensions
- kubectl for Kubernetes operations
- s6-overlay for proper process management
- Optimized for Kubeflow Notebook deployments

## Build Instructions

```bash
# Build the image
make docker-build

# Build with dependencies
make docker-build-dep

# Build and push
make docker-build-push

# Build and push with dependencies
make docker-build-push-dep
```

## Usage

This image serves as a base for creating specialized notebook servers that require root access:

```dockerfile
FROM ghcr.io/kubeflow/kubeflow/notebook-servers/jupyter-root:latest

USER root
RUN apt-get update && apt-get install -y some-package
# Add your customizations here
```

## Derived Images

- **jupyter-pytorch-root**: Jupyter with PyTorch pre-installed (root variant)