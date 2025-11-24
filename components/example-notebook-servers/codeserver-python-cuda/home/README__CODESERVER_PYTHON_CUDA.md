# About the Code-Server Python CUDA Image

This file contains notes about the Kubeflow Notebooks _Code-Server Python CUDA_ image.

## CUDA Support

This image is built on **NVIDIA CUDA 12.6.1** and includes:

- CUDA 12.6.1 development environment
- cuDNN libraries for deep learning
- CUDA-aware PyTorch (built for CUDA 12.1+)
- CUDA-enabled TensorFlow (2.15.0)
- CuPy for NumPy-compatible GPU operations
- Numba for JIT compilation with CUDA support

## Root Access

This image runs as the **root** user, providing full administrative privileges within the container. This allows users to:

- Install system packages with `apt`, `yum`, etc.
- Modify system files and configurations
- Access all system resources without restrictions
- Run commands that require elevated privileges
- Install additional CUDA libraries and drivers if needed

⚠️ **Warning**: Running as root provides full system access. Only use this image when you need administrative privileges and understand the security implications.

## GPU Access Requirements

To utilize the CUDA capabilities in this image:

1. **NVIDIA GPU**: The host system must have an NVIDIA GPU
2. **NVIDIA Drivers**: Compatible NVIDIA drivers must be installed on the host
3. **NVIDIA Container Toolkit**: Install the nvidia-container-runtime on the host
4. **Kubernetes Configuration**: Set appropriate resource requests for GPU resources

Example Kubernetes pod spec:
```yaml
resources:
  limits:
    nvidia.com/gpu: 1
```

## CUDA Verification

Once running, you can verify CUDA access with:

```bash
# Check CUDA compiler
nvcc --version

# Check GPU availability from Python
python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
python -c "import tensorflow as tf; print(f'GPU devices: {len(tf.config.list_physical_devices(\"GPU\"))}')"

# Test CuPy
python -c "import cupy as cp; print(f'CuPy version: {cp.__version__}')"
```

## Jupyter Extension required HTTPS

This image comes with the jupyter extension installed, which allows you to run and edit jupyter notebooks in code-server.

However, because the jupyter extension uses [Service Workers](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API), it requires HTTPS to work.
That is, if you access this notebook over HTTP, the Jupyter extension will NOT work.

Additionally, if you are using __Chrome__, the HTTPS certificate must be __valid__ and trusted by your browser.
As a workaround, if you have a self-signed HTTPS certificate, you could use Firefox, or set the [`unsafely-treat-insecure-origin-as-secure`](chrome://flags/#unsafely-treat-insecure-origin-as-secure) flag in Chrome.