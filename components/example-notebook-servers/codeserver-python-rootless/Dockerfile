#
# NOTE: Use the Makefiles to build this image correctly.
#

ARG BASE_IMG=<codeserver>
FROM $BASE_IMG

ARG TARGETARCH

USER root

# args - software versions
# https://open-vsx.org/extension/ms-python/python
# https://open-vsx.org/extension/ms-toolsai/jupyter
# https://github.com/ipython/ipykernel/releases
ARG CODESERVER_PYTHON_VERSION=2024.10.1
ARG CODESERVER_JUPYTER_VERSION=2024.10.0
ARG IPYKERNEL_VERSION=6.29.5
ARG MINIFORGE_VERSION=24.11.3-0
ARG PIP_VERSION=24.3.1
ARG PYTHON_VERSION=3.11.11
ARG DOCKER_VERSION=5:27.4.1-1~ubuntu.22.04~jammy
ARG DOCKER_COMPOSE_VERSION=2.40.3-1~ubuntu.22.04~jammy
ARG DOCKER_BUILDX_VERSION=0.19.3-1~ubuntu.22.04~jammy

# setup environment for conda
ENV CONDA_DIR /opt/conda
ENV PATH "${CONDA_DIR}/bin:${PATH}"
RUN mkdir -pv ${CONDA_DIR} \
 && chmod 2775 ${CONDA_DIR} \
 && echo ". /opt/conda/etc/profile.d/conda.sh" >> ${HOME}/.bashrc \
 && echo ". /opt/conda/etc/profile.d/conda.sh" >> /etc/profile \
 && echo "conda activate base" >> ${HOME}/.bashrc \
 && echo "conda activate base" >> /etc/profile

# Install Docker for rootless mode
RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get -yq update \
 && apt-get -yq install --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    uidmap \
    slirp4netns \
    fuse-overlayfs \
    unzip \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Add Docker's official GPG key
RUN mkdir -m 0755 -p /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
 && chmod a+r /etc/apt/keyrings/docker.gpg

# Set up the Docker repository
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null \
 && apt-get -yq update

# Install Docker CLI, Docker Buildx, and Docker Compose
RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get -yq install --no-install-recommends \
    docker-ce-cli=${DOCKER_VERSION} \
    docker-buildx-plugin=${DOCKER_BUILDX_VERSION} \
    docker-compose-plugin=${DOCKER_COMPOSE_VERSION} \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Install Docker Rootless setup script
RUN curl -fsSL https://get.docker.com/rootless -o /usr/local/bin/docker-rootless-setup.sh \
 && chmod +x /usr/local/bin/docker-rootless-setup.sh

# Create directories for rootless Docker
RUN mkdir -pv /home/${NB_USER}/.local/share/docker \
 && mkdir -pv /home/${NB_USER}/.config/docker \
 && mkdir -pv /home/${NB_USER}/bin

# Set up environment variables for rootless Docker
ENV DOCKER_HOST=unix:///home/${NB_USER}/.local/share/docker/docker.sock
ENV DOCKER_CONFIG=/home/${NB_USER}/.config/docker
ENV PATH="/home/${NB_USER}/bin:${PATH}"

# Install conda, pip, python as root for easier permission management
RUN case "${TARGETARCH}" in \
      amd64) MINIFORGE_ARCH="x86_64" ;; \
      arm64) MINIFORGE_ARCH="aarch64" ;; \
      ppc64le) MINIFORGE_ARCH="ppc64le" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac \
 && curl -fsSL "https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Miniforge3-${MINIFORGE_VERSION}-Linux-${MINIFORGE_ARCH}.sh" -o /tmp/Miniforge3.sh \
 && curl -fsSL "https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Miniforge3-${MINIFORGE_VERSION}-Linux-${MINIFORGE_ARCH}.sh.sha256" -o /tmp/Miniforge3.sh.sha256 \
 && echo "$(cat /tmp/Miniforge3.sh.sha256 | awk '{ print $1; }')  /tmp/Miniforge3.sh" | sha256sum -c - \
 && rm /tmp/Miniforge3.sh.sha256 \
 && /bin/bash /tmp/Miniforge3.sh -b -f -p ${CONDA_DIR} \
 && rm /tmp/Miniforge3.sh \
 && conda config --system --set auto_update_conda false \
 && conda config --system --set show_channel_urls true \
 && echo "python ==${PYTHON_VERSION}" >> ${CONDA_DIR}/conda-meta/pinned \
 && conda install -y -q \
    python=${PYTHON_VERSION} \
    pip=${PIP_VERSION} \
 && conda update -y -q --all \
 && conda clean -a -f -y

# install - ipykernel
# NOTE: we need this for jupyter codeserver extension to work
RUN echo "ipykernel ==${IPYKERNEL_VERSION}" >> ${CONDA_DIR}/conda-meta/pinned \
 && conda install -y -q \
    ipykernel==${IPYKERNEL_VERSION} \
 && conda clean -a -f -y

# Set ownership back to the notebook user
RUN chown -R ${NB_USER}:${NB_GID} ${CONDA_DIR} \
 && chown -R ${NB_USER}:${USERS_GID} ${HOME} \
 && chown -R ${NB_USER}:${NB_GID} /home/${NB_USER}/.local \
 && chown -R ${NB_USER}:${NB_GID} /home/${NB_USER}/.config

# install - requirements.txt
COPY --chown=${NB_USER}:${NB_GID} requirements.txt /tmp
RUN python3 -m pip install -r /tmp/requirements.txt --quiet --no-cache-dir \
 && rm -f /tmp/requirements.txt

# install - codeserver extensions
# RUN code-server --install-extension "ms-python.python@${CODESERVER_PYTHON_VERSION}" --force \
#  && code-server --install-extension "ms-toolsai.jupyter@${CODESERVER_JUPYTER_VERSION}" --force \
#  && code-server --list-extensions --show-versions

RUN code-server --install-extension ms-python.python --force \
 && code-server --install-extension ms-toolsai.jupyter --force \
 && code-server --list-extensions --show-versions

# home - pre-populate home with files for this image
COPY --chown=${NB_USER}:${NB_GID} home/. ${HOME}/

# s6 - 01-copy-tmp-home
# NOTE: the contents of $HOME_TMP are copied to $HOME at runtime
#       this is a workaround because a PVC will be mounted at $HOME
#       and the contents of $HOME will be hidden
RUN cp -p -r -T "${HOME}" "${HOME_TMP}" \
    # give group same access as user (needed for OpenShift)
 && chmod -R g=u "${HOME_TMP}"

# Copy rootless Docker initialization script
COPY --chown=${NB_USER}:${NB_GID} --chmod=755 s6/ /etc

USER $NB_UID