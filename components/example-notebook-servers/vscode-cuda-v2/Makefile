# Copyright 2023 The Kubeflow authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARCH ?= amd64
# Change this to match your Kubeflow version
TAG ?= v1.9.2
BASE_IMAGE ?= ghcr.io/kubeflow/kubeflow/notebook-servers/codeserver-python:v1.9.2
CUDA_VERSION ?= 12.6.2
CODESERVER_VERSION ?= 4.96.4
GCC_VERSION ?= 11

IMG ?= kubeflownotebookswg/vscode-cuda-v2:$(TAG)

# Docker build flags
DOCKER_BUILD_FLAGS ?= --no-cache

.PHONY: build build-arch buildx-push test-cuda test-kubeflow clean info

# Build the image for the current architecture
build:
	docker build $(DOCKER_BUILD_FLAGS) \
		--build-arg BASE_IMG=$(BASE_IMAGE) \
		--build-arg CODESERVER_VERSION=$(CODESERVER_VERSION) \
		--build-arg CUDA_VERSION=$(CUDA_VERSION) \
		--build-arg GCC_VERSION=$(GCC_VERSION) \
		--build-arg TARGETARCH=$(ARCH) \
		-t $(IMG)-$(ARCH) \
		.

# Build and push multi-arch image
buildx-push:
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		--build-arg BASE_IMG=$(BASE_IMAGE) \
		--build-arg CODESERVER_VERSION=$(CODESERVER_VERSION) \
		--build-arg CUDA_VERSION=$(CUDA_VERSION) \
		--build-arg GCC_VERSION=$(GCC_VERSION) \
		-t $(IMG) \
		--push \
		.

# Run the image locally for testing
run:
	docker run -it --rm \
		--gpus all \
		-p 8888:8888 \
		-v $(PWD)/workspace:/home/jovyan \
		-e NB_PREFIX=/test \
		$(IMG)-$(ARCH)

# Run with privileged mode for extended CUDA functionality
run-privileged:
	docker run -it --rm \
		--privileged \
		--gpus all \
		-p 8888:8888 \
		-v $(PWD)/workspace:/home/jovyan \
		-e NB_PREFIX=/test \
		$(IMG)-$(ARCH)

# Test CUDA functionality
test-cuda:
	docker run --rm --gpus all \
		$(IMG)-$(ARCH) \
		nvidia-smi

test-cuda-compatibility:
	docker run --rm --gpus all \
		$(IMG)-$(ARCH) \
		python3 -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA version: {torch.version.cuda}'); print(f'GPU count: {torch.cuda.device_count()}')"

# Test Kubeflow compliance
test-kubeflow:
	@echo "=== Testing Kubeflow Compliance ==="
	@echo "Image: $(IMG)-$(ARCH)"
	@echo "Testing container startup..."
	@CONTAINER_ID=$$(docker run -d --rm \
		--name vscode-test \
		-e NB_PREFIX=/test/prefix \
		-p 8888:8888 \
		$(IMG)-$(ARCH)); \
	sleep 10; \
	echo "Testing user configuration..."; \
	USER_ID=$$(docker exec vscode-test id -u jovyan 2>/dev/null); \
	if [ "$$USER_ID" = "1000" ]; then \
		echo "✅ jovyan user has UID 1000"; \
	else \
		echo "❌ jovyan user UID is $$USER_ID (expected 1000)"; \
	fi; \
	echo "Testing home directory..."; \
	HOME_DIR=$$(docker exec vscode-test sh -c 'echo $$HOME' 2>/dev/null); \
	if [ "$$HOME_DIR" = "/home/jovyan" ]; then \
		echo "✅ Home directory is /home/jovyan"; \
	else \
		echo "❌ Home directory is $$HOME_DIR (expected /home/jovyan)"; \
	fi; \
	echo "Testing NB_PREFIX handling..."; \
	NB_PREFIX_VALUE=$$(docker exec vscode-test sh -c 'echo $$NB_PREFIX' 2>/dev/null); \
	if [ "$$NB_PREFIX_VALUE" = "/test/prefix" ]; then \
		echo "✅ NB_PREFIX environment variable is set correctly"; \
	else \
		echo "❌ NB_PREFIX is $$NB_PREFIX_VALUE (expected /test/prefix)"; \
	fi; \
	docker stop vscode-test >/dev/null 2>&1; \
	echo "✅ Test completed"

# Test VSCode functionality
test-vscode:
	@echo "=== Testing VSCode Functionality ==="
	@CONTAINER_ID=$$(docker run -d --rm \
		--name vscode-test \
		-p 8888:8888 \
		$(IMG)-$(ARCH)); \
	sleep 15; \
	echo "Testing VSCode extensions..."; \
	EXTENSIONS=$$(docker exec vscode-test code-server --list-extensions 2>/dev/null | grep -c "ms-python" || echo "0"); \
	echo "Found $$EXTENSIONS Python extensions"; \
	if [ "$$EXTENSIONS" -gt 0 ]; then \
		echo "✅ VSCode extensions installed"; \
	else \
		echo "❌ No VSCode extensions found"; \
	fi; \
	docker stop vscode-test >/dev/null 2>&1

# Push to registry
push:
	docker push $(IMG)-$(ARCH)

# Clean up images
clean:
	docker rmi -f $(IMG)-$(ARCH) 2>/dev/null || true
	docker rmi -f $(IMG) 2>/dev/null || true

# Show image information
info:
	@echo "=== VSCode CUDA v2 Image Information ==="
	@echo "Image: $(IMG)"
	@echo "Architecture: $(ARCH)"
	@echo "Base Image: $(BASE_IMAGE)"
	@echo "CUDA Version: $(CUDA_VERSION)"
	@echo "CodeServer Version: $(CODESERVER_VERSION)"
	@echo "GCC Version: $(GCC_VERSION)"
	@echo ""
	@echo "Features:"
	@echo "✅ Kubeflow Notebooks Compliant"
	@echo "✅ HTTP interface on port 8888"
	@echo "✅ NB_PREFIX support with CORS headers"
	@echo "✅ Runs as jovyan (UID 1000, GID 0)"
	@echo "✅ Home directory at /home/jovyan"
	@echo "✅ CUDA 12.6 toolkit"
	@echo "✅ GCC 11.4.0 with multilib support"
	@echo "✅ Pre-installed ML/DL packages"
	@echo "✅ VSCode extensions for Python/Jupyter/Docker/K8s"

# Help target
help:
	@echo "Available targets:"
	@echo "  build                 Build image for current architecture"
	@echo "  buildx-push          Build and push multi-arch image"
	@echo "  run                  Run image locally with GPU support"
	@echo "  run-privileged       Run with privileged mode"
	@echo "  test-cuda            Test CUDA functionality"
	@echo "  test-cuda-compatibility Test CUDA Python integration"
	@echo "  test-kubeflow        Test Kubeflow compliance"
	@echo "  test-vscode          Test VSCode functionality"
	@echo "  push                 Push image to registry"
	@echo "  clean                Clean up images"
	@echo "  info                 Show build configuration"
	@echo "  help                 Show this help message"
	@echo ""
	@echo "Environment variables:"
	@echo "  ARCH                 Target architecture (default: amd64)"
	@echo "  TAG                  Image tag (default: v1.10.0)"
	@echo "  BASE_IMAGE           Base image (default: kubeflownotebookswg/codeserver-python:1.10.0)"
	@echo "  CUDA_VERSION         CUDA version (default: 12.6.2)"
	@echo "  CODESERVER_VERSION   Code-server version (default: 4.96.4)"
	@echo "  GCC_VERSION          GCC version (default: 11.4.0)"