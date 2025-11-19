# CodeServer Python with Rootless Docker

A secure Kubeflow notebook server that combines VS Code (Code Server), Python development environment, and **rootless Docker** for safe container building within notebooks.

## 🚀 Features

### 🛡️ Security-First Design
- **Rootless Docker**: Docker daemon runs without root privileges
- **Isolated Environment**: Containers are isolated from host system
- **No Privilege Escalation**: Users cannot gain root access on the host
- **User Namespaces**: Additional isolation for container processes

### 💻 Development Environment
- **VS Code in Browser**: Full IDE experience with extensions
- **Python 3.11**: Latest Python with Conda package management
- **Jupyter Support**: Native Jupyter notebook integration
- **Docker Tools**: CLI, BuildKit, and Docker Compose included

### ⚡ Performance Optimized
- **BuildKit**: Modern Docker build engine
- **Efficient Storage**: Optimized layer caching
- **Fast Startup**: Optimized container initialization

## 📋 Prerequisites

- Kubernetes 1.24+ (for user namespace support)
- Container runtime that supports user namespaces (containerd 1.7+ recommended)
- Kubeflow v1.7+ (for full PVC management)
- Minimum 4GB RAM and 2 CPU cores per notebook

## 🔧 Quick Start

### 1. Build the Image

```bash
# Build for current architecture
make docker-build

# Build and push to registry
make docker-build-push

# Build multi-architecture
make docker-build-multi-arch
```

### 2. Deploy with Kubeflow

```bash
# Apply the notebook CR
kubectl apply -f kubeflow-notebook.yaml

# Or create via Kubeflow UI using the image:
# ghcr.io/kubeflow/kubeflow/notebook-servers/codeserver-python-rootless:latest
```

### 3. Verify Docker Functionality

Access your notebook and run:

```bash
# Check Docker version
docker --version

# Test Docker daemon
docker info

# Build and run a test container
echo "FROM alpine:latest
RUN echo 'Rootless Docker works!' > /test.txt
CMD cat /test.txt" > Dockerfile

docker build -t test-image .
docker run test-image
```

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│          Kubeflow Notebook          │
│  ┌─────────────────────────────┐    │
│  │    Code Server (VS Code)    │    │
│  │  ┌─────────────────────┐    │    │
│  │  │   Python + Conda    │    │    │
│  │  └─────────────────────┘    │    │
│  │  ┌─────────────────────┐    │    │
│  │  │   Rootless Docker   │    │    │
│  │  │  ┌─────────────┐   │    │    │
│  │  │  │ Your Apps   │   │    │    │
│  │  │  └─────────────┘   │    │    │
│  │  └─────────────────────┘    │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

## 📁 Directory Structure

```
codeserver-python-rootless/
├── Dockerfile                    # Main image definition
├── Makefile                      # Build targets
├── requirements.txt              # Python packages
├── README.md                     # This file
├── k8s-manifest.yaml            # Kubernetes deployment example
├── kubeflow-notebook.yaml       # Kubeflow Notebook CRD example
├── home/                        # Home directory contents
│   └── README__CODESERVER_PYTHON_ROOTLESS.md
└── s6/                          # Service management
    ├── cont-init.d/
    │   └── 02-setup-rootless-docker  # Docker setup script
    └── services.d/
        └── dockerd/
            ├── run                  # Docker daemon start
            └── finish               # Docker daemon stop
```

## 🔒 Security Considerations

### What's Secured
- ✅ No root access on host system
- ✅ User namespace isolation
- ✅ Container process isolation
- ✅ Network isolation (by default)
- ✅ File system isolation

### Limitations
- ❌ Cannot bind host ports < 1024
- ❌ Cannot access host network directly
- ❌ Some privileged Docker features unavailable
- ❌ Slightly slower performance than privileged Docker

