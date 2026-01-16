# Makefile for generating SDKs from OpenAPI spec using Docker
# Uses openapi-generator-cli Docker image to avoid local installation

# Variables
OPENAPI_FILE := openapi.yaml
SDK_DIR := sdks
PACKAGES_DIR := packages
TYPES_PKG := $(PACKAGES_DIR)/andamio-types
DOCKER_IMAGE := openapitools/openapi-generator-cli:latest
DOCKER_RUN := docker run --rm -v ${PWD}:/local $(DOCKER_IMAGE)

# Gateway source of truth
GATEWAY_SPEC_URL := https://andamio-api-gateway-168705267033.us-central1.run.app/api/v1/docs/doc.json

# Colors for output
GREEN := \033[0;32m
NC := \033[0m # No Color

.PHONY: all typescript go rust python clean validate help types types-build types-publish fetch-spec

# Default target - shows help
help:
	@echo "$(GREEN)OpenAPI SDK Generator$(NC)"
	@echo ""
	@echo "Available targets:"
	@echo "  make all           - Generate all SDKs (TypeScript, Go, Rust, Python)"
	@echo "  make typescript    - Generate TypeScript (typescript-fetch) SDK"
	@echo "  make go            - Generate Go SDK"
	@echo "  make rust          - Generate Rust SDK"
	@echo "  make python        - Generate Python SDK"
	@echo "  make validate      - Validate the OpenAPI spec"
	@echo "  make clean         - Remove all generated SDKs"
	@echo "  make help          - Show this help message"
	@echo ""
	@echo "$(GREEN)TypeScript Types Package$(NC)"
	@echo "  make types         - Generate TypeScript types (requires Node.js)"
	@echo "  make types-build   - Generate and build the types package"
	@echo "  make types-publish - Build and publish to npm (requires npm login)"
	@echo ""
	@echo "$(GREEN)Spec Management$(NC)"
	@echo "  make fetch-spec    - Fetch latest spec from live gateway"

# Fetch the latest OpenAPI spec from the live gateway and convert to OpenAPI 3.0
fetch-spec:
	@echo "$(GREEN)Fetching spec from gateway...$(NC)"
	@curl -s $(GATEWAY_SPEC_URL) > swagger2.json
	@echo "$(GREEN)Converting Swagger 2.0 to OpenAPI 3.0...$(NC)"
	@npx swagger2openapi swagger2.json -o $(OPENAPI_FILE) --yaml
	@rm swagger2.json
	@echo "$(GREEN)✓ Spec saved to $(OPENAPI_FILE)$(NC)"
	@echo "$(GREEN)Run 'git diff $(OPENAPI_FILE)' to review changes$(NC)"

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
	@rm -rf $(TYPES_PKG)/dist $(TYPES_PKG)/src/index.ts
	@echo "$(GREEN)✓ Cleaned$(NC)"

# ============================================================================
# TypeScript Types Package (@andamio/types)
# Generates pure TypeScript types from OpenAPI spec using openapi-typescript
# ============================================================================

# Generate TypeScript types only (no build)
# Requires: Node.js and npm
types:
	@echo "$(GREEN)Generating TypeScript types...$(NC)"
	@cd $(TYPES_PKG) && npm install && npm run generate
	@echo "$(GREEN)✓ Types generated at $(TYPES_PKG)/src/index.ts$(NC)"

# Generate and build the types package
types-build: types
	@echo "$(GREEN)Building types package...$(NC)"
	@cd $(TYPES_PKG) && npm run build
	@echo "$(GREEN)✓ Package built at $(TYPES_PKG)/dist/$(NC)"

# Build and publish to npm
# Requires: npm login to @andamio scope
types-publish: types-build
	@echo "$(GREEN)Publishing @andamio/types to npm...$(NC)"
	@cd $(TYPES_PKG) && npm publish --access public
	@echo "$(GREEN)✓ Published to npm$(NC)"
