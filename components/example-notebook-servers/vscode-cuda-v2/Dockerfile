#
# NOTE: Use the Makefiles to build this image correctly.
#

ARG BASE_IMG=ghcr.io/kubeflow/kubeflow/notebook-servers/codeserver-python:v1.9.2
FROM $BASE_IMG

ARG TARGETARCH

# args - software versions
ARG CODESERVER_VERSION=4.96.4
ARG CUDA_VERSION=12.6.2
ARG GCC_VERSION=11
ARG PYTHON_VERSION=3.11.11
ARG CODESERVER_PYTHON_VERSION=2025.0.0
ARG CODESERVER_JUPYTER_VERSION=2024.11.0
ARG IPYKERNEL_VERSION=6.29.5
ARG MINIFORGE_VERSION=24.11.3-0
ARG PIP_VERSION=24.3.1

# NVIDIA container toolkit configuration
# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/docker-specialized.html
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility,compat32
ENV NVIDIA_REQUIRE_CUDA "cuda>=12.6"

# Kubeflow environment variables (inherited from base image)
# NB_USER=jovyan, NB_UID=1000, NB_GID=0, NB_PREFIX=/, HOME=/home/jovyan

USER root

# Install additional system dependencies
RUN export DEBIAN_FRONTEND=noninteractive \
 && dpkg --add-architecture i386 \
 && apt-get -yq update \
 && apt-get -yq install --no-install-recommends \
    wget \
    curl \
    gnupg2 \
    lsb-release \
    ca-certificates \
    software-properties-common \
    apt-transport-https \
    build-essential \
    gcc-${GCC_VERSION} \
    g++-${GCC_VERSION} \
    gcc-${GCC_VERSION}-multilib \
    g++-${GCC_VERSION}-multilib \
    libc6-dev \
    libc6-dev:i386 \
    linux-libc-dev \
    make \
    cmake \
    pkg-config \
    nginx \
    socat \
    git \
    vim \
    nano \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Add NVIDIA CUDA repository
RUN curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub | apt-key add - \
    && echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64 /" > /etc/apt/sources.list.d/cuda.list \
    && apt-get update

# Install CUDA toolkit
RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get -yq install --no-install-recommends \
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
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Set up symbolic links for CUDA
RUN ln -sf /usr/local/cuda-${CUDA_VERSION%.*} /usr/local/cuda

# Environment variables for CUDA
ENV PATH=$PATH:/usr/local/cuda/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64
ENV CUDA_HOME=/usr/local/cuda
ENV CUDA_ROOT=/usr/local/cuda
ENV CUDA_PATH=/usr/local/cuda

USER $NB_UID

# Install CUDA Python packages
RUN echo "nvidia-cuda-runtime-cu12==${CUDA_VERSION%.*}.*" >> ${CONDA_DIR}/conda-meta/pinned \
 && echo "nvidia-cuda-nvrtc-cu12==${CUDA_VERSION%.*}.*" >> ${CONDA_DIR}/conda-meta/pinned \
 && echo "nvidia-cublas-cu12==${CUDA_VERSION%.*}.*" >> ${CONDA_DIR}/conda-meta/pinned \
 && echo "nvidia-cufft-cu12==${CUDA_VERSION%.*}.*" >> ${CONDA_DIR}/conda-meta/pinned \
 && echo "nvidia-curand-cu12==${CUDA_VERSION%.*}.*" >> ${CONDA_DIR}/conda-meta/pinned \
 && echo "nvidia-cusolver-cu12==${CUDA_VERSION%.*}.*" >> ${CONDA_DIR}/conda-meta/pinned \
 && echo "nvidia-cusparse-cu12==${CUDA_VERSION%.*}.*" >> ${CONDA_DIR}/conda-meta/pinned \
 && python3 -m pip install --quiet --no-cache-dir \
    cupy-cuda12x \
    numba \
    jax[cuda12_pip] \
    pynvml \
    torch \
    torchvision \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cu121

# Install additional ML/DL packages
RUN python3 -m pip install --quiet --no-cache-dir \
    tensorflow \
    keras \
    scikit-learn \
    pandas \
    numpy \
    matplotlib \
    seaborn \
    plotly \
    dash \
    streamlit \
    fastapi \
    uvicorn \
    requests \
    opencv-python \
    pillow

# Install additional VSCode extensions for CUDA and ML development
RUN code-server --install-extension "ms-python.black-formatter" --force \
 && code-server --install-extension "ms-python.flake8" --force \
 && code-server --install-extension "ms-toolsai.jupyter-renderers" --force \
 && code-server --install-extension "ms-toolsai.jupyter-keymap" --force \
 && code-server --install-extension "ms-azuretools.vscode-docker" --force \
 && code-server --install-extension "ms-kubernetes-tools.vscode-kubernetes-tools" --force \
 && code-server --install-extension "ms-vscode-remote.remote-containers" --force \
 && code-server --install-extension "ms-python.debugpy" --force \
 && code-server --list-extensions --show-versions

# home - pre-populate home with files for this image
COPY --chown=${NB_USER}:${NB_GID} home/. ${HOME}/

# s6 - copy scripts for container initialization
COPY --chown=${NB_USER}:${NB_GID} --chmod=755 s6/ /etc

# s6 - 01-copy-tmp-home
# NOTE: the contents of $HOME_TMP are copied to $HOME at runtime
#       this is a workaround because a PVC will be mounted at $HOME
#       and the contents of $HOME will be hidden
RUN cp -p -r -T "${HOME}" "${HOME_TMP}" \
    # give group same access as user (needed for OpenShift)
 && chmod -R g=u "${HOME_TMP}"