### Best Practices
1. **Resource Limits**: Always set memory and CPU limits
2. **Storage**: Use dedicated PVCs for Docker storage
3. **Network**: Use NetworkPolicies to restrict access
4. **Images**: Scan built images for vulnerabilities
5. **Cleanup**: Regularly clean unused containers/images

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOCKER_HOST` | `unix:///home/jovyan/.local/share/docker/docker.sock` | Docker daemon socket |
| `DOCKER_CONFIG` | `/home/jovyan/.config/docker` | Docker configuration directory |
| `CONDA_DIR` | `/opt/conda` | Conda installation directory |

### Docker Daemon Configuration

```json
{
  "storage-driver": "overlay2",
  "userland-proxy": false,
  "experimental": false,
  "features": {
    "buildkit": true
  }
}
```

## 📊 Resource Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **Memory** | 4GB | 8GB |
| **CPU** | 2 cores | 4 cores |
| **Storage** | 30GB | 50GB |
| **Docker Storage** | 10GB | 20GB |

## 🐛 Troubleshooting

### Docker Daemon Issues

```bash
# Check if Docker daemon is running
ps aux | grep dockerd

# Check Docker logs
journalctl -u dockerd --user

# Docker daemon logs
cat ~/.local/share/docker/docker.log

# Restart Docker daemon
# (Container restart will handle this)
```

### Permission Issues

```bash
# Check Docker socket permissions
ls -la ~/.local/share/docker/docker.sock

# Verify user namespace support
unshare --user true echo "User namespaces supported"
```

### Performance Issues

```bash
# Check resource usage
docker stats

# Clean up unused Docker resources
docker system prune -a

# Monitor container size
docker system df
```

### Common Issues

#### Issue: "Docker daemon not running"
```bash
# Solution: Check if container has proper startup time
# Increase liveness/readiness probe initialDelaySeconds
```

#### Issue: "Permission denied" errors
```bash
# Solution: Check security context and user IDs
# Ensure runAsUser: 1000 and runAsGroup: 0
```

#### Issue: Out of space errors
```bash
# Solution: Increase PVC sizes for Docker storage
# or implement regular cleanup
docker system prune -a --volumes
```

## 🔄 Building and Updating

### Build Arguments

```bash
# Docker versions
DOCKER_VERSION=27.4.1
DOCKER_COMPOSE_VERSION=2.30.3
DOCKER_BUILDX_VERSION=0.19.3

# Python versions
PYTHON_VERSION=3.11.11
CONDA_VERSION=24.11.3-0
```

### Build Process

```bash
# Build locally
make docker-build

# Build with custom tag
make docker-build TAG=v1.0.0

# Build multi-architecture
make docker-build-multi-arch ARCH="linux/amd64,linux/arm64"

# Push to registry
REGISTRY=your-registry.com make docker-push
```

## 📚 Examples

### Machine Learning Pipeline

```python
import docker
import kfp

# Build a custom training container
client = docker.from_env()
client.images.build(path="./trainer", tag="custom-trainer")

# Use in Kubeflow pipeline
@kfp.dsl.component
def train_model():
    return kfp.dsl.ContainerOp(
        name='training',
        image='custom-trainer',
        command=['python', 'train.py'],
        resources={
            'memory_limit': '4G',
            'cpu_limit': '2'
        }
    )
```

### Web App Development

```bash
# Create a Flask app
cat > app.py << 'EOF'
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello from Docker!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY app.py .
RUN pip install flask
EXPOSE 8080
CMD ["python", "app.py"]
EOF

# Build and run
docker build -t flask-app .
docker run -d -p 8080:8080 --name my-app flask-app
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly with Docker operations
5. Submit a pull request

## 📄 License

This project follows the same license as Kubeflow.

## 🙋‍♂️ Support

- **Kubeflow Documentation**: https://www.kubeflow.org/docs/
- **Docker Rootless**: https://docs.docker.com/engine/security/rootless/
- **Code Server**: https://github.com/coder/code-server
- **Issues**: Create an issue in the Kubeflow repository

---

**Note**: This image is designed for development and experimentation. For production workloads, ensure proper security reviews and compliance with your organization's policies.