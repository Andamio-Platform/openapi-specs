# Andamio OpenAPI Specs — deprecated

**This repository is deprecated and is being archived. Do not build against it.**

The OpenAPI specification that lived here (`openapi.yaml`) has been removed. It was last
updated on 2026-01-18 and had drifted from the API we actually serve. It was also the wrong
artifact: an unfiltered export that included administrative operations which were never part
of any product surface.

## Where the contract lives now

The public API contract — the operations available to you as an integrator — is published at
**[`specs/andamio-api.yaml`](https://github.com/Andamio-Platform/andamio-dev/blob/main/specs/andamio-api.yaml)**
in [`andamio-dev`](https://github.com/Andamio-Platform/andamio-dev).

That file carries a header naming the artifact it was generated from and the date it was
synced, so you can tell whether what you are reading is current.

## What was here

- `openapi.yaml` — removed. Stale, and included administrative operations.
- `.github/workflows/sync-from-api.yml` — removed. Intended to keep the spec current; it
  never completed a successful run, and it fetched the unfiltered specification rather than
  the public contract.
- SDK generation (`Makefile`, `tools/`) and the `@andamio/types` package under `packages/` —
  left in place but unmaintained, and non-functional without the spec. `@andamio/types` was
  never published to npm.

History is preserved — nothing is removed from the git log.
