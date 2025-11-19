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
TAG ?= v1.10.0
BASE_IMAGE ?= kubeflownotebookswg/jupyter-scipy:1.10.0
CUDA_VERSION ?= 12.6.2
CODESERVER_VERSION ?= 4.96.4
GCC_VERSION ?= 11.4.0

IMG ?= kubeflownotebookswg/vscode-cuda:$(TAG)

# Docker build flags
DOCKER_BUILD_FLAGS ?= --no-cache

.PHONY: build build-arch buildx-push

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

# Run the image locally
run:
	docker run -it --rm \
		--gpus all \
		-p 8888:8888 \
		-v $(PWD)/workspace:/workspace \
		-w /workspace \
		$(IMG)-$(ARCH)

# Run with privileged mode for extended CUDA functionality
run-privileged:
	docker run -it --rm \
		--privileged \
		--gpus all \
		-p 8888:8888 \
		-v $(PWD)/workspace:/workspace \
		-w /workspace \
		$(IMG)-$(ARCH)

# Push to registry
push:
	docker push $(IMG)-$(ARCH)

# Test CUDA functionality
test-cuda:
	docker run --rm --gpus all \
		$(IMG)-$(ARCH) \
		nvidia-smi

test-cuda-compatibility:
	docker run --rm --gpus all \
		$(IMG)-$(ARCH) \
		python3 -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA version: {torch.version.cuda}'); print(f'GPU count: {torch.cuda.device_count()}')"

# Clean up
clean:
	docker rmi -f $(IMG)-$(ARCH) 2>/dev/null || true
	docker rmi -f $(IMG) 2>/dev/null || true

# Show image info
info:
	@echo "Image: $(IMG)"
	@echo "Architecture: $(ARCH)"
	@echo "Base Image: $(BASE_IMAGE)"
	@echo "CUDA Version: $(CUDA_VERSION)"
	@echo "CodeServer Version: $(CODESERVER_VERSION)"
	@echo "GCC Version: $(GCC_VERSION)"

help:
	@echo "Available targets:"
	@echo "  build                 Build image for current architecture"
	@echo "  buildx-push          Build and push multi-arch image"
	@echo "  run                  Run image locally"
	@echo "  run-privileged       Run with privileged mode"
	@echo "  push                 Push image to registry"
	@echo "  test-cuda            Test CUDA functionality"
	@echo "  test-cuda-compatibility Test CUDA compatibility"
	@echo "  clean                Clean up images"
	@echo "  info                 Show build configuration"
	@echo "  help                 Show this help message"