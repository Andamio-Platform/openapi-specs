# Usage Instructions

## Prerequisites
Docker must be installed and running.

## Quick Start
```bash
# Validate the OpenAPI spec
make validate

# Generate all SDKs at once
make all

# Or generate individual language SDKs
make typescript
make go
make rust
make python

# Clean up generated files
make clean
```

Generated SDKs will be placed in ./sdks/<language>/ directories. Each SDK includes its own README with language-specific installation and usage instructions. The TypeScript SDK uses the modern fetch API, Go includes a complete client package, Rust provides an async client, and Python generates a pip-installable package.
