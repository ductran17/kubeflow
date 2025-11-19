# Kubeflow VSCode CUDA v2 Image

Tuyệt vời! Đây là image VSCode (code-server) được xây dựng trên base `codeserver-python` của Kubeflow, được nâng cấp với đầy đủ hỗ trợ CUDA 12.6, GCC, và các thư viện phát triển machine learning.

## ✅ Đầy đủ tuân thủ Kubeflow Notebooks

Image này đáp ứng TẤT CẢ các yêu cầu của Kubeflow Notebooks:

- **✅ Giao diện HTTP trên port 8888** với hỗ trợ NB_PREFIX
- **✅ CORS headers** cho tương thích iframe (`Access-Control-Allow-Origin: *`)
- **✅ Chạy với user jovyan** (UID 1000, GID 0)
- **✅ Home directory tại /home/jovyan** với hỗ trợ PVC trống
- **✅ Xử lý permissions** cho arbitrary UIDs (tương thích OpenShift)

## 🚀 Tính năng chính

### Development Tools
- **VSCode Server**: Code-server v4.96.4 với IDE web-based
- **Python Environment**: Python 3.11 với Conda và full package management
- **GCC 11.4.0**: Full C/C++ compiler với multilib support
- **Build Tools**: make, cmake, pkg-config, build-essential
- **Version Control**: Git integration

### CUDA 12.6 Complete Toolkit
- **CUDA Compiler**: nvcc (CUDA C++ compiler)
- **CUDA Libraries**: cuBLAS, cuFFT, cuRAND, cuSOLVER, cuSPARSE
- **CUDA Runtime**: Full runtime và development libraries
- **Environment**: Biến môi trường CUDA được cấu hình đầy đủ

### Machine Learning Stack
- **Deep Learning**: PyTorch, TensorFlow, Keras với CUDA support
- **GPU Computing**: CuPy, Numba, JAX với CUDA 12.6
- **Data Science**: NumPy, Pandas, Scikit-learn, Matplotlib, Seaborn
- **Computer Vision**: OpenCV, Pillow
- **Kubeflow**: KFP (Kubeflow Pipelines) integration

### VSCode Extensions
- **Python**: Microsoft Python với IntelliSense
- **Jupyter**: Full Jupyter notebook support
- **Docker**: Docker và container integration
- **Kubernetes**: Kubernetes tools và resource management
- **Remote Development**: Remote container development
- **Code Quality**: Black formatter, Flake8 linter, DebugPy

## 📋 Yêu cầu hệ thống

- Docker với GPU support (NVIDIA Container Toolkit)
- NVIDIA GPU với drivers tương thích CUDA 12.6
- Tối thiểu 8GB RAM và 20GB disk space
- Kubeflow 1.10.0 hoặc mới hơn

## 🛠️ Build và Deploy

### Build Image

```bash
# Build cho architecture hiện tại
make build

# Build và push multi-arch image
make buildx-push
```

### Chạy Local để Test

```bash
# Run với GPU support
make run

# Run với privileged mode cho đầy đủ chức năng
make run-privileged
```

### Truy cập VSCode

Sau khi chạy, mở browser tại: `http://localhost:8888`

## ⚙️ Tùy chỉnh Build

Bạn có thể tùy chỉnh các phiên bản và cài đặt:

```bash
# Custom tag và base image
export TAG=v2.0.0
export BASE_IMAGE=ghcr.io/kubeflow/kubeflow/notebook-servers/codeserver-python:v1.9.2

# Custom phiên bản
export CUDA_VERSION=12.6.2
export CODESERVER_VERSION=4.96.4
export GCC_VERSION=11.4.0

# Build với custom settings
make build
```

## 🧪 Testing và Validation

### Test CUDA

```bash
# Test NVIDIA drivers
make test-cuda

# Test CUDA Python integration
make test-cuda-compatibility
```

### Test Kubeflow Compliance

```bash
# Test tuân thủ Kubeflow
make test-kubeflow

# Test VSCode functionality
make test-vscode
```

### Manual Testing trong VSCode Terminal

```python
# Test PyTorch với CUDA
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

## 📁 Cấu trúc thư mục

```
vscode-cuda-v2/
├── Dockerfile                    # Main Dockerfile (mở rộng codeserver-python)
├── Makefile                     # Build automation
├── requirements.txt             # Python packages list
├── README.md                    # Documentation
└── s6/
    ├── cont-init.d/
    │   ├── 01-setup-cuda-env    # CUDA environment setup
    │   └── 02-cors-proxy-setup  # CORS và NB_PREFIX support
    └── services.d/
        └── code-server/
            └── run              # Service startup script
