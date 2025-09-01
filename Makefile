# GlinrDock Build and Release Makefile
.PHONY: help build release release-stage clean verify-deps

VERSION ?= $(shell git describe --tags --always --dirty)
BUILD_TIME := $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
COMMIT := $(shell git rev-parse HEAD)

# Build configuration
BINARY_NAME := glinrdockd
BUILD_DIR := build
STAGING_DIR := _staging/$(VERSION)

# Platform targets
PLATFORMS := linux/amd64 linux/arm64 darwin/amd64 darwin/arm64

# Build flags
LDFLAGS := -s -w -X main.version=$(VERSION) -X main.buildTime=$(BUILD_TIME) -X main.commit=$(COMMIT)
BUILD_FLAGS := -ldflags="$(LDFLAGS)" -trimpath

help: ## Show this help message
	@echo "GlinrDock Release Tools"
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

verify-deps: ## Verify required dependencies are installed
	@echo "Checking build dependencies..."
	@command -v go >/dev/null 2>&1 || (echo "Error: go is required but not installed" && exit 1)
	@command -v tar >/dev/null 2>&1 || (echo "Error: tar is required but not installed" && exit 1)
	@command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1 || (echo "Error: sha256sum or shasum is required but not installed" && exit 1)
	@if [ -n "$$COSIGN_PASSWORD" ] && [ -n "$$COSIGN_KEY" ]; then \
		command -v cosign >/dev/null 2>&1 || (echo "Error: cosign is required for signing but not installed" && exit 1); \
		echo "Cosign signing enabled"; \
	else \
		echo "Cosign signing disabled (COSIGN_PASSWORD and COSIGN_KEY not both set)"; \
	fi
	@echo "All dependencies verified"

clean: ## Remove build artifacts
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@rm -rf _staging
	@echo "Clean complete"

build: verify-deps ## Build binaries for all platforms
	@echo "Building GlinrDock $(VERSION) for all platforms..."
	@mkdir -p $(BUILD_DIR)
	@for platform in $(PLATFORMS); do \
		os=$${platform%/*}; \
		arch=$${platform#*/}; \
		echo "Building for $$os/$$arch..."; \
		CGO_ENABLED=0 GOOS=$$os GOARCH=$$arch go build \
			$(BUILD_FLAGS) \
			-o $(BUILD_DIR)/$(BINARY_NAME)_$${os}_$$arch \
			./cmd/$(BINARY_NAME) || exit 1; \
	done
	@echo "Build complete"

release-stage: build ## Create staging directory with packaged artifacts
	@echo "Staging release $(VERSION)..."
	@mkdir -p $(STAGING_DIR)
	@for platform in $(PLATFORMS); do \
		os=$${platform%/*}; \
		arch=$${platform#*/}; \
		binary="$(BUILD_DIR)/$(BINARY_NAME)_$${os}_$$arch"; \
		tarball="$(STAGING_DIR)/$(BINARY_NAME)_$${os}_$$arch.tar.gz"; \
		echo "Packaging $$os/$$arch..."; \
		tar -czf $$tarball -C $(BUILD_DIR) $(BINARY_NAME)_$${os}_$$arch || exit 1; \
	done
	@echo "Generating checksums..."
	@cd $(STAGING_DIR) && \
		if command -v sha256sum >/dev/null 2>&1; then \
			sha256sum *.tar.gz > SHA256SUMS; \
		else \
			shasum -a 256 *.tar.gz > SHA256SUMS; \
		fi
	@echo "Staging complete"

sign-artifacts: ## Sign artifacts with cosign (requires COSIGN_PASSWORD and COSIGN_KEY)
	@if [ -z "$$COSIGN_PASSWORD" ] || [ -z "$$COSIGN_KEY" ]; then \
		echo "Skipping artifact signing (COSIGN_PASSWORD and COSIGN_KEY not both set)"; \
		exit 0; \
	fi
	@echo "Signing artifacts with cosign..."
	@cd $(STAGING_DIR) && \
		for file in *.tar.gz SHA256SUMS; do \
			if [ -f "$$file" ]; then \
				echo "Signing $$file..."; \
				cosign sign-blob \
					--key env://COSIGN_KEY \
					--output-signature $$file.sig \
					$$file || exit 1; \
			fi; \
		done
	@echo "Artifact signing complete"

release: release-stage sign-artifacts ## Build, stage, and optionally sign release artifacts
	@echo "Release $(VERSION) ready in $(STAGING_DIR)"
	@echo "Artifacts:"
	@ls -la $(STAGING_DIR)

verify-signatures: ## Verify cosign signatures (requires cosign public key)
	@if [ ! -f "cosign.pub" ]; then \
		echo "Error: cosign.pub public key file not found"; \
		echo "Extract public key with: cosign public-key --key env://COSIGN_KEY > cosign.pub"; \
		exit 1; \
	fi
	@echo "Verifying signatures..."
	@cd $(STAGING_DIR) && \
		for file in *.tar.gz SHA256SUMS; do \
			if [ -f "$$file.sig" ]; then \
				echo "Verifying $$file..."; \
				cosign verify-blob \
					--key ../cosign.pub \
					--signature $$file.sig \
					$$file || exit 1; \
			else \
				echo "Warning: No signature found for $$file"; \
			fi; \
		done
	@echo "Signature verification complete"