#!/bin/bash

# Build and Test Script for CodeServer Python Rootless Docker
# This script helps build the image and validate Docker functionality

set -euo pipefail

# Configuration
REGISTRY=${REGISTRY:-"ghcr.io/kubeflow/kubeflow/notebook-servers"}
TAG=${TAG:-"latest"}
IMAGE_NAME="codeserver-python-rootless"
IMAGE_REF="${REGISTRY}/${IMAGE_NAME}:${TAG}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi

    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi

    # Check if buildx is available
    if ! docker buildx version &> /dev/null; then
        log_warning "Docker buildx is not available, using regular build"
        USE_BUILDX=false
    else
        USE_BUILDX=true
    fi

    log_success "Prerequisites check passed"
}

# Build the image
build_image() {
    log_info "Building image: ${IMAGE_REF}"

    cd "$(dirname "$0")"

    if [ "$USE_BUILDX" = true ]; then
        docker buildx build \
            --load \
            --build-arg BASE_IMG=ghcr.io/kubeflow/kubeflow/notebook-servers/codeserver:latest \
            --tag "${IMAGE_REF}" \
            -f Dockerfile \
            .
    else
        docker build \
            --build-arg BASE_IMG=ghcr.io/kubeflow/kubeflow/notebook-servers/codeserver:latest \
            --tag "${IMAGE_REF}" \
            -f Dockerfile \
            .
    fi

    log_success "Image built successfully: ${IMAGE_REF}"
}

# Test the image
test_image() {
    log_info "Testing image functionality..."

    # Create a temporary container for testing
    CONTAINER_NAME="test-${IMAGE_NAME}-$$"

    # Start the container
    log_info "Starting test container..."
    docker run -d \
        --name "${CONTAINER_NAME}" \
        -p 8080:8080 \
        "${IMAGE_REF}"

    # Wait for container to be ready
    log_info "Waiting for container to be ready..."
    for i in {1..30}; do
        if docker exec "${CONTAINER_NAME}" curl -s http://localhost:8080/healthz &> /dev/null; then
            log_success "Container is ready after ${i} seconds"
            break
        fi

        if [ $i -eq 30 ]; then
            log_error "Container failed to become ready within 30 seconds"
            docker logs "${CONTAINER_NAME}"
            cleanup_container
            exit 1
        fi

        sleep 1
    done

    # Test Python environment
    log_info "Testing Python environment..."
    if docker exec "${CONTAINER_NAME}" python --version &> /dev/null; then
        log_success "Python is working"
    else
        log_error "Python is not working"
        docker logs "${CONTAINER_NAME}"
        cleanup_container
        exit 1
    fi

    # Test Conda
    log_info "Testing Conda environment..."
    if docker exec "${CONTAINER_NAME}" conda --version &> /dev/null; then
        log_success "Conda is working"
    else
        log_error "Conda is not working"
        docker logs "${CONTAINER_NAME}"
        cleanup_container
        exit 1
    fi

    # Test Docker CLI
    log_info "Testing Docker CLI..."
    if docker exec "${CONTAINER_NAME}" docker --version &> /dev/null; then
        log_success "Docker CLI is working"
    else
        log_error "Docker CLI is not working"
        docker logs "${CONTAINER_NAME}"
        cleanup_container
        exit 1
    fi

    # Wait for Docker daemon to be ready (can take some time)
    log_info "Waiting for Docker daemon to be ready..."
    for i in {1..60}; do
        if docker exec "${CONTAINER_NAME}" docker info &> /dev/null; then
            log_success "Docker daemon is ready after ${i} seconds"
            break
        fi

        if [ $i -eq 60 ]; then
            log_error "Docker daemon failed to become ready within 60 seconds"
            docker exec "${CONTAINER_NAME}" cat /home/jovyan/.local/share/docker/docker.log || true
            cleanup_container
            exit 1
        fi

        sleep 1
    done

    # Test Docker operations
    log_info "Testing Docker operations..."

    # Test building an image
    docker exec "${CONTAINER_NAME}" sh -c "
        echo 'FROM alpine:latest
RUN echo \"Rootless Docker test successful!\" > /test.txt
CMD cat /test.txt' > /tmp/Dockerfile
    "

    if docker exec "${CONTAINER_NAME}" docker build -t test-image /tmp/ &> /dev/null; then
        log_success "Docker build is working"
    else
        log_error "Docker build failed"
        cleanup_container
        exit 1
    fi

    # Test running a container
    if docker exec "${CONTAINER_NAME}" docker run --rm test-image | grep -q "Rootless Docker test successful"; then
        log_success "Docker container execution is working"
    else
        log_error "Docker container execution failed"
        cleanup_container
        exit 1
    fi

    # Test Docker Compose
    log_info "Testing Docker Compose..."
    if docker exec "${CONTAINER_NAME}" docker compose version &> /dev/null; then
        log_success "Docker Compose is working"
    else
        log_warning "Docker Compose is not working"
    fi

    log_success "All tests passed successfully!"
}

