# Makefile for generating SDKs from OpenAPI spec using Docker
# Uses openapi-generator-cli Docker image to avoid local installation

# Variables
OPENAPI_FILE := openapi.yaml
SDK_DIR := sdks
DOCKER_IMAGE := openapitools/openapi-generator-cli:latest
DOCKER_RUN := docker run --rm -v ${PWD}:/local $(DOCKER_IMAGE)

# Colors for output
GREEN := \033[0;32m
NC := \033[0m # No Color

.PHONY: all typescript go rust python clean validate help

# Default target - shows help
help:
	@echo "$(GREEN)OpenAPI SDK Generator$(NC)"
	@echo ""
	@echo "Available targets:"
	@echo "  make all        - Generate all SDKs (TypeScript, Go, Rust, Python)"
	@echo "  make typescript - Generate TypeScript (typescript-fetch) SDK"
	@echo "  make go         - Generate Go SDK"
	@echo "  make rust       - Generate Rust SDK"
	@echo "  make python     - Generate Python SDK"
	@echo "  make validate   - Validate the OpenAPI spec"
	@echo "  make clean      - Remove all generated SDKs"
	@echo "  make help       - Show this help message"

# Generate all SDKs
all: typescript go rust python
	@echo "$(GREEN)✓ All SDKs generated successfully$(NC)"

# Validate the OpenAPI spec
validate:
	@echo "$(GREEN)Validating OpenAPI spec...$(NC)"
	@$(DOCKER_RUN) validate -i /local/$(OPENAPI_FILE)
	@echo "$(GREEN)✓ Validation successful$(NC)"

# Generate TypeScript SDK using typescript-fetch generator
# Output: ./sdks/typescript/
typescript:
	@echo "$(GREEN)Generating TypeScript SDK...$(NC)"
	@mkdir -p $(SDK_DIR)/typescript
	@$(DOCKER_RUN) generate \
		-i /local/$(OPENAPI_FILE) \
		-g typescript-fetch \
		-o /local/$(SDK_DIR)/typescript \
		--additional-properties=npmName=@andamiojs/demo,supportsES6=true,typescriptThreePlus=true
	@echo "$(GREEN)✓ TypeScript SDK generated at $(SDK_DIR)/typescript$(NC)"

# Generate Go SDK
# Output: ./sdks/go/
go:
	@echo "$(GREEN)Generating Go SDK...$(NC)"
	@mkdir -p $(SDK_DIR)/go
	@$(DOCKER_RUN) generate \
		-i /local/$(OPENAPI_FILE) \
		-g go \
		-o /local/$(SDK_DIR)/go \
		--additional-properties=packageName=todoclient,isGoSubmodule=true
	@echo "$(GREEN)✓ Go SDK generated at $(SDK_DIR)/go$(NC)"

# Generate Rust SDK
# Output: ./sdks/rust/
rust:
	@echo "$(GREEN)Generating Rust SDK...$(NC)"
	@mkdir -p $(SDK_DIR)/rust
	@$(DOCKER_RUN) generate \
		-i /local/$(OPENAPI_FILE) \
		-g rust \
		-o /local/$(SDK_DIR)/rust \
		--additional-properties=packageName=todo-api-client
	@echo "$(GREEN)✓ Rust SDK generated at $(SDK_DIR)/rust$(NC)"

# Generate Python SDK
# Output: ./sdks/python/
python:
	@echo "$(GREEN)Generating Python SDK...$(NC)"
	@mkdir -p $(SDK_DIR)/python
	@$(DOCKER_RUN) generate \
		-i /local/$(OPENAPI_FILE) \
		-g python \
		-o /local/$(SDK_DIR)/python \
		--additional-properties=packageName=todo_api_client,projectName=todo-api-client
	@echo "$(GREEN)✓ Python SDK generated at $(SDK_DIR)/python$(NC)"

# Clean all generated SDKs
clean:
	@echo "$(GREEN)Cleaning generated SDKs...$(NC)"
	@rm -rf $(SDK_DIR)
	@echo "$(GREEN)✓ Cleaned$(NC)"
