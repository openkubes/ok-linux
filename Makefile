.PHONY: help kernel image boot install clean lint

OKL_VERSION ?= v0.1.0
NODE ?= ok-infra

# okl — OpenKubes Linux
help: ## Show this help
	@echo ""
	@echo "  okl — OpenKubes Linux $(OKL_VERSION)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

kernel: ## Build okl kernel
	@echo "🐧 Building okl kernel $(OKL_VERSION)..."
	@bash image/build.sh kernel

image: ## Build okl golden image
	@echo "📦 Building okl golden image $(OKL_VERSION)..."
	@bash image/build.sh image

boot: ## Generate PXE/iPXE boot config
	@echo "🥾 Generating okl boot config..."
	@bash image/build.sh boot

install: ## Install okl on a node
	@echo "🚀 Installing okl on $(NODE)..."
	@bash image/build.sh install $(NODE)

lint: ## Lint all scripts
	@shellcheck image/build.sh

clean: ## Remove build artifacts
	@rm -rf build/
	@echo "🧹 Cleaned."

version: ## Show okl version
	@echo "okl $(OKL_VERSION)"
