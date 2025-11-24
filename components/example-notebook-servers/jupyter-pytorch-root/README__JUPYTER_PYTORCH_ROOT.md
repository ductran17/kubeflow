# Jupyter PyTorch Root Image

This is a variant of the Jupyter PyTorch notebook image that runs as root user.

## Key Differences from Standard Image

- **User**: Runs as `root` user instead of `jovyan` (UID 1000)
- **Permissions**: All files and directories are owned by `root:root`
- **Use Case**: Suitable for workloads that require root privileges for system operations

## Security Considerations

⚠️ **WARNING**: Running containers as root user should be done with caution:

1. **Elevated Privileges**: The container has full root access to the container filesystem
2. **Security Risk**: Potential security vulnerabilities have higher impact
3. **Recommended Use**: Only use when absolutely necessary for your workloads

## Software Versions

- **PyTorch**: 2.5.1 (CPU version)
- **TorchAudio**: 2.5.1
- **TorchVision**: 0.20.1
- **JupyterLab**: 4.3.5
- **Jupyter Notebook**: 7.3.2
- **Python**: 3.11.11

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

This image can be used as a base for custom notebook servers that require root access:

```dockerfile
FROM ghcr.io/kubeflow/kubeflow/notebook-servers/jupyter-pytorch-root:latest

# Add your customizations here
USER root
RUN apt-get update && apt-get install -y some-package
```

## Features

- Pre-installed PyTorch ecosystem (torch, torchaudio, torchvision)
- JupyterLab with root support enabled
- Optimized for Kubeflow Notebook deployments
- Includes kubectl for cluster operations
- s6-overlay for proper process management