```

## 🌐 Integration với Kubeflow

### Sử dụng trong Kubeflow Dashboard

1. Build và push image到 registry của bạn
2. Trong Kubeflow, tạo notebook mới
3. Chọn custom image: `your-registry/vscode-cuda-v2:v1.10.0`

### Example Notebook Config

```yaml
apiVersion: kubeflow.org/v1
kind: Notebook
metadata:
  name: vscode-cuda-v2-notebook
spec:
  template:
    spec:
      containers:
      - name: vscode-cuda-v2
        image: your-registry/kubeflownotebookswg/vscode-cuda-v2:v1.9.2
        resources:
          limits:
            nvidia.com/gpu: 1
          requests:
            cpu: "4"
            memory: "16Gi"
        env:
        - name: NB_PREFIX
          value: "/notebook/vscode-cuda-v2"
```

## 🔧 Environment Variables

Image này bao gồm các biến môi trường sau:

### Kubeflow (kế thừa từ base)
- `NB_USER=jovyan`: User name
- `NB_UID=1000`: User ID
- `NB_GID=0`: Group ID
- `NB_PREFIX=/`: URL prefix (được set bởi Kubeflow)
- `HOME=/home/jovyan`: Home directory

### CUDA
- `NVIDIA_VISIBLE_DEVICES=all`: Make all GPUs visible
- `NVIDIA_DRIVER_CAPABILITIES=compute,utility,compat32`
- `NVIDIA_REQUIRE_CUDA=cuda>=12.6`
- `CUDA_HOME=/usr/local/cuda`
- `CUDA_ROOT=/usr/local/cuda`
- `CUDA_PATH=/usr/local/cuda`
- `LD_LIBRARY_PATH`: Includes CUDA library paths
- `PATH`: Includes CUDA binary paths

### Conda/Python
- `CONDA_DIR=/opt/conda`
- `PATH`: Includes conda binaries

## 🐛 Troubleshooting

### Common Issues

1. **GPU không được detect**:
   - Kiểm tra NVIDIA Container Toolkit đã được install và working
   - Chạy `docker run --rm --gpus all nvidia/cuda:12.6.2-base-ubuntu22.04 nvidia-smi`

2. **CUDA version mismatch**:
   - Kiểm tra NVIDIA drivers có support CUDA 12.6
   - Verify driver version với `nvidia-smi`

3. **Memory issues**:
   - Tăng Docker memory allocation tối thiểu 8GB
   - Monitor với `docker stats`

4. **Permissions issues**:
   - Image đã được cấu hình cho arbitrary UIDs
   - Kiểm tra PVC permissions trong Kubernetes

### Debug Commands

```bash
# Check Docker GPU support
docker run --rm --gpus all nvidia/cuda:12.6.2-base-ubuntu22.04 nvidia-smi

# Check image layers
docker history $(IMG)-$(ARCH)

# Inspect running container
docker inspect <container_id>

# Check container logs
docker logs <container_id>
```

## 🔄 Upgrade Path

Để upgrade từ các Kubeflow image khác:

1. **Từ base codeserver**: Chỉ cần thêm CUDA packages
2. **Từ jupyter images**: Thêm code-server và proxy setup
3. **Từ custom images**: Merge Dockerfile sections này

## 📄 License

Project này tuân thủ Apache 2.0 license như Kubeflow.

## 🤝 Contributing

1. Fork repository
2. Create feature branch
3. Test kỹ lưỡng (đặc biệt là CUDA và Kubeflow compliance)
4. Submit pull request

## 📞 Support

- **Kubeflow Issues**: [Kubeflow GitHub](https://github.com/kubeflow/kubeflow/issues)
- **CUDA Support**: [NVIDIA CUDA Forums](https://forums.developer.nvidia.com/c/cuda)
- **Code-Server Issues**: [Code-Server GitHub](https://github.com/coder/code-server/issues)

---

**🎉 Ready for Kubeflow!** Image này được thiết kế để hoạt động seamlessly với Kubeflow Notebooks, cung cấp môi trường phát triển VSCode đầy đủ với CUDA support cho machine learning và data science workflows.