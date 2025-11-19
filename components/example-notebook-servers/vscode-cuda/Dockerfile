#
# NOTE: Use the Makefiles to build this image correctly.
#

ARG BASE_IMG=<jupyter>
FROM $BASE_IMG

ARG TARGETARCH

# args - software versions
ARG CODESERVER_VERSION=4.96.4
ARG CUDA_VERSION=12.6.2
ARG GCC_VERSION=11.4.0
ARG PYTHON_VERSION=3.11

# NVIDIA container toolkit configuration
# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/docker-specialized.html
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility,compat32
ENV NVIDIA_REQUIRE_CUDA "cuda>=12.6"

# Kubeflow environment variables (inherited from base image)
# NB_USER=jovyan, NB_UID=1000, NB_GID=0, NB_PREFIX=/, HOME=/home/jovyan

USER root

# Update package lists and install basic dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg2 \
    lsb-release \
    ca-certificates \
    software-properties-common \
    apt-transport-https \
    build-essential \
    git \
    vim \
    nano \
    nginx \
    socat \
    && rm -rf /var/lib/apt/lists/*

# Add NVIDIA CUDA repository
RUN curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub | apt-key add - \
    && echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64 /" > /etc/apt/sources.list.d/cuda.list \
    && apt-get update

# Install GCC and development tools
RUN apt-get update && apt-get install -y \
    gcc-${GCC_VERSION} \
    g++-${GCC_VERSION} \
    gcc-${GCC_VERSION}-multilib \
    g++-${GCC_VERSION}-multilib \
    libc6-dev \
    libc6-dev-i386 \
    linux-libc-dev \
    linux-libc-dev:i386 \
    make \
    cmake \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install CUDA toolkit
RUN apt-get update && apt-get install -y \
    cuda-toolkit-${CUDA_VERSION%.*} \
    cuda-compiler-${CUDA_VERSION%.*} \
    cuda-libraries-dev-${CUDA_VERSION%.*} \
    cuda-cudart-dev-${CUDA_VERSION%.*} \
    cuda-cufft-dev-${CUDA_VERSION%.*} \
    cuda-curand-dev-${CUDA_VERSION%.*} \
    cuda-cusolver-dev-${CUDA_VERSION%.*} \
    cuda-cusparse-dev-${CUDA_VERSION%.*} \
    cuda-nvrtc-dev-${CUDA_VERSION%.*} \
    cuda-nvtx-dev-${CUDA_VERSION%.*} \
    libcublas-dev-${CUDA_VERSION%.*} \
    libcufft-dev-${CUDA_VERSION%.*} \
    libcurand-dev-${CUDA_VERSION%.*} \
    libcusolver-dev-${CUDA_VERSION%.*} \
    libcusparse-dev-${CUDA_VERSION%.*} \
    && rm -rf /var/lib/apt/lists/*

# Install code-server
RUN curl -fsSL "https://github.com/coder/code-server/releases/download/v${CODESERVER_VERSION}/code-server_${CODESERVER_VERSION}_${TARGETARCH}.deb" -o /tmp/code-server.deb \
    && dpkg -i /tmp/code-server.deb \
    && rm -f /tmp/code-server.deb

# Install VSCode extensions for Kubeflow development
RUN code-server --install-extension ms-python.python \
    && code-server --install-extension ms-toolsai.jupyter \
    && code-server --install-extension ms-toolsai.jupyter-renderers \
    && code-server --install-extension ms-toolsai.jupyter-keymap \
    && code-server --install-extension ms-azuretools.vscode-docker \
    && code-server --install-extension ms-kubernetes-tools.vscode-kubernetes-tools \
    && code-server --install-extension ms-vscode-remote.remote-containers \
    && code-server --install-extension ms-python.flake8 \
    && code-server --install-extension ms-python.black-formatter

# Set up symbolic links for CUDA
RUN ln -sf /usr/local/cuda-${CUDA_VERSION%.*} /usr/local/cuda

# Environment variables for CUDA
ENV PATH=$PATH:/usr/local/cuda/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64
ENV CUDA_HOME=/usr/local/cuda
ENV CUDA_ROOT=/usr/local/cuda
ENV CUDA_PATH=/usr/local/cuda

# Python environment setup for CUDA
RUN python3 -m pip install --quiet --no-cache-dir \
    nvidia-cuda-runtime-cu12==${CUDA_VERSION%.*}.* \
    nvidia-cuda-nvrtc-cu12==${CUDA_VERSION%.*}.* \
    nvidia-cublas-cu12==${CUDA_VERSION%.*}.* \
    nvidia-cufft-cu12==${CUDA_VERSION%.*}.* \
    nvidia-curand-cu12==${CUDA_VERSION%.*}.* \
    nvidia-cusolver-cu12==${CUDA_VERSION%.*}.* \
    nvidia-cusparse-cu12==${CUDA_VERSION%.*}.* \
    cupy-cuda12x \
    numba \
    jax[cuda12_pip] \
    pynvml

# s6 - copy scripts for container initialization
COPY --chown=${NB_USER}:${NB_GID} --chmod=755 s6/ /etc

# Create workspace directory
RUN mkdir -p /workspace && chown ${NB_USER}:${NB_GID} /workspace

# Switch back to notebook user
USER $NB_UID

# Set working directory
WORKDIR /workspace

# Expose port for code-server
EXPOSE 8888

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8888/ || exit 1