# Cleanup function
cleanup_container() {
    log_info "Cleaning up test container..."
    docker stop "${CONTAINER_NAME}" &> /dev/null || true
    docker rm "${CONTAINER_NAME}" &> /dev/null || true
}

# Run integration tests
run_integration_tests() {
    log_info "Running integration tests..."

    CONTAINER_NAME="integration-test-${IMAGE_NAME}-$$"

    # Start container with volume mount
    docker run -d \
        --name "${CONTAINER_NAME}" \
        -p 8081:8080 \
        -v "$(pwd)/test-data:/home/jovyan/test-data" \
        "${IMAGE_REF}"

    # Wait for container to be ready
    for i in {1..30}; do
        if docker exec "${CONTAINER_NAME}" curl -s http://localhost:8080/healthz &> /dev/null; then
            break
        fi
        sleep 1

        if [ $i -eq 30 ]; then
            log_error "Integration test container failed to become ready"
            cleanup_container
            exit 1
        fi
    done

    # Test Python package installation
    docker exec "${CONTAINER_NAME}" pip install requests &> /dev/null
    if docker exec "${CONTAINER_NAME}" python -c "import requests; print('Python package installation successful')" &> /dev/null; then
        log_success "Python package installation test passed"
    else
        log_error "Python package installation test failed"
        cleanup_container
        exit 1
    fi

    # Test building a more complex Docker image
    docker exec "${CONTAINER_NAME}" sh -c "
        cat > /tmp/python-app/Dockerfile << 'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
EXPOSE 8080
CMD ['python', 'app.py']
EOF

        cat > /tmp/python-app/requirements.txt << 'EOF'
flask==3.0.0
EOF

        cat > /tmp/python-app/app.py << 'EOF'
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello from Flask built with rootless Docker!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF
    "

    if docker exec "${CONTAINER_NAME}" docker build -t python-test-app /tmp/python-app/ &> /dev/null; then
        log_success "Complex Docker build test passed"
    else
        log_error "Complex Docker build test failed"
        cleanup_container
        exit 1
    fi

    cleanup_container
    log_success "Integration tests passed"
}

# Push image (optional)
push_image() {
    if [ "${SKIP_PUSH:-false}" = "true" ]; then
        log_info "Skipping image push"
        return
    fi

    log_info "Pushing image: ${IMAGE_REF}"
    docker push "${IMAGE_REF}"
    log_success "Image pushed successfully"
}

# Main execution
main() {
    log_info "Starting build and test process for ${IMAGE_NAME}"

    check_prerequisites
    build_image
    test_image
    run_integration_tests
    push_image

    log_success "Build and test process completed successfully!"
    log_info "Image: ${IMAGE_REF}"
    log_info "Ready for deployment in Kubeflow!"
}

# Cleanup on exit
trap cleanup_container EXIT

# Parse command line arguments
case "${1:-}" in
    --skip-push)
        export SKIP_PUSH=true
        main
        ;;
    --test-only)
        log_info "Running tests only (assuming image already exists)"
        test_image
        run_integration_tests
        ;;
    --build-only)
        check_prerequisites
        build_image
        ;;
    *)
        main
        ;;
esac