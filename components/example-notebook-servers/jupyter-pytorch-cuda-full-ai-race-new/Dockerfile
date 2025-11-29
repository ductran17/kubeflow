#
# NOTE: Use the Makefiles to build this image correctly.
#

ARG BASE_IMG=docker.io/kubeflownotebookswg/jupyter-pytorch-cuda:v1.10.0-rc.1
FROM $BASE_IMG

# Update system packages
USER root
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -y \
    && apt-get install -y keyboard-configuration \
    && echo 'keyboard-configuration keyboard-configuration/layout select US' | debconf-set-selections \
    && echo 'keyboard-configuration keyboard-configuration/variant select US' | debconf-set-selections

# Install system dependencies required for MATLAB Runtime and Python
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y wget unzip xorg \
    libxext6 libx11-6 libglu1-mesa libxi6 libxtst6 libxrender1 \
    libxrandr2 libxinerama1 libxcursor1 libxcomposite1 libxdamage1 \
    libfontconfig1 libxss1 libasound2 \
    python3.10 python3.10-distutils python3-pip \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Download and install MATLAB Runtime R2025a
RUN mkdir -p /tmp/mcr_temp \
    && cd /tmp/mcr_temp \
    && wget -O matlab_runtime.zip https://ssd.mathworks.com/supportfiles/downloads/R2025a/Release/0/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2025a_glnxa64.zip \
    && unzip -q matlab_runtime.zip -d mcr_install \
    && mcr_install/install -mode silent -agreeToLicense yes -destinationFolder "/opt/mcr" \
    && rm -rf /tmp/mcr_temp

ENV MCR_ROOT=/opt/mcr/R2025a
ENV LD_LIBRARY_PATH=$MCR_ROOT/runtime/glnxa64:$MCR_ROOT/bin/glnxa64:$MCR_ROOT/sys/os/glnxa64:$MCR_ROOT/sys/opengl/lib/glnxa64:${LD_LIBRARY_PATH}
ENV XAPPLRESDIR=$MCR_ROOT/X11/app-defaults

USER ${NB_USER}

# install - conda packages
# NOTE: we use mamba to speed things up
RUN mamba install -y -q \
    bokeh==3.6.3 \
    cloudpickle==3.1.1 \
    dill==0.3.9 \
    ipympl==0.9.6 \
    matplotlib==3.10.0 \
    numpy==1.26.4 \
    pandas==2.2.3 \
    scikit-image==0.25.1 \
    scikit-learn==1.6.1 \
    scipy==1.15.1 \
    seaborn==0.13.2 \
    xgboost==2.1.4 \
 && mamba clean -a -f -y

# install - requirements.txt
COPY --chown=${NB_USER}:${NB_GID} requirements.txt /tmp/requirements.txt
RUN python3 -m pip install -r /tmp/requirements.txt --quiet --no-cache-dir \
 && rm -f /tmp/requirements.txt