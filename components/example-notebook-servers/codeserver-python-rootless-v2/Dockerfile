FROM quay.io/jupyter/base-notebook:python-3.13

USER root

# Cài các package cần thiết cho Docker rootless
RUN apt-get update && apt-get install -y \
    dbus-user-session uidmap fuse-overlayfs slirp4netns iptables iproute2 curl git \
    && rm -rf /var/lib/apt/lists/*

# Tải và cài Docker rootless thủ công (bypass script chặn root)
ENV DOCKER_VERSION=27.3.1
RUN curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-rootless-extras-${DOCKER_VERSION}.tgz \
    | tar -xz -C /usr/local/bin --strip-components=1 \
        docker-rootless-extras-${DOCKER_VERSION}/rootlesskit \
        docker-rootless-extras-${DOCKER_VERSION}/vpnkit \
        docker-rootless-extras-${DOCKER_VERSION}/docker-proxy \
    && curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz \
    | tar -xz -C /usr/local/bin --strip-components=1 docker/docker \
    && dockerd --version && docker --version

# Cài binfmt-support (nếu muốn build multi-arch)
RUN apt-get update && apt-get install -y binfmt-support qemu-user-static && rm -rf /var/lib/apt/lists/*

# Tạo thư mục và symlink cho user jovyan
RUN mkdir -p /home/jovyan/bin \
    && ln -s /usr/local/bin/docker /home/jovyan/bin/docker \
    && ln -s /usr/local/bin/dockerd-rootless.sh /home/jovyan/bin/dockerd-rootless.sh \
    && ln -s /usr/local/bin/rootlesskit /home/jovyan/bin/rootlesskit

# Cấp đủ subuid/subgid cho jovyan (uid 1000)
RUN echo "jovyan:100000:65536" >> /etc/subuid \
    && echo "jovyan:100000:65536" >> /etc/subgid

# Config rootless Docker
RUN mkdir -p /home/jovyan/.config/docker \
    && mkdir -p /home/jovyan/.config/systemd/user \
    && chown -R jovyan:users /home/jovyan

USER jovyan

# Config storage dùng fuse-overlayfs (ổn định nhất)
RUN mkdir -p ~/.config/containers && \
    cat > ~/.config/containers/storage.conf <<EOF
[storage]
driver = "overlay"
runroot = "/tmp/containers"
graphroot = "/home/jovyan/.local/share/containers/storage"

[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
mountopt = "nodev,fsync=0"
EOF

ENV PATH=/home/jovyan/bin:$PATH \
    DOCKER_HOST=unix:///run/user/1000/docker.sock \
    XDG_RUNTIME_DIR=/run/user/1000

# Khởi động dockerd rootless khi container start (nếu cần tự động)
# CMD ["sh", "-c", "dockerd-rootless.sh &> /tmp/dockerd.log & jupyter lab"]