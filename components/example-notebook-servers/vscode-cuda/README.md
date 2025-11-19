# Kubeflow VSCode Image with CUDA 12.6 Support

This repository contains the Dockerfile and configuration to build a **fully Kubeflow-compatible** VSCode (code-server) image with comprehensive CUDA 12.6, GCC, and development tools support.

## ✅ Kubeflow Compliance

This image follows all Kubeflow Notebooks requirements:

- **✅ HTTP interface on port 8888** with NB_PREFIX support
- **✅ CORS headers** for iframe compatibility (`Access-Control-Allow-Origin: *`)
- **✅ Runs as jovyan user** (UID 1000, GID 0)
- **✅ Home directory at /home/jovyan** with empty PVC support
- **✅ Proper permissions handling** for arbitrary UIDs (OpenShift compatible)

## Features

- **VSCode Server**: Latest code-server (v4.96.4) with web-based IDE
- **CUDA 12.6**: Full NVIDIA CUDA toolkit including:
  - CUDA compiler (nvcc)
  - CUDA libraries (cuBLAS, cuFFT, cuRAND, cuSOLVER, cuSPARSE)
  - CUDA runtime and development libraries
- **Development Tools**: GCC 11.4.0, build-essential, cmake, pkg-config
- **Python Libraries**: Pre-installed data science and ML libraries with CUDA support
- **VSCode Extensions**: Pre-installed extensions for Python, Jupyter, Docker, Kubernetes
- **Kubeflow Ready**: Compatible with Kubeflow notebooks infrastructure

## Prerequisites

- Docker with GPU support (NVIDIA Container Toolkit)
- NVIDIA GPU with CUDA 12.6 compatible drivers
- At least 8GB RAM and 20GB disk space recommended

## Quick Start

### Build the Image

```bash
# Build for current architecture
make build

# Build and push multi-arch image (requires buildx)
make buildx-push
```

### Run Locally

```bash
# Basic run with GPU support
make run

# Run with privileged mode for extended functionality
make run-privileged
```

### Access the IDE

After running, open your browser to: `http://localhost:8888`

## Build Configuration

You can customize the build using environment variables:

```bash
# Custom tag
export TAG=v1.0.0

# Custom base image (must be Jupyter-compatible)
export BASE_IMAGE=kubeflownotebookswg/jupyter-scipy:1.10.0

# Custom versions
export CUDA_VERSION=12.6.2
export CODESERVER_VERSION=4.96.4
export GCC_VERSION=11.4.0

# Build with custom settings
make build
```

## Included Software

### Development Tools
- **GCC 11.4.0**: C/C++ compiler with multilib support
- **Build Tools**: make, cmake, pkg-config, build-essential
- **Git**: Version control
- **Editors**: vim, nano

### CUDA Toolkit 12.6.2
- **Compiler**: nvcc (CUDA C++ compiler)
- **Libraries**: cuBLAS, cuFFT, cuRAND, cuSOLVER, cuSPARSE
- **Runtime**: CUDA runtime libraries
- **Development**: Headers and development libraries

### Python Environment
- **Core**: Python 3.11, numpy, scipy, pandas
- **Visualization**: matplotlib, seaborn
- **Machine Learning**: scikit-learn
- **Deep Learning**: PyTorch, TensorFlow (with CUDA support)
- **CUDA Acceleration**: CuPy, Numba, JAX
- **Kubeflow**: kfp, kubernetes client

### VSCode Extensions
- **Python**: Microsoft Python extension with IntelliSense
- **Jupyter**: Jupyter notebook support
- **Docker**: Docker integration
- **Kubernetes**: Kubernetes tools and resource management
- **Remote**: Remote container development

## Testing CUDA Functionality

### Test NVIDIA Drivers

```bash
make test-cuda
```

### Test CUDA Python Integration

```bash
make test-cuda-compatibility
```

### Manual Testing

```python
# Test in VSCode terminal or Python notebook
import torch
print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"CUDA version: {torch.version.cuda}")
print(f"GPU count: {torch.cuda.device_count()}")

# Test CuPy
import cupy as cp
print(f"CuPy version: {cp.__version__}")
print(f"CuPy CUDA device: {cp.cuda.Device()}")

# Test Numba
from numba import cuda
print(f"Numba CUDA available: {cuda.is_available()}")
```

## Directory Structure

```
vscode-cuda/
├── Dockerfile              # Main Dockerfile
├── Makefile               # Build automation
├── requirements.txt       # Python packages
├── README.md             # This file
└── s6/
    └── services/
        └── code-server/
            └── run      # Service startup script
```

## Environment Variables

The image includes these CUDA-related environment variables:

- `NVIDIA_VISIBLE_DEVICES=all`: Make all GPUs visible
- `NVIDIA_DRIVER_CAPABILITIES=compute,utility,compat32`: Enable GPU capabilities
- `NVIDIA_REQUIRE_CUDA=cuda>=12.6`: Require CUDA 12.6+
- `CUDA_HOME=/usr/local/cuda`: CUDA installation path
- `CUDA_ROOT=/usr/local/cuda`: Alternative CUDA path
- `CUDA_PATH=/usr/local/cuda`: Another CUDA path reference
- `LD_LIBRARY_PATH`: Includes CUDA library paths
- `PATH`: Includes CUDA binary paths

## Troubleshooting

### Common Issues

1. **GPU not detected**: Ensure NVIDIA Container Toolkit is installed and working
2. **CUDA version mismatch**: Check that your NVIDIA drivers support CUDA 12.6
3. **Memory issues**: Increase Docker memory allocation to at least 8GB

### Debug Commands

```bash
# Check Docker GPU support
docker run --rm --gpus all nvidia/cuda:12.6.2-base-ubuntu22.04 nvidia-smi

# Check image layers
docker history $(IMG)-$(ARCH)

# Inspect running container
docker inspect <container_id>
```

## Integration with Kubeflow

This image is designed to work seamlessly with Kubeflow's notebook controller. You can use it by:

1. Building and pushing the image to your registry
2. Creating a custom notebook configuration in Kubeflow
3. Selecting the VSCode CUDA image when creating notebooks

### Example Kubeflow Notebook Config

```yaml
apiVersion: kubeflow.org/v1
kind: Notebook
metadata:
  name: vscode-cuda-notebook
spec:
  template:
    spec:
      containers:
      - name: vscode-cuda
        image: your-registry/kubeflownotebookswg/vscode-cuda:v1.10.0
        resources:
          limits:
            nvidia.com/gpu: 1
          requests:
            cpu: "2"
            memory: "8Gi"
```

## License

This project follows the same Apache 2.0 license as Kubeflow.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Support

For issues related to:
- **Kubeflow**: [Kubeflow Issues](https://github.com/kubeflow/kubeflow/issues)
- **CUDA**: [NVIDIA CUDA Forums](https://forums.developer.nvidia.com/c/cuda)
- **Code-Server**: [Code-Server Issues](https://github.com/coder/code-server/issues)