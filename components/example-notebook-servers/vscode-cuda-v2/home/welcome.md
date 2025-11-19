# Welcome to VSCode CUDA v2 for Kubeflow! 🚀

## 🎯 What's Available

This VSCode environment comes with:

### **Development Environment**
- **VSCode** with full IntelliSense and debugging
- **Python 3.11** with Conda package management
- **CUDA 12.6** with complete toolkit
- **GCC 11.4.0** for C/C++ development

### **Machine Learning Stack**
- **PyTorch** with CUDA support
- **TensorFlow** with GPU acceleration
- **CuPy** for NumPy-compatible GPU computing
- **JAX** with high-performance computing
- **Scikit-learn, Pandas, NumPy** for data science

### **VSCode Extensions Pre-installed**
- Python with IntelliSense
- Jupyter notebook support
- Docker integration
- Kubernetes tools
- Code formatting (Black, Flake8)
- Remote development support

## 🚀 Quick Start

### Test Your GPU Environment

```python
# Test PyTorch with CUDA
import torch
print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"CUDA version: {torch.version.cuda}")
    print(f"GPU count: {torch.cuda.device_count()}")
    print(f"GPU name: {torch.cuda.get_device_name(0)}")

# Test CuPy
import cupy as cp
print(f"CuPy version: {cp.__version__}")
print(f"CuPy device: {cp.cuda.Device()}")

# Simple GPU computation test
if torch.cuda.is_available():
    # Create a tensor on GPU
    x = torch.randn(1000, 1000).cuda()
    y = torch.randn(1000, 1000).cuda()
    z = torch.mm(x, y)
    print(f"GPU Matrix multiplication successful! Result shape: {z.shape}")
```

### Test CUDA Compiler

```bash
# Check CUDA compiler
nvcc --version

# Compile and run a simple CUDA program
cat > hello_cuda.cu << 'EOF'
#include <stdio.h>
#include <cuda_runtime.h>

__global__ void hello_cuda() {
    printf("Hello from GPU thread %d!\n", threadIdx.x);
}

int main() {
    printf("Hello from CPU!\n");

    // Launch kernel with 10 threads
    hello_cuda<<<1, 10>>>();

    // Wait for GPU to finish
    cudaDeviceSynchronize();

    printf("CUDA program completed!\n");
    return 0;
}
EOF

# Compile and run
nvcc hello_cuda.cu -o hello_cuda
./hello_cuda
```

### Kubeflow Integration

```python
# Test Kubeflow Pipelines
import kfp
print(f"KFP version: {kfp.__version__}")

# Test Kubernetes client
from kubernetes import client, config
print("Kubernetes client available")
```

## 🛠️ Development Tips

### **VSCode Shortcuts**
- `Ctrl+Shift+P`: Command palette
- `Ctrl+``: Open terminal
- `Ctrl+Shift+E`: File explorer
- `Ctrl+,`: Settings

### **Python Development**
- Use the integrated debugger with DebugPy
- Jupyter notebooks work directly in VSCode
- IntelliSense provides code completion
- Black formatter automatically formats code

### **CUDA Development**
- `.cu` files have CUDA syntax highlighting
- nvcc compiler is available in terminal
- GPU memory monitoring with `nvidia-smi`
- Use `torch.cuda.memory_summary()` for PyTorch

## 📁 Workspace Organization

- `/home/jovyan` - Your home directory (persisted)
- `/home/jovyan/workspace` - Development workspace
- `/opt/conda` - Conda environment
- `/usr/local/cuda` - CUDA toolkit installation

## 🐛 Common Issues & Solutions

### **CUDA Not Available**
```bash
# Check NVIDIA drivers
nvidia-smi

# Check CUDA installation
nvcc --version

# Restart the VSCode server if needed
```

### **Memory Issues**
```bash
# Monitor GPU memory
watch -n 1 nvidia-smi

# Clear GPU cache in PyTorch
import torch
torch.cuda.empty_cache()
```

### **Package Installation**
```bash
# Use conda for system packages
conda install package_name

# Use pip for Python packages
pip install package_name

# Install CUDA-specific packages
pip install cupy-cuda12x
```

## 🎯 Project Ideas

Try these in your new environment:

1. **GPU-Accelerated Data Processing**
   - Use CuPy for NumPy operations on GPU
   - Process large datasets with RAPIDS

2. **Deep Learning Projects**
   - Train neural networks with PyTorch/TensorFlow
   - Use distributed training across multiple GPUs

3. **Kubeflow Pipelines**
   - Create ML pipelines with KFP
   - Deploy models as Kubeflow components

4. **C++/CUDA Development**
   - Write custom CUDA kernels
   - Optimize performance-critical code

5. **Research & Prototyping**
   - Fast experimentation with Jupyter notebooks
   - Reproduce research papers

## 📚 Resources

- [PyTorch Documentation](https://pytorch.org/docs/)
- [CUDA Programming Guide](https://docs.nvidia.com/cuda/cuda-c-programming-guide/)
- [Kubeflow Documentation](https://www.kubeflow.org/docs/)
- [VSCode Python Extension](https://code.visualstudio.com/docs/python/python-tutorial)

---

**Happy Coding! 🎉**

Your VSCode environment is ready for GPU-accelerated machine learning development in Kubeflow!