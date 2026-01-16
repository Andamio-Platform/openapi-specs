# Andamio OpenAPI Specs

OpenAPI specification and SDK generation for the Andamio API.

## Prerequisites

- **Docker** - Required for SDK generation (typescript-fetch, Go, Rust, Python)
- **Node.js 18+** - Required for TypeScript types package

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

Generated SDKs will be placed in `./sdks/<language>/` directories.

## TypeScript Types Package

A lightweight, zero-dependency TypeScript types package is available at `packages/andamio-types/`.

### Generate and Build

```bash
# Generate TypeScript types from OpenAPI spec
make types

# Generate and build the distributable package
make types-build

# Publish to npm (requires npm login)
make types-publish
```

### Installation (for consumers)

```bash
npm install @andamio/types
```

### Usage

```typescript
import type { components, paths } from '@andamio/types';

// Access schema types
type Course = components['schemas']['Course'];
type Student = components['schemas']['Student'];

// Access request/response types
type MintRequest = components['schemas']['MintAccessTokenV2TxRequest'];
type TxResponse = components['schemas']['UnsignedTxResponse'];

// Access path parameters and responses
type CoursesResponse = paths['/v2/courses']['get']['responses']['200']['content']['application/json'];
```

### Package Features

- **Pure types** - No runtime dependencies
- **Generated from OpenAPI** - Always in sync with the spec
- **ESM and CJS** - Dual module support
- **TypeScript 4.7+** - Modern type features

## SDK Overview

| SDK | Generator | Output |
|-----|-----------|--------|
| TypeScript (fetch) | `typescript-fetch` | `./sdks/typescript/` |
| Go | `go` | `./sdks/go/` |
| Rust | `rust` | `./sdks/rust/` |
| Python | `python` | `./sdks/python/` |
| **TypeScript Types** | `openapi-typescript` | `./packages/andamio-types/` |
