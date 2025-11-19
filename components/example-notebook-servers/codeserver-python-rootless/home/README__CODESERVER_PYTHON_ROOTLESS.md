# Code Server + Python + Rootless Docker

This notebook image provides:

- **Code Server**: A web-based IDE that runs VS Code in your browser
- **Python**: Full Python development environment with Conda package management
- **Rootless Docker**: Docker daemon running in rootless mode for secure container building

## Key Features

### 🔒 Rootless Docker Security
- Docker daemon runs without root privileges
- Isolated container environment
- Secure building and running of containers within your notebook
- No host access escalation risks

### 🐍 Python Environment
- Conda package manager included
- Pre-installed Jupyter support in VS Code
- Full access to PyPI packages
- Python kernel for Jupyter notebooks

### 📦 Pre-installed Tools
- Docker CLI, Buildx, and Compose
- kubectl for Kubernetes interaction
- Git for version control
- Full VS Code extensions for Python and Jupyter

## Getting Started

### 1. Initialize Rootless Docker
```bash
# This is automatically done on container start, but if needed:
docker-rootless-setup.sh
```

### 2. Verify Docker Installation
```bash
docker --version
docker-compose --version
docker info
```

### 3. Build and Run a Container
```bash
# Build a simple Docker image
echo "FROM alpine:latest
RUN echo 'Hello from rootless Docker!' > /hello.txt
CMD cat /hello.txt" > Dockerfile

docker build -t my-test-image .
docker run my-test-image
```

### 4. Use Docker in Python
```python
import docker

client = docker.from_env()
# List running containers
print(client.containers.list())
```

## Environment Variables

- `DOCKER_HOST`: Unix socket for rootless Docker daemon
- `DOCKER_CONFIG`: Configuration directory for Docker
- `CONDA_DIR`: Conda installation directory

## Important Notes

### Security
- ✅ Docker runs in rootless mode (no root privileges)
- ✅ Containers are isolated from the host
- ✅ No host file system access from containers
- ✅ User namespaces provide additional isolation

### Limitations
- Some privileged Docker features won't work
- Cannot bind host ports below 1024
- Slightly slower performance than privileged Docker
- Cannot access host network directly

### Best Practices
- Always specify resource limits for containers
- Use official base images when possible
- Scan images for vulnerabilities
- Clean up unused containers and images regularly

## Troubleshooting

### Docker Daemon Not Starting
```bash
# Check if Docker daemon is running
ps aux | grep dockerd

# Restart rootless Docker
docker-rootless-setup.sh
```

### Permission Issues
```bash
# Ensure correct permissions
ls -la ~/.local/share/docker/
```

### Container Issues
```bash
# Check Docker logs
journalctl -u dockerd --user

# Docker daemon logs
cat ~/.local/share/docker/docker.log
```

## Examples

### Machine Learning Pipeline
```python
import docker
import kfp

# Build a custom training container
client = docker.from_env()
client.images.build(path="./training-image", tag="custom-training")

# Use in Kubeflow pipeline
@kfp.dsl.component
def train_component():
    return kfp.dsl.ContainerOp(
        name='training',
        image='custom-training',
        ...
    )
```

### Development Workflow
```bash
# Clone a repository
git clone https://github.com/user/repo.git
cd repo

# Build development environment
docker build -t dev-env .

# Run development container
docker run -it --rm -v $(pwd):/workspace dev-env
```

## Support

For issues related to:
- **Kubeflow**: Check [Kubeflow documentation](https://www.kubeflow.org/docs/)
- **Docker Rootless**: Check [Docker documentation](https://docs.docker.com/engine/security/rootless/)
- **Code Server**: Check [Code Server documentation](https://github.com/coder/code